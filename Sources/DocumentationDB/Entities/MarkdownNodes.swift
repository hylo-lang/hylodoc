import Foundation
import FrontEnd
import MarkdownKit

// Used for the markdown parser
public struct MarkdownAPIDocResult {
  var summary: Block?
  var description: [Block]
  var specialSections: [SpecialSection]
}

public struct SpecialSection {
  let name: String
  let content: [Block]
}
