//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

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

public struct GenderAttribute {
    public var gender: GenderType
    public var confidence: Double

    public init(gender: GenderType, confidence: Double) {
        self.gender = gender
        self.confidence = confidence
    }
}
