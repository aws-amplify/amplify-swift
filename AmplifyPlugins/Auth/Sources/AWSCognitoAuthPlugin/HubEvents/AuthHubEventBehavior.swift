//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Note: `Sendable` because the handler is stored on the plugin, which is `Sendable`.
protocol AuthHubEventBehavior: Sendable {

    func sendUserSignedInEvent()

    func sendUserSignedOutEvent()

    func sendUserDeletedEvent()

    func sendSessionExpiredEvent()
}
