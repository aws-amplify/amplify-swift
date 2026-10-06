//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// The host app of the client's WebAuthn UI tests (WA-0 and WA-1).
///
/// It is the client's counterpart of the plugin's `AuthWebAuthnApp`, and it signs as that app does
/// (same team and bundle identifier), because the relying party's apple-app-site-association lists
/// only that app ID. It links the client and the raw AWS SDK, never Amplify.
///
/// The launch argument `-WebAuthnDriver raw` or `-WebAuthnDriver client` picks what the buttons call:
/// the raw Cognito API with `AuthenticationServices` (WA-0, which proves the sandbox and the simulator
/// set-up today), or the client's WebAuthn API (WA-1, compiled only with `COGNITO_CLIENT_WEBAUTHN_API`).
@main
struct CognitoClientWebAuthnApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(driver: WebAuthnHarness.makeDriver())
        }
    }
}
