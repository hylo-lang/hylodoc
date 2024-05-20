import FrontEnd
import Foundation
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












//Old proprietary markdown data structure

// TODO: Revise the markdown node data types to support styling and nesting properly.

// public enum AnyMarkdownNodeID : Equatable, Hashable {
//   case of(text: MDText.ID)
//   case of(italic: MDItalic.ID)
//   case of(paragraph: MDParagraph.ID)
//   case of(codeBlock: MDCodeBlock.ID)
//   case of(heading: MDHeading.ID)
//   case of(link: MDLink.ID)
//   case of(image: MDImage.ID)
// }

// public struct MDText: IdentifiedEntity {
//   public let text: String
// }
// public struct MDItalic: IdentifiedEntity {
//   public let text: AnyMarkdownNodeID  // todo refine type
// }
// public struct MDParagraph: IdentifiedEntity {
//   // todo: Type this more precisely, e.g. don't allow a paragraph to contain another paragraph
//   public let children: [AnyMarkdownNodeID]
// }
// public struct MDCodeBlock: IdentifiedEntity {
//   public let language: String?
//   public let code: String
// }
// public struct MDHeading: IdentifiedEntity {
//   public let level: Int
//   public let text: String
// }
// public struct MDList: IdentifiedEntity {
//   public let items: [AnyMarkdownNodeID]
// }
// public struct MDLink: IdentifiedEntity {
//   public enum Reference {
//     /// An asset within the project
//     case asset(AnyAssetID)

//     /// An internet URL
//     case url(String)
    
//     /// Refers to a hylo symbol
//     case symbol(id: AnyDeclID)
//   }

//   /// The reference that the link points to.
//   public let reference: Reference

//   /// The title that was given to the link in the markdown source.
//   ///
//   /// If nothing is provided, we should default to the name of the referenced entity or the URL.
//   public let title: String?
// }
// public struct MDImage: IdentifiedEntity {
//   public let source: ProjectURL
//   public let altText: String?
// }


// /// A project URL is a URL that points to a file or folder within the project.
// ///
// /// We use a custom scheme `project://` to distinguish these URLs from regular URLs.
// public struct ProjectURL {
//   public let url: URL

//   public init(_ url: URL) {
//     assert(
//       url.isFileURL && url.scheme == "project", "URL must be a file url with the scheme project://")
//     self.url = url
//   }
// }

// /// A store of markdown nodes that supports insertion and lookup by ID, both in O(1) time.
// /// 
// /// The entities are grouped by their type.
// public struct MarkdownStore {
//   public var texts: EntityStore<MDText> = .init()
//   public var italics: EntityStore<MDItalic> = .init()
//   public var paragraphs: EntityStore<MDParagraph> = .init()
//   public var codeBlocks: EntityStore<MDCodeBlock> = .init()
//   public var headings: EntityStore<MDHeading> = .init()
//   public var lists: EntityStore<MDList> = .init()
//   public var links: EntityStore<MDLink> = .init()
//   public var images: EntityStore<MDImage> = .init()
// }
