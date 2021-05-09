//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct Attribute {

    /// <#Description#>
    public let name: String

    /// <#Description#>
    public let value: Bool

    /// <#Description#>
    public let confidence: Double

    /// <#Description#>
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - value: <#value description#>
    ///   - confidence: <#confidence description#>
    public init(name: String, value: Bool, confidence: Double) {
        self.name = name
        self.value = value
        self.confidence = confidence
    }
}

/// <#Description#>
public struct GenderAttribute {

    /// <#Description#>
    public var gender: GenderType

    /// <#Description#>
    public var confidence: Double

    /// <#Description#>
    /// - Parameters:
    ///   - gender: <#gender description#>
    ///   - confidence: <#confidence description#>
    public init(gender: GenderType, confidence: Double) {
        self.gender = gender
        self.confidence = confidence
    }
}
