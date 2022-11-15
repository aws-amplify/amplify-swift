//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import Amplify

struct SignUpView: View {

    @State private var username: String = ""
    @State private var password: String = ""

    @State var errorLabel: String? = nil
    @State var successLabel: String? = nil

    private enum Identifiers {
        static let usernameField = "hostedUI_signup_username_field"
        static let passwordField = "hostedUI_signup_password_field"
        static let signUpButton = "hostedUI_signup_button"

        static let successLabel = "hostedUI_success_text"
        static let errorLabel = "hostedUI_error_text"
    }

    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .accessibility(identifier: Identifiers.usernameField)

            SecureField("Password", text: $password)
                .textContentType(.password)
                .accessibility(identifier: Identifiers.passwordField)

            Button("SignUp") {
                Task {
                    await signUp()
                }
            }
            .accessibility(identifier: Identifiers.signUpButton)
            Spacer()
            if let error = self.errorLabel {
                Text("Error occured: \(error)")
                    .accessibilityLabel(Identifiers.errorLabel)
            }
            if let successLabel = self.successLabel {
                Text("SignUp Succeeded \(successLabel)")
                    .accessibilityLabel(Identifiers.successLabel)
            }
        }
        .padding(20)
    }

    func signUp() async {
        self.successLabel = nil
        self.errorLabel = nil
        print("Password \(password)")
        do {
            let options = AuthSignUpRequest.Options(userAttributes: [.init(.email, value: username)])
            let signUpResult = try await Amplify.Auth.signUp(
                username: username,
                password: password,
                options: options
            )
            if signUpResult.isSignUpComplete {
                self.successLabel = "Complete"
            } else {
                self.errorLabel = "SignUp is not complete: \(signUpResult.nextStep)"
            }
        } catch {
            print("Unexpected error: \(error)")
            self.errorLabel = error.info()
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
