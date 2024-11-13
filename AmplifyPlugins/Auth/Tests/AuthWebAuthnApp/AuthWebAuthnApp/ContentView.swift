//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoAuthPlugin
import SwiftUI

struct ContentView: View {
    @State private var lastResult: String = ""
    @State private var credentialId: String = ""
    @State private var isSignedUp: Bool = false
    @State private var isSignedIn: Bool = false

    private let username = "integTest\(UUID().uuidString)"
    private let password = "Pp123@\(UUID().uuidString)"
    private let email = "test-\(UUID().uuidString)@amplify-swift-gamma.awsapps.com"

    var body: some View {
        ScrollView {
            VStack {
                Text(username)
                    .accessibilityIdentifier("Username")
                Divider()
                if isSignedIn {
                    Button("Sign Out") {
                        Task {
                            lastResult = ""
                            _ = await Amplify.Auth.signOut()
                            isSignedIn = false
                            lastResult = "User is signed out"
                        }
                    }
                    .accessibilityIdentifier("SignOut")
                } else {
                    if isSignedUp {
                        Button("Sign In") {
                            Task {
                                await signIn(authFlowType: .userAuth(preferredFirstFactor: .webAuthn))
                            }
                        }
                        .accessibilityIdentifier("SignIn")
                    } else {
                        Button("Sign Up and Sign In") {
                            Task {
                                await signUpAndSignIn()
                            }
                        }
                        .accessibilityIdentifier("SignUp")
                    }
                }

                Button("Associate WebAuthn Credential") {
                    Task {
                        do {
                            lastResult = ""
                            try await Amplify.Auth.associateWebAuthnCredential()
                            lastResult = "WebAuthn credential was associated"
                        } catch {
                            lastResult = "Associate WebAuthn Credential failed: \(error)"
                        }
                    }
                }
                .accessibilityIdentifier("AssociateWebAuthn")

                Button("List WebAuthn Credentials") {
                    Task {
                        do {
                            lastResult = ""
                            let result = try await Amplify.Auth.listWebAuthnCredentials()
                            lastResult = "WebAuthn Credentials: \(result.credentials.count)"
                            if let firstCredential = result.credentials.first {
                                credentialId = firstCredential.credentialId
                            }
                        } catch {
                            lastResult = "List WebAuthn Credentials failed: \(error)"
                        }
                    }
                }
                .accessibilityIdentifier("ListWebAuthn")

                Button("Delete WebAuthn Credential") {
                    Task {
                        do {
                            lastResult = ""
                            try await Amplify.Auth.deleteWebAuthnCredential(credentialId: credentialId)
                            lastResult = "WebAuthn credential was deleted"
                        } catch {
                            lastResult = "Delete WebAuthn Credential failed: \(error)"
                        }
                    }
                }
                .accessibilityIdentifier("DeleteWebAuthn")

                Button("Delete User") {
                    Task {
                        lastResult = ""
                        try? await Amplify.Auth.deleteUser()
                        lastResult = "User was deleted"
                        isSignedIn = false
                        isSignedUp = false
                    }
                }
                .accessibilityIdentifier("DeleteUser")

                Divider()

                Text(lastResult)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .accessibilityIdentifier("LastResult")

                Spacer()
            }
            .padding()
        }
    }

    private func signUpAndSignIn() async {
        do {
            lastResult = ""
            let signUpResult = try await Amplify.Auth.signUp(
                username: username,
                password: password,
                options: .init(userAttributes: [.init(.email, value: email)])
            )

            guard signUpResult.isSignUpComplete else {
                lastResult = "Sign Up was not completed. Next step is: \(signUpResult.nextStep)"
                return
            }

            lastResult = "User is signed up"
            isSignedUp = true

            await signIn(
                password: password,
                authFlowType: .userPassword
            )
        } catch {
            lastResult = "Sign Up failed: \(error)"
        }
    }

    private func signIn(
        password: String? = nil,
        authFlowType: AuthFlowType
    ) async {
        do {
            lastResult = ""
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init(
                    pluginOptions: AWSAuthSignInOptions(
                        authFlowType: authFlowType
                    )
                )
            )

            guard signInResult.isSignedIn else {
                lastResult = "Sign In was not completed. Next step is: \(signInResult.nextStep)"
                return
            }

            lastResult = "User is signed in"
            isSignedIn = true
        } catch {
            lastResult = "Sign In failed: \(error)"
        }
    }
}
