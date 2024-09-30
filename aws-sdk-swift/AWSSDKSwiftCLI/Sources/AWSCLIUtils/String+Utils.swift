//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension String {
    /// Returns the receiver wrapped in the provided string
    ///
    /// ```swift
    /// let example = "a".wrapped(in: "1")
    /// print(example) // prints 1a1
    /// ```
    ///
    /// - Parameter char: The string to wrap the reciever in
    /// - Returns: The receiver wrapped in the provided string
    func wrapped(in string: String) -> String {
        "\(string)\(self)\(string)"
    }
    
    /// Returns the receiver wrapped quotes
    ///
    /// ```swift
    /// let example = "swift".wrappedInQuotes()
    /// print(example) // prints "swift"
    /// ```
    ///
    /// - Parameter char: The string to wrap the reciever in
    /// - Returns: The receiver wrapped in the provided string
    func wrappedInQuotes() -> String {
        wrapped(in: "\"")
    }
    
    /// Returns the string that represents a newline
    static var newline: Self { "\n" }
}

public func printError(_ items: Any..., separator: String = " ", terminator: String = "\n") throws {
    var s = ""
    print(items, separator: separator, terminator: terminator, to: &s)
    try FileHandle.standardError.write(contentsOf: Data(s.utf8))
}
