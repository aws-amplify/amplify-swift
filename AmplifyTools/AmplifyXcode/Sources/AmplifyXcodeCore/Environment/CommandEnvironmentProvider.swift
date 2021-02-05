//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Defines requirement on an environment object for a command executor
public protocol CommandEnvironmentProvider {
    var environment: AmplifyCommandEnvironment { get }
}
