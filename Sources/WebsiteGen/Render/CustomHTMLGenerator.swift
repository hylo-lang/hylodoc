import DocExtractor
import FrontEnd
import MarkdownKit
import PathWrangler

public struct ReferenceRenderingContext {
  let typedProgram: TypedProgram
  let scopeId: AnyScopeID
  let resolveUrls: (AnyTargetID) -> RelativePath?
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
    // Override how to generate code tags
    if case .code(let str) = fragment {
      return "<code class=\"tag\">\(String(str).encodingPredefinedXmlEntities())</code>"
    }

    return super.generate(textFragment: fragment)
  }

  public var referenceContext: ReferenceRenderingContext?

  /// Rendering hylo references by resolving the reference to a link to the actual target.
  public func render(hyloReference reference: HyloReference) -> String {
    precondition(referenceContext != nil)

    let resolved = referenceContext!.typedProgram.resolveReference(
      reference.text, in: referenceContext!.scopeId)

    // Todo improve error handling
    guard let resolved = resolved else {
      fatalError("[ERROR] Reference \"\(reference.text)\" could not be parsed.")
    }
    guard !resolved.isEmpty else {
      fatalError(
        "[ERROR] Unable to resolve reference \(reference.text) in \(referenceContext!.scopeId).")
    }
    guard resolved.count == 1 else {
      fatalError("[ERROR] Reference \(reference.text) resolved to multiple targets: \n\(resolved)")
    }

    if let link = referenceContext!.resolveUrls(.decl(resolved.first!))?.description {
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
func referWithSource(
  _ targetResolver: TargetResolver,
  from: AnyTargetID
) -> (AnyTargetID) -> RelativePath? {
  return { to in
    targetResolver.refer(from: from, to: to)
  }
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
