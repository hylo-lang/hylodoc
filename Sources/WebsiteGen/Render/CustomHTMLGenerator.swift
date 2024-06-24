import DocExtractor
import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit

public struct ReferenceRenderingContext {
  let typedProgram: TypedProgram

  /// The scope id of the current scope in which references should be resolved
  let scopeId: AnyScopeID

  /// A closure that turns a target id into a URL that can be used to link to it
  let resolveUrls: (AnyTargetID) -> URL?

  // these are for resolving local file references:

  /// The absolute URL of the source file or hylodoc file that we
  /// should resolve local file references relative to
  let sourceUrl: URL

  /// We need this for looking up assets by url
  let assetStore: AssetStore
}

public protocol HyloReferenceResolvingGenerator {
  func generateResolvingHyloReferences(document: Block, context: ReferenceRenderingContext)
    -> String
  func generateResolvingHyloReferences(block: Block, context: ReferenceRenderingContext) -> String
}

/// A Custom HTML generator that overrides the default behavior of the `HtmlGenerator` to render code blocks and hylo references in a custom way.
public class CustomHTMLGenerator: HtmlGenerator, HyloReferenceRenderer,
  HyloReferenceResolvingGenerator
{
  override open func generate(block: Block, tight: Bool = false) -> String {
    // Override how to generate code blocks
    if case .indentedCode(let lines) = block {
      return """
        <div class="code-snippet">
            <span class="options">
                <a class="copy">Copy</a>
            </span>
            <code><pre>\(self.generate(lines: lines).encodingPredefinedXmlEntities())</pre></code>
        </div>
        """
    } else if case .fencedCode(let lang, let lines) = block {
      if let language = lang {
        return """
          <div class="code-snippet">
              <span class="options">
                  <a class="copy">Copy</a>
              </span>
              <code class=\"\(language)\"><pre>\(self.generate(lines: lines, separator: "").encodingPredefinedXmlEntities())</pre></code>
          </div>
          """
      } else {
        return """
          <div class="code-snippet">
              <span class="options">
                  <a class="copy">Copy</a>
              </span>
              <code><pre>\(self.generate(lines: lines, separator: "").encodingPredefinedXmlEntities())</pre></code>
          </div>
          """
      }
    }

    return super.generate(block: block, tight: tight)
  }

  override open func generate(textFragment fragment: TextFragment) -> String {
    precondition(referenceContext != nil)

    // Override how to generate code tags
    if case .code(let str) = fragment {
      return "<span class=\"tag\">\(String(str).encodingPredefinedXmlEntities())</span>"
    }

    // Override the generation of links to allow for local file references
    if case .link(let text, let url, let title) = fragment {
      let titleAttr = title == nil ? "" : " title=\"\(title!)\""

      guard let reference = url, !reference.isEmpty else {
        return self.generate(text: text)
      }

      guard
        let urlString = resolveLinkReference(
          reference: reference, referenceContext: referenceContext!), !urlString.isEmpty
      else {
        return self.generate(text: text)
      }

      return "<a href=\"\(urlString)\"\(titleAttr)>" + self.generate(text: text) + "</a>"
    }
    // Override the generation of images to resolve local file references
    if case .image(let alt, let url, let title) = fragment {
      let titleAttr = title == nil ? "" : " title=\"\(title!)\""

      guard let reference = url, !reference.isEmpty else {
        return self.generate(text: alt)
      }

      guard
        let urlString = resolveLinkReference(
          reference: reference, referenceContext: referenceContext!), !urlString.isEmpty
      else {
        fatalError(
          "Couldn't resolve image reference \(reference) from source url \(referenceContext!.sourceUrl)"
        )
      }

      return "<img src=\"\(urlString)\" alt=\"\(alt)\"\(titleAttr) />"
    }

    return super.generate(textFragment: fragment)
  }

  public var referenceContext: ReferenceRenderingContext?

  /// Rendering hylo references by resolving the reference to a link to the actual target.
  public func render(hyloReference reference: HyloReference) -> String {
    precondition(referenceContext != nil)

    let resolved: Set<AnyDeclID>
    do {
      resolved = try referenceContext!.typedProgram.resolveReference(reference.text, in: referenceContext!.scopeId)
    } catch {
      fatalError("[ERROR] Failed to resolve Hylo reference: \(error)\nin string: ``\(reference.text)``.")
    }

    guard !resolved.isEmpty else {
      fatalError(
        "[ERROR] Unable to resolve reference \(reference.text) in \(referenceContext!.scopeId).")
    }
    guard resolved.count == 1 else {
      fatalError("[ERROR] Reference \(reference.text) resolved to multiple targets: \n\(resolved)")
    }

    if let link = referenceContext!.resolveUrls(.decl(resolved.first!))?.path {
      return "<code class=\"hylo-reference\"><a href=\"\(link)\">\(reference.text)</a></code>"
    }
    return "<code class=\"hylo-reference\">\(reference.text)</code>"
    // return "<code class=\"hylo-reference\">\(reference.text) in \(resolved)</code>"
  }

  public func generateResolvingHyloReferences(document: Block, context: ReferenceRenderingContext)
    -> String
  {
    self.referenceContext = context
    defer { self.referenceContext = nil }
    return self.generate(doc: document)
  }

  public func generateResolvingHyloReferences(block: Block, context: ReferenceRenderingContext)
    -> String
  {
    self.referenceContext = context
    defer { self.referenceContext = nil }
    return self.generate(block: block)
  }
}

/// Returns a facade closure that is able to resolve urls to arbitrary
/// targets from the given source in `from`
func targetToUrl(_ targetResolver: TargetResolver) -> (AnyTargetID) -> URL? {
  return { targetResolver.url(to: $0) }
}

/// A facade struct that wraps the necessary context and the generator to ease
/// the generation of html content from markdown
///
/// Once constructed, we only need to call the `generate` method with the markdown
/// content to get the html content which is easier than calling the generator
/// directly creating the context every time.
struct SimpleHTMLGenerator<T: HyloReferenceResolvingGenerator> {
  let context: ReferenceRenderingContext
  let generator: T

  init(context: ReferenceRenderingContext, generator: T) {
    self.context = context
    self.generator = generator
  }

  func generate(block: Block) -> String {
    generator.generateResolvingHyloReferences(block: block, context: context)
  }
  func generate(document: Block) -> String {
    generator.generateResolvingHyloReferences(document: document, context: context)
  }
}

/// Resolves a local file reference to an asset id, relative to the provided source file url.
func resolveLocalFileReference(_ reference: String, from sourceUrl: URL, in assetStore: AssetStore)
  -> AnyTargetID
{
  // todo refactor into a throwing function
  let referencedLocalFileUrl = URL.init(
    fileURLWithPath: reference,
    relativeTo: sourceUrl.deletingLastPathComponent()
  ).absoluteURL

  guard let assetId: AnyAssetID = assetStore.find(url: referencedLocalFileUrl.standardized) else {
    var message =
      "[Error]: didn't find asset for referenced asset \"\(referencedLocalFileUrl.standardized)\" \n\t"
      + "while resolving reference \(reference) in \(sourceUrl)\n Possible paths are:\n"
    for a in assetStore.folders {
      message += "- " + a.location.description + "\n"
    }
    fatalError(message)
  }
  return .asset(assetId)
}

/// Resolves a local file reference or any web url to a correct string
/// representation of a link that can be embedded in the website
func resolveLinkReference(reference: String, referenceContext: ReferenceRenderingContext) -> String?
{
  if reference.hasPrefix(".") || !reference.contains(":") {
    referenceContext.resolveUrls(
      resolveLocalFileReference(
        reference, from: referenceContext.sourceUrl, in: referenceContext.assetStore
      )
    ).map { urlToEncodedPath($0) }
  } else {
    reference
  }
}
