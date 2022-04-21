//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Type-erased protocol for `TemporalSpec`
public protocol _AnyTemporalSpec {
    var iso8601String: String { get }
}
