//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Implement this protocol to support versioning in your plugin
protocol AmplifyVersionable {
    var version: String { get }
}
