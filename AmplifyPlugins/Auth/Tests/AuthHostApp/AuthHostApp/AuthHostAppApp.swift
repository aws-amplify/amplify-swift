//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import Amplify
import protocol Amplify.Model

@main
struct AuthHostAppApp: App {

    typealias AmplifyModel = Amplify.Model

    func doOneThing() async -> AmplifyModel { fatalError() }

    func doOtherThing() async -> Amplify.Model { fatalError() }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
