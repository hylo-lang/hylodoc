import OrderedCollections

public typealias tocItem = (id: String, name: String, children: [Any])

public func tableOfContents(stencilContext: [String: Any] = [:]) -> [tocItem] {
  let buckets: OrderedDictionary<String, String> = [
    "details": "Details",
    "content": "Content",
    "contents": "Contents",
    "preconditions": "Preconditions",
    "postconditions": "Postconditions",
    "returns": "Returns",
    "yields": "Yields",
    "throwsInfo": "Throws Info",
    "parameters": "Parameters",
    "genericParameters": "Generic Parameters",
    "invariants": "Invariants",
    "members": "Members",
    "description": "Description",
    "seeAlso": "See Also",
  ]

  return buckets.filter { !isEmptyValue(value: stencilContext[$0.key]) }.map {
    (key, value) -> tocItem in
    if key == "members",
      let array = stencilContext[key] as? [OrderedDictionary<String, nameAndContentArray>.Element]
    {
      let children = array.map { $0.key }.map {
        (id: $0.prefix(1).lowercased() + $0.dropFirst(), name: $0)
      }
      return (id: key, name: value, children: children)
    }

    return (id: key, name: value, children: [])
  }
}

private func isEmptyValue(value: Any?) -> Bool {
  guard let value = value else {
    return true
  }

  if let array = value as? [Any] {
    return array.isEmpty
  } else if let string = value as? String {
    return string.isEmpty
  } else if let dictionary = value as? [AnyHashable: Any] {
    return dictionary.isEmpty
  }

  return false
}
