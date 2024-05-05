/// A unique identifier that is a separate nominal type for each different kind of object that T refers to.
/// It is useful because it makes it impossible to pass/assign the wrong types of IDs to each other.
public struct CustomID<T>: Hashable, Equatable {
    public let raw: Int
    public init(_ raw: Int) {
        self.raw = raw
    }
}


/// A store of entities that supports insertion and lookup by ID, both in O(1) time.
public struct EntityStore<T> {
    var entities: [T] = []

    public func at(id: CustomID<T>) -> T? {
        if id.raw < 0 || id.raw >= entities.count {
            return nil
        }
        return entities[id.raw]
    }

    public mutating func insert(_ entity: T) -> CustomID<T> {
        entities.append(entity)
        return CustomID<T>(entities.count - 1)
    }
}
