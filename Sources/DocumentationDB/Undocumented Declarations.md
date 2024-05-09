
# Undocumented Declarations

## `conformance-decl`
```swift
public trait MyTrait { ... }
public conformance String: MyTrait { .. }
```

## `extension-decl`
```swift
public type MyType { ... }
public extension MyType { fun toHTML() -> String { ... } }
```

## `namespace-decl`
The problem is that namespaces can be introduced in multiple modules.
```swift
/// In a file:
public namespace MyNamespace { ... }
```