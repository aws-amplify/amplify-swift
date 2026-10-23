//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// An empty shell. It exists so the integration tests run inside a signed iOS app, which is what
/// gives them a real data-protection keychain; `swift test` on macOS is unsigned and cannot.
@main
struct CognitoClientHostAppApp: App {
    var body: some Scene {
        WindowGroup {
            Text("AmplifyCognitoClient integration test host")
        }
    }
}
