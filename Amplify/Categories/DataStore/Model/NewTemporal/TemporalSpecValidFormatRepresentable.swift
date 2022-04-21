//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol TemporalSpecValidFormatRepresentable: Equatable {
    var value: String { get }
    
    static var short: Self { get }
    static var medium: Self { get }
    static var long: Self { get }
    static var full: Self { get }
    
    /// Using `.unknown` will result in all of the formats being checked
    /// in the order of `.allFormats`
    ///
    /// 1. `.full`
    /// 2. `.long`
    /// 3. `.medium`
    /// 4. `.short`
    static var unknown: Self { get }
    
    /// All supported formats in `[String]` form, ordered from most specific format to least.
    static var allFormats: [String] { get }
}

public struct ValidFormatRepresenting<T> {
    let value: String
}
