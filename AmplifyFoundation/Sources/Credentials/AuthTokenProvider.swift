//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Provides authentication tokens for signed-in users.
///
/// Returns `nil` when no user is signed in (guest mode).
/// When a token is available, the Connect client uses the authenticated
/// path (Bearer token). When nil, it falls back to the guest (SigV4) path.
public protocol AuthTokenProvider {
    func getToken() async throws -> AuthToken?
}
