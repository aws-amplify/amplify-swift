//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Protocol to implement for providers vending a user pool access token: the token counterpart of
/// `AWSCredentialsProvider`, so a client that needs tokens depends on AmplifyFoundation alone.
///
/// **Errors.** A provider's failures are `CredentialsError`, whose `disposition` says what to do with
/// buffered work, as for AWS credentials. `CancellationError` passes through unwrapped when the calling task
/// is cancelled.
@_spi(AmplifyExperimental)
public protocol AccessTokenProvider: Sendable {

    /// A currently valid access token.
    func accessToken() async throws -> String
}
