import Foundation
import MarkdownKit

public protocol HyloReferenceRenderer {
  func render(hyloReference reference: HyloReference) -> String
}

public struct HyloReference: CustomTextFragment, Equatable {
  public let text: String

  public init(_ text: String) {
    self.text = text
  }

  public func equals(to other: CustomTextFragment) -> Bool {
    guard let that = other as? HyloReference else { return false }
    return self == that
  }

  public func transform(via transformer: InlineTransformer) -> TextFragment {
    return .custom(self)  // we don't allow transforming this fragment
  }

  public func generateHtml(via htmlGen: HtmlGenerator) -> String {
    precondition(htmlGen is HyloReferenceRenderer, "HtmlGenerator must be a HyloReferenceRenderer")
    return (htmlGen as! HyloReferenceRenderer).render(hyloReference: self)
  }

  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    public func generateHtml(via htmlGen: HtmlGenerator, and attrGen: AttributedStringGenerator?)
      -> String
    {
      fatalError("This method should not be used")
    }
  #endif

  public var rawDescription: String {
    return text
  }
  public var description: String {
    return "hyloReference(\(text))"
  }
  public var debugDescription: String {
    return "hyloReference(\(text))"
  }
}

///
/// An inline transformer which extracts code spans, auto-links and html tags and transforms
/// them into `code`, `autolinks`, and `html` text fragments.
/// This transformer is a modification of the `CodeLinkHtmlTransformer` from the `MarkdownKit` library.
open class CodeRefLinkHtmlTransformer: InlineTransformer {

  public override func transform(_ text: Text) -> Text {
    var res: Text = Text()
    var iterator = text.makeIterator()
    var element = iterator.next()
    loop: while let fragment = element {
      switch fragment {
      case .delimiter("`", let n, []):
        var scanner = iterator
        var next = scanner.next()
        var count = 0
        while let lookahead = next {
          count += 1
          switch lookahead {
          case .delimiter("`", n, _):
            var scanner2 = iterator
            var code = ""
            for _ in 1 ..< count {
              code += scanner2.next()?.rawDescription ?? ""
            }
            if n == 2 {
              res.append(fragment: .custom(HyloReference(code)))
            } else {
              res.append(fragment: .code(Substring(code)))
            }
            iterator = scanner
            element = iterator.next()
            continue loop
          case .delimiter(_, _, _), .text(_), .softLineBreak, .hardLineBreak:
            next = scanner.next()
          default:
            res.append(fragment: fragment)
            element = iterator.next()
            continue loop
          }
        }
        res.append(fragment: fragment)
        element = iterator.next()
      case .delimiter("<", let n, []):
        var scanner = iterator
        var next = scanner.next()
        var count = 0
        while let lookahead = next {
          count += 1
          switch lookahead {
          case .delimiter(">", n, _):
            var scanner2 = iterator
            var content = ""
            for _ in 1 ..< count {
              content += scanner2.next()?.rawDescription ?? ""
            }
            if isURI(content) {
              res.append(fragment: .autolink(.uri, Substring(content)))
              iterator = scanner
              element = iterator.next()
              continue loop
            } else if isEmailAddress(content) {
              res.append(fragment: .autolink(.email, Substring(content)))
              iterator = scanner
              element = iterator.next()
              continue loop
            } else if isHtmlTag(content) {
              res.append(fragment: .html(Substring(content)))
              iterator = scanner
              element = iterator.next()
              continue loop
            }
            next = scanner.next()
          case .delimiter(_, _, _), .text(_), .softLineBreak, .hardLineBreak:
            next = scanner.next()
          default:
            res.append(fragment: fragment)
            element = iterator.next()
            continue loop
          }
        }
        res.append(fragment: fragment)
        element = iterator.next()
      default:
        element = self.transform(fragment, from: &iterator, into: &res)
      }
    }
    return res
  }
}

public final class HyloDocMarkdownParser: MarkdownParser {
  override public class var defaultInlineTransformers: [InlineTransformer.Type] {
    return [
      DelimiterTransformer.self,
      CodeRefLinkHtmlTransformer.self,
      LinkTransformer.self,
      EmphasisTransformer.self,
      EscapeTransformer.self,
    ]
  }
  override public class var standard: HyloDocMarkdownParser {
    return self.singleton
  }
  private static let singleton = HyloDocMarkdownParser()
}
