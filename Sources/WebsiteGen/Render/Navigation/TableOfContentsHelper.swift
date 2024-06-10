import OrderedCollections

public struct tocItem: Equatable {
  var id: String
  var name: String
  var children: [tocItem] = []
}

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
    "seeAlso": "See Also",
  ]

  return buckets.filter { !isEmptyValue(value: stencilContext[$0.key]) }.map {
    (key, value) -> tocItem in
    if key == "members",
      let array = stencilContext[key] as? [OrderedDictionary<String, nameAndContentArray>.Element]
    {
      let children = array.map { $0.key }.map {
        tocItem(
          id: $0.prefix(1).lowercased() + $0.dropFirst().replacingOccurrences(of: " ", with: ""),
          name: $0, children: [])
      }
      return tocItem(id: key, name: value, children: children)
    }

    return tocItem(id: key, name: value, children: [])
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
