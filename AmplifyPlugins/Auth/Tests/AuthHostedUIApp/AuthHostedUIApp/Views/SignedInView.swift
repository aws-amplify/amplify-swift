//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin

struct SignedInView: View {

    @Binding var username: String?

    private enum Identifiers {
        static let signOutButton = "hostedUI_signOut_button"
    }

    var body: some View {
        VStack {
            Text("Welcome \(username ?? "")")
            Button("Sign Out") {
                Task {
                    await signOut()
                }
            }
            .accessibilityLabel(Identifiers.signOutButton)

            Button("Fetch Auth Session") {

            }
        }
    }

    func signOut() async {
        let result = await Amplify.Auth.signOut()
        guard let signOutResult = result as? AWSCognitoSignOutResult
        else {
            print("Signout failed")
            return
        }

        print("Local signout successful: \(signOutResult.signedOutLocally)")
        switch signOutResult {
        case .complete:
            print("SignOut completed")
            username = nil
        case .failed(let error):
            print("SignOut failed with \(error)")
        default:
            print("Default signout case")
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignedInView(username: .constant("username"))
    }
}
