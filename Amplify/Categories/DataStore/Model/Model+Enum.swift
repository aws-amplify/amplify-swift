//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol that represents a `Codable` Enum that can be persisted and easily
/// integrate with remote APIs since it must have a raw `String` value.
///
/// That means only simple enums (i.e. the ones that don't have arguments) can be used
/// as model properties.
///
/// - Example:
///
/// ```swift
/// public enum PostStatus: String, PersistentEnum {
///     case draft
///     case published
/// }
/// ```
public protocol PersistentEnum: Codable {

    /// The `String` representation. Make your enum conform to `String`
    /// to get an automatic `rawValue`.
    /// See the [Enumeration Language Guide](https://docs.swift.org/swift-book/LanguageGuide/Enumerations.html#ID149)
    /// for details on enum with raw values.
    var rawValue: String { get }

}
