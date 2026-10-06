//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Defaults for tests that drive an engine directly, with no core around it: epoch 0, a cancel of
/// everything, and a forced refresh. They live in the test target, so no production caller can compile
/// against them and skip the core's epoch or `force`.
extension SessionEngine {

    func signIn(_ request: EngineSignInRequest, current: Data?) async throws -> EngineStepResult {
        try await signIn(request, current: current, epoch: 0)
    }

    func confirmSignIn(_ request: EngineConfirmSignInRequest, current: Data?) async throws -> EngineStepResult {
        try await confirmSignIn(request, current: current, epoch: 0)
    }

    func autoSignIn(current: Data?) async throws -> EngineStepResult {
        try await autoSignIn(current: current, epoch: 0)
    }

    func cancelPendingSignIn() async {
        await cancelPendingSignIn(before: .max)
    }

    func refresh(_ payload: Data) async throws -> Data {
        try await refresh(payload, force: true)
    }
}
