//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol that represents a `Codable` Enum that can be persisted and easily
/// integrate with remote APIs since it must have a raw `String` value.
///
/// That means only enums without associated values can be used as model properties.
///
/// - Example:
///
/// ```swift
/// public enum PostStatus: String, EnumPersistable {
///     case draft
///     case published
/// }
/// ```
/// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
///   by host applications. The behavior of this may change without warning.
/// - Note: `Sendable` because codegen'd enums stored on models conform to this, and `Model` is
///   `Sendable`. Raw-value enums satisfy it without change.
public protocol EnumPersistable: Codable, Sendable {

    var rawValue: String { get }

    init?(rawValue: String)

}
