import MarkdownKit

class RenderHTMLGenerator: HtmlGenerator {
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
}
