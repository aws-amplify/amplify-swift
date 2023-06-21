//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol RemoteLoggingConstraintsProvider {
    var refreshIntervalInSeconds: Int { get }
    func fetchLoggingConstraints() async throws -> LoggingConstraints
}
