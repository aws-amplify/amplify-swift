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
    static var unknown: Self { get }
    
    static var allFormats: [String] { get }
}
