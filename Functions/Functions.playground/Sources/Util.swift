import XCTest

// NB: `@_exported` will make foundation available in our playgrounds
@_exported import Foundation

@discardableResult
public func assertEqual<A: Equatable>(_ lhs: A, _ rhs: A) -> String {
  return lhs == rhs ? "✅" : "❌"
}

@discardableResult
public func assertEqual<A: Equatable, B: Equatable>(_ lhs: (A, B), _ rhs: (A, B)) -> String {
  return lhs == rhs ? "✅" : "❌"
}

public var __: Void {
  print("--")
}

public func incr(_ x: Int) -> Int {
  return x + 1
}

public func square(_ x: Int) -> Int {
  return x * x
}
