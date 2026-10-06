//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// Temporary AWS credentials vended by a session.
///
/// Internal and concrete, so it can cross from the session actor: `any AWSCredentials` is not
/// `Sendable`. It is upcast only inside the provider's nonisolated `resolve()`.
struct CognitoAWSCredentials: AWSTemporaryCredentials, Sendable, Equatable {
    let accessKeyId: String
    let secretAccessKey: String
    let sessionToken: String
    let expiration: Date
}
