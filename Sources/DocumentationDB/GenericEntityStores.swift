import FrontEnd

public protocol DocumentationIDProtocol: Hashable, Equatable {
  associatedtype Element
  var raw: UInt32 { get }
  init(_ raw: UInt32)
}

public protocol IdentifiedEntity {
  typealias ID = DocumentationID<Self>
}

/// A unique identifier that is a separate nominal type for each different kind of object that T refers to.
/// It is useful because it makes it impossible to pass/assign the wrong types of IDs to each other.
public struct DocumentationID<T: IdentifiedEntity>: DocumentationIDProtocol,
  CustomDebugStringConvertible
{
  public typealias Element = T
  public let raw: UInt32
  public init(_ raw: UInt32) {
    self.raw = raw
  }

  public var debugDescription: String {
    return "DocID<\(T.self)>(\(raw))"
  }
}

public protocol ReadableEntityStoreProtocol: Sequence {
  associatedtype Entity: IdentifiedEntity
  subscript(_ id: DocumentationID<Entity>) -> Entity? { get }
}

/// A store of entities that supports insertion and lookup by ID, both in O(1) time.
///
/// This data structure stores its elements in contiguous memory, which allows for fast lookup and
/// great cache locality.
///
/// It supports insertion and lookup but no modification or deletion of elements.
public struct EntityStore<T: IdentifiedEntity>: ReadableEntityStoreProtocol {
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

  public init() {}

  public init<S>(from entities: S) where S: Sequence, S.Element == T {
    self.entities = Array(entities)
  }

  /// conformance to Sequence protocol
  public func makeIterator() -> some IteratorProtocol<T> {
    return entities.makeIterator()
  }
}

/// Adapted Entity Store
public struct AdaptedEntityStore<ASTNodeType: Node, StoredDataT: IdentifiedEntity>:
  ReadableEntityStoreProtocol
{
  /// The entity store that stores the documentation entities in contiguous memory for fast lookup by documentation entity IDs.
  private var entityStore: EntityStore<StoredDataT> = .init()

  /// A mapping from AST node IDs to documentation entity IDs.
  private var idMapping: [ASTNodeType.ID: StoredDataT.ID] = [:]

  public init() {}

  /// Initializes the store with the given entities from a sequence of pairs of entities and their corresponding AST node IDs.
  public init(from entities: [(StoredDataT, for: ASTNodeType.ID)]) {
    for (entity, forId) in entities {
      let _ = insert(entity, for: forId)
    }
  }

  /// Returns the documentation entity for the given AST node ID if it exists.
  ///
  /// - Parameters:
  ///   - id: The AST node ID to look up.
  public subscript(_ id: ASTNodeType.ID) -> StoredDataT? {
    return idMapping[id].flatMap { entityStore[$0] }
  }

  /// Returns the documentation entity for the given documentation entity ID if it exists.
  ///
  /// - Parameters:
  ///   - id: The documentation entity ID to look up.
  public subscript(_ id: StoredDataT.ID) -> StoredDataT? {
    return entityStore[id]
  }

  /// Inserts the given documentation entity for the given AST node ID, and returns the documentation ID of the inserted entity.
  public mutating func insert(_ entity: StoredDataT, for id: ASTNodeType.ID) -> StoredDataT.ID {
    let newID = entityStore.insert(entity)
    idMapping[id] = newID
    return newID
  }

  public func documentationId(of: ASTNodeType.ID) -> StoredDataT.ID? {
    return idMapping[of]
  }

  /// conformance to Sequence protocol
  public func makeIterator() -> some IteratorProtocol<StoredDataT> {
    return entityStore.makeIterator()
  }
}
