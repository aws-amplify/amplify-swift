//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// - Note: `Sendable` because the dispatcher is handed to actions that run concurrently.
protocol EventDispatcher: Sendable {
    func send(_ event: StateMachineEvent) async
}
