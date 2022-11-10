//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import Amplify

struct ContentView: View {

    @State var username: String? = nil
    @State var loading: Bool = true

    var body: some View {
        NavigationView {
            if !loading {
                VStack {
                    if self.username != nil {
                        SignedInView(username: $username)
                    } else {
                        SignedOutView()
                    }
                }
                .padding()
            }

        }.onAppear {
            Task {
                await self.configureAuth()
            }
        }
    }

    func configureAuth() async {
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            self.username = user.username
        } catch {
            self.username = nil
        }
        self.loading = false
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
