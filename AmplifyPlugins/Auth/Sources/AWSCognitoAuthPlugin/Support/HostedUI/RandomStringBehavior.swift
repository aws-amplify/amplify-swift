//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Note: `Sendable` because the generator is produced by a `@Sendable` factory on the HostedUI
///   environment, which is itself `Sendable`.
protocol RandomStringBehavior: Sendable {

    func generateUUID() -> String

    func generateRandom(byteSize: Int) -> String?
}
