//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// The host app of the client's hosted-UI UI tests (`CognitoClientUITests`, HU-1 and HU-2).
///
/// It is the client's counterpart of the plugin's `AuthHostedUIApp`: one screen that signs in through the
/// hosted UI and signs out, on the plugin's hosted-UI backend (on the sandbox, P-7), whose redirect URIs use
/// the plugin's `myapp://` scheme, which this app registers too (with its own `cognitoclienthostapp`). It
/// links the client only, never Amplify. The users it signs in
/// are created and deleted by the UI tests, which also paste their credentials into the hosted UI's form:
/// the app never holds a password.
@main
struct CognitoClientHostedUIApp: App {
    var body: some Scene {
        WindowGroup {
            HostedUIView(client: HostedUIHarness.makeClient())
        }
    }
}
