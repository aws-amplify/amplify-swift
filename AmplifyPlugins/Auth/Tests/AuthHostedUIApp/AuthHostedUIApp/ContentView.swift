//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import SwiftUI

struct ContentView: View {

    @State var username: String? = nil
    @State var loading: Bool = true

    var body: some View {
        NavigationView {
            if !loading {
                VStack {
                    if username != nil {
                        SignedInView(username: $username)
                    } else {
                        SignedOutView()
                    }
                }
                .padding()
            }

        }.onAppear {
            Task {
                await configureAuth()
            }
        }
    }

    func configureAuth() async {
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            username = user.username
        } catch {
            username = nil
        }
        loading = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
