//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Note: `@Sendable` because the factory lives on a `Sendable` environment.
typealias EventIDFactory = @Sendable () -> String

enum UUIDFactory {
    nonisolated(unsafe) static let factory: EventIDFactory = { UUID().uuidString }
}
