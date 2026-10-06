//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

#if os(iOS) || os(macOS) || os(visionOS)
/// The plugin half of `HostedUIOptions`: the initializer that takes the public
/// `AWSAuthWebUISignInOptions.Prompt` values. `prompt` is stored, and persisted, as the space-separated
/// `String` it builds, so the public type never enters the engine.
extension HostedUIOptions {
    init(
        scopes: [String],
        providerInfo: HostedUIProviderInfo,
        presentationAnchor: EnginePresentationAnchor?,
        preferPrivateSession: Bool,
        nonce: String?,
        language: String?,
        loginHint: String?,
        promptValues: [AWSAuthWebUISignInOptions.Prompt]?,
        resource: String?
    ) {
        self.init(
            scopes: scopes,
            providerInfo: providerInfo,
            presentationAnchor: presentationAnchor,
            preferPrivateSession: preferPrivateSession,
            nonce: nonce,
            language: language,
            loginHint: loginHint,
            prompt: promptValues?.map { "\($0.rawValue)" }.joined(separator: " "),
            resource: resource
        )
    }
}
#endif
