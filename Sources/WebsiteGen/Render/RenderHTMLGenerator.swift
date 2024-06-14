import DocExtractor
import FrontEnd
import MarkdownKit

public protocol HyloReferenceResolvingGenerator {
  func generateResolvingHyloReferences(
    document: Block, scopeId: AnyScopeID, from typedProgram: TypedProgram
  ) -> String

  func generateResolvingHyloReferences(
    block: Block, scopeId: AnyScopeID, from typedProgram: TypedProgram
  ) -> String
}

/// A Custom HTML generator that overrides the default behavior of the `HtmlGenerator` to render code blocks and hylo references in a custom way.
public class CustomHTMLGenerator: HtmlGenerator, HyloReferenceRenderer, HyloReferenceResolvingGenerator {
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

  public struct ReferenceRenderingContext {
    var typedProgram: TypedProgram
    let scopeId: AnyScopeID
  }

  public var referenceContext: ReferenceRenderingContext?

  /// Rendering hylo references by resolving the reference to a link to the actual target.
  public func render(hyloReference reference: HyloReference) -> String {
    precondition(referenceContext != nil)
    let nothing = "nil"
    let resolved = referenceContext!.typedProgram.resolveReference(
      reference.text, in: referenceContext!.scopeId)
    return
      "<code class=\"hylo-reference\">\(reference.rawDescription) resolved as \(resolved?.description ?? nothing)</code>"
  }

  public func generateResolvingHyloReferences(
    document: Block, scopeId: AnyScopeID, from typedProgram: TypedProgram
  ) -> String {
    self.referenceContext = ReferenceRenderingContext(typedProgram: typedProgram, scopeId: scopeId)
    defer { self.referenceContext = nil }

    return self.generate(doc: document)
  }

  public func generateResolvingHyloReferences(
    block: Block, scopeId: AnyScopeID, from typedProgram: TypedProgram
  ) -> String {
    self.referenceContext = ReferenceRenderingContext(typedProgram: typedProgram, scopeId: scopeId)
    defer { self.referenceContext = nil }

    return self.generate(block: block)
  }
}
