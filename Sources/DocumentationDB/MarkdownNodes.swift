public enum Reference {
    case asset(AssetID)
    /// An internet URL
    case url(String)
    /// Refers to a hylo symbol
    case symbol(id: SymbolID)
}

// todo make it make more sense
public enum MarkdownNode {
    case text(String)
    case codeBlock(language: String, String)
    case heading(level: Int, String)
    case list([MarkdownNode])
    case link(title: String?, to: Reference)
    case image(String, String)
    case paragraph([MarkdownNode])
}