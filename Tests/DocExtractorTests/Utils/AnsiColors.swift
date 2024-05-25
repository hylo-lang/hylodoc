struct ANSIColors {
  static let _reset: String = "\u{001B}[0;0m"
  static let _black: String = "\u{001B}[0;30m"
  static let _red: String = "\u{001B}[0;31m"
  static let _green: String = "\u{001B}[0;32m"
  static let _yellow: String = "\u{001B}[0;33m"
  static let _blue: String = "\u{001B}[0;34m"
  static let _magenta: String = "\u{001B}[0;35m"
  static let _cyan: String = "\u{001B}[0;36m"
  static let _white: String = "\u{001B}[0;37m"

  static func black(_ text: String) -> String {
    return _black + text + _reset
  }

  static func red(_ text: String) -> String {
    return _red + text + _reset
  }

  static func green(_ text: String) -> String {
    return _green + text + _reset
  }

  static func yellow(_ text: String) -> String {
    return _yellow + text + _reset
  }

  static func blue(_ text: String) -> String {
    return _blue + text + _reset
  }

  static func magenta(_ text: String) -> String {
    return _magenta + text + _reset
  }

  static func cyan(_ text: String) -> String {
    return _cyan + text + _reset
  }

  static func white(_ text: String) -> String {
    return _white + text + _reset
  }
}
