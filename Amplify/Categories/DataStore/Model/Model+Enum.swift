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
/// public enum PostStatus: String, EnumPersistable {
///     case draft
///     case published
/// }
/// ```
public protocol EnumPersistable: Codable {

    var rawValue: String { get }

    init?(rawValue: String)

}
