import Foundation

public struct URLResolver {
    private var references: Dictionary<AnyTargetID,(URL,Int)> = [:]
    
    // Resolve the reference to a target
    public mutating func resolve(path: TargetPath) {
        references[path.target()] = (path.url(), path.depth())
    }
    
    // Get the file path of the target
    public func pathToFile(target: AnyTargetID) -> URL {
        return references[target]!.0
    }
    
    // Get the relative path of the target to the root
    public func pathToRoot(target: AnyTargetID) -> URL {
        return URL(fileURLWithPath: String(repeating: "../", count: references[target]!.1))
    }
    
    // Get a url referencing from one target to another
    public func refer(from: AnyTargetID, to: AnyTargetID) -> URL {
        // Refers to itself
        if from == to {
            return URL(fileURLWithPath: "")
        }
        
        // Get path components
        let fromFile = pathToFile(target: from).pathComponents
        let toFile = pathToFile(target: to).pathComponents
        
        // Find how many parts are similar
        var similar = 0
        let maxSimilar = min(fromFile.count, toFile.count) - 1 // the actual file can not be similar
        while similar < maxSimilar && fromFile[similar] == toFile[similar] {
            similar += 1
        }
        
        // Construct url keeping common parents in mind
        var url = URL(fileURLWithPath: String(repeating: "../", count: fromFile.count - similar))
        while similar < toFile.count {
            url.appendPathComponent(toFile[similar])
            similar += 1
        }
        
        return url
    }
    
}

public struct URLResolvingVisitor : DocumentationVisitor {
    private var urlResolver: URLResolver
    
    public init(urlResolver: inout URLResolver) {
        self.urlResolver = urlResolver
    }
    
    public mutating func visit(path: TargetPath) {
        urlResolver.resolve(path: path)
    }
}
