//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Predictions {
    /// Attribute of an entity identified as a result of identify() API
    public struct Attribute {
        public let name: String
        public let value: Bool
        public let confidence: Double

        public init(
            name: String,
            value: Bool,
            confidence: Double
        ) {
            self.name = name
            self.value = value
            self.confidence = confidence
        }
    }
}

extension Predictions {
    /// Gender of an entity(face/celebrity) identified with
    /// associated confidence value
    public struct GenderAttribute {
        public var gender: Gender
        public var confidence: Double

        public init(
            gender: Gender,
            confidence: Double
        ) {
            self.gender = gender
            self.confidence = confidence
        }
    }
}
