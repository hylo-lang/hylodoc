import Foundation
import FrontEnd
import DocumentationDB
import DequeModule

/// An identifier that uniquely identifies an asset or symbol in a path
///
/// It stores the type (asset or symbol) and the local ID of the value within that type.
/// (It is a composite key.)
public enum PathPart : Equatable, Hashable {
  case asset(AnyAssetID)
  case symbol(AnyDeclID)
}

public struct DynamicPath {
    private var stack: Deque<PathPart> = []
    
    // Push asset onto stack
    public mutating func push(asset: AnyAssetID) {
        stack.append(.asset(asset))
    }
    
    // Push symbol onto stack
    public mutating func push(decl: AnyDeclID) {
        stack.append(.symbol(decl))
    }
    
    // Pop top-item on the stack
    public mutating func pop() {
        let _ = stack.popLast()
    }
    
    // Get the full stack
    public func value() -> Deque<PathPart> {
        return stack
    }
    
}
