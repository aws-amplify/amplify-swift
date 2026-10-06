//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoAuthPlugin
import SwiftUI

struct SignedOutView: View {

    @State var errorLabel: String? = nil
    @State var successLabel: String? = nil
    /// Set when a sign-in button's tap reaches the app, so the UI tests can tell a lost tap from a
    /// slow hosted UI and only tap again for the former.
    @State var signInStarted = false

    private enum Identifiers {
        static let signUpNav = "hostedUI_signUp_view_nav"
        static let signInButton = "hostedUI_signIn_button"
        static let signInWithoutWindowButton = "hostedUI_signIn_wo_window_button"

        static let successLabel = "hostedUI_success_text"
        static let errorLabel = "hostedUI_error_text"
        static let signInStartedLabel = "hostedUI_signIn_started_text"
    }

    var body: some View {
        VStack {
            Spacer()
            Button("Sign In") {
                signInStarted = true
                Task {
                    await signInWithWebUI(anchor: getWindow())
                }
            }.accessibility(identifier: Identifiers.signInButton)

            Button("Sign In Without Window") {
                signInStarted = true
                Task {
                    await signInWithWebUI(anchor: nil)
                }
            }.accessibility(identifier: Identifiers.signInWithoutWindowButton)

            NavigationLink("Sign Up") {
                SignUpView()
            }
            .accessibility(identifier: Identifiers.signUpNav)
            Spacer()
            if signInStarted {
                Text("Sign in started")
                    .accessibilityIdentifier(Identifiers.signInStartedLabel)
            }
            if let error = errorLabel {
                Text("Error occured: \(error)")
                    .accessibilityLabel(Identifiers.errorLabel)
                    .accessibilityValue(error)
            }
            if let successLabel {
                Text("Succeeded: \(successLabel)")
                    .accessibilityLabel(Identifiers.successLabel)
            }
            Spacer()
        }

    }

    func signInWithWebUI(anchor: AuthUIPresentationAnchor?) async {
        do {
            // Ephemeral session, else a persisted cookie skips the login form.
            let signInResult = try await Amplify.Auth.signInWithWebUI(
                presentationAnchor: anchor,
                options: .preferPrivateSession()
            )
            if signInResult.isSignedIn {
                successLabel = "SignedIn"
            }
        } catch {
            print("Unexpected error: \(error)")
            errorLabel = error.info()
        }
    }

    func getWindow() async -> AuthUIPresentationAnchor {
#if os(macOS)
        return await MainActor.run {
            let window = NSApplication.shared.windows.first!
            return window
        }
#elseif canImport(UIKit)
        let scene = await UIApplication.shared.connectedScenes.first!
        let windowSceneDelegate = await scene.delegate as! UIWindowSceneDelegate
        let window = await windowSceneDelegate.window!!
        return window
#endif
    }

}

struct SignedOutView_Previews: PreviewProvider {
    static var previews: some View {
        SignedOutView()
    }
}
