//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
		

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AWSPinpointPushNotificationsPlugin
import AWSPinpointAnalyticsPlugin

let configFilePath = "testconfiguration/AWSPushNotificationPluginIntegrationTest-amplifyconfiguration"

var pushNotificationHubSubscription: UnsubscribeToken?
var analyticsHubSubscription: UnsubscribeToken?

struct ContentView: View {

    @State var hubEvents: [String] = []
    @State var showIdentifyUserDone: Bool = false
    @State var showRegisterTokenDone: Bool = false

    var body: some View {
        VStack {
            Button("Init Amplify", action: initAmplify)

            Button("Identify User", action: identifyUser)
            .alert(isPresented: $showIdentifyUserDone) {
                Alert(title: Text("Identified User"))
            }

            Button("Register Device", action: registerDevice)
            .alert(isPresented: $showRegisterTokenDone) {
                Alert(title: Text("Registered Device"))
            }

            Text(hubEvents.joined(separator: "\n"))
            Spacer()
        }
        .padding()
    }

    func initAmplify() {
        do {
            let config = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: configFilePath)
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSPinpointAnalyticsPlugin())
            try Amplify.add(plugin: AWSPinpointPushNotificationsPlugin())
            try Amplify.configure(config)

            listenHubEvent()
        } catch {
            print("Failed to init Amplify", error)
        }
    }

    func listenHubEvent() {
        pushNotificationHubSubscription = Amplify.Hub.listen(to: .pushNotifications) { payload in
            if payload.eventName == HubPayload.EventName.Notifications.Push.registerForRemoteNotifications {
                self.hubEvents.append(payload.eventDescription)
            }
        }

        analyticsHubSubscription = Amplify.Hub.listen(to: .analytics) { payload in
            if payload.eventName == HubPayload.EventName.Analytics.flushEvents {
                self.hubEvents.append(payload.eventDescription)
            }
        }
    }

    func identifyUser() {
        Task {
            do {
                try await Amplify.Notifications.Push.identifyUser(userId: UUID().uuidString)
                self.showIdentifyUserDone = true
            } catch {
                print(#function, "Failed to identify user", error)
            }
        }
    }

    func registerDevice() {
        let randomDeviceToken = Data.generateRandomDeviceToken()
        Task {
            do {
                try await Amplify.Notifications.Push.registerDevice(apnsToken: randomDeviceToken)
                self.showRegisterTokenDone = true
            } catch {
                print(#function, "Failed to register device token", error)
            }
        }
    }
}

extension HubPayload {
    var eventDescription: String {
        "\(self.eventName) = \(String(describing: self.data))"
    }
}

extension Data {
    static func generateRandomDeviceToken() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        let random = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }
}
