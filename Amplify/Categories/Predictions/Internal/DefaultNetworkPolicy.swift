//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// DefaultNetworkPolicy of the operation
public enum DefaultNetworkPolicy {
    /// `offline` operation doesnot make network call
    case offline

    case online

    /// `auto` operation make use of online and offline calls.
    case auto
}
