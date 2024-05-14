import FrontEnd

public protocol DocumentationIDProtocol : Hashable, Equatable {
  associatedtype Element
  var raw: UInt32 { get }
  init(_ raw: UInt32)
}

public protocol IdentifiedEntity {
  typealias ID = DocumentationID<Self>
}

/// A unique identifier that is a separate nominal type for each different kind of object that T refers to.
/// It is useful because it makes it impossible to pass/assign the wrong types of IDs to each other.
public struct DocumentationID<T: IdentifiedEntity>: DocumentationIDProtocol {
  public typealias Element = T
  public let raw: UInt32
  public init(_ raw: UInt32) {
    self.raw = raw
  }
}

/// A store of entities that supports insertion and lookup by ID, both in O(1) time.
///
/// This data structure stores its elements in contiguous memory, which allows for fast lookup and
/// great cache locality.
/// 
/// It supports insertion and lookup but no modification or deletion of elements.
public struct EntityStore<T: IdentifiedEntity> {
  private var entities: [T] = []

  /// Can be used to access the entity with the given ID (for reading) like this: entityStore[id]
  public subscript(_ id: DocumentationID<T>) -> T? {
    if id.raw >= entities.count {
      return nil
    }
    return entities[Int(id.raw)]
  }

  /// Inserts the given entity into the store and returns the documentation entity ID of the inserted entity.
  public mutating func insert(_ entity: T) -> DocumentationID<T> {
    entities.append(entity)
    return DocumentationID<T>(UInt32(entities.endIndex - 1))
  }
}

/// A protocol that requies a type to have an associated type that
/// denotes the related documentation type for a given AST node type.
public protocol HasAssociatedDocumentationTypes {
  associatedtype DocumentationT: IdentifiedEntity
}

/// Adapted Entity Store
public struct AdaptedEntityStore<OriginalASTNodeType: Node & HasAssociatedDocumentationTypes> {
  public typealias DocumentationT = OriginalASTNodeType.DocumentationT

  /// The entity store that stores the documentation entities in contiguous memory for fast lookup by documentation entity IDs.
  private var entityStore: EntityStore<OriginalASTNodeType.DocumentationT> = .init()

  /// A mapping from AST node IDs to documentation entity IDs.
  private var idMapping: [OriginalASTNodeType.ID: OriginalASTNodeType.DocumentationT.ID] = [:]

  /// Returns the documentation entity for the given AST node ID if it exists.
  public subscript(astNodeId id: OriginalASTNodeType.ID) -> OriginalASTNodeType.DocumentationT? {
    return idMapping[id].flatMap { entityStore[$0] }
  }

  /// Returns the documentation entity for the given documentation entity ID if it exists.
  public subscript(documentationId id: OriginalASTNodeType.DocumentationT.ID) -> OriginalASTNodeType.DocumentationT? {
    return entityStore[id]
  }

  /// Inserts the given documentation entity for the given AST node ID, and returns the documentation ID of the inserted entity.
  public mutating func insert(_ entity: OriginalASTNodeType.DocumentationT, for id: OriginalASTNodeType.ID) -> DocumentationT.ID {
    let newID = entityStore.insert(entity)
    idMapping[id] = newID
    return newID
  }
}