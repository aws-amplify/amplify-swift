//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Struct describing attribute of an entity with confidence value
public struct Attribute {
    public let name: String
    public let value: Bool
    public let confidence: Double

    public init(name: String, value: Bool, confidence: Double) {
        self.name = name
        self.value = value
        self.confidence = confidence
    }
}

/// Struct describing gender of an entity with confidence value
public struct GenderAttribute {
    public var gender: GenderType
    public var confidence: Double

    public init(gender: GenderType, confidence: Double) {
        self.gender = gender
        self.confidence = confidence
    }
}
