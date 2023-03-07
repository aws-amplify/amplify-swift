//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
		

import XCTest

final class PushNotificationHostAppUITests: XCTestCase {
    let timeout = TimeInterval(3)
    let app = XCUIApplication()

    lazy var deviceIdentifier: String? = {
        let paths = Bundle.main.bundleURL.pathComponents
        guard let index = paths.firstIndex(where: { $0 == "XCTestDevices" }),
              let identifier = paths.dropFirst(index + 1).first
        else {
            XCTFail("Failed to get device identifier")
            return nil
        }

        return identifier
    }()

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app.launch()
    }

    override func tearDown() async throws {
        await terminate()
//        try await uninstallApp()
    }

    @MainActor
    func testInitAmplify_withPushNotificationPlugin_verifyRequestNotificationsPermissions() async throws {
        initAmplify()

        grantNotificationPermissionIfNeeded()

        let expectedEvent = anyElementContains(
            text: "Notifications.Push.requestNotificationsPermissions = Optional(true)",
            scope: app
        )
        if !expectedEvent.waitForExistence(timeout: 3) {
            XCTFail("Failed to receive requestNotificationsPermissions event from hub")
        }
    }

    @MainActor
    func testIdentifyUser_withPushNotificationPlugin_verifySuccessful() async throws {
        initAmplify()
        grantNotificationPermissionIfNeeded()

        let identifyUserButton = app.buttons["Identify User"]
        if identifyUserButton.waitForExistence(timeout: timeout) {
            identifyUserButton.tap()
        } else {
            XCTFail("Failed to find 'Identify User' button")
            return
        }

        let firstAlert = app.alerts.firstMatch
        if !firstAlert.waitForExistence(timeout: timeout) ||
            !anyElementContains(text: "Identified User", scope: firstAlert).waitForExistence(timeout: timeout)
        {
            XCTFail("Failed to identify user")
        }
    }

    @MainActor
    func testRegisterDevice_withPushNotificationPlugin_verifySuccessful() async throws {
        initAmplify()
        grantNotificationPermissionIfNeeded()

        let identifyUserButton = app.buttons["Register Device"]
        if identifyUserButton.waitForExistence(timeout: timeout) {
            identifyUserButton.tap()
        } else {
            XCTFail("Failed to find 'Register Device' button")
            return
        }

        let firstAlert = app.alerts.firstMatch
        if !firstAlert.waitForExistence(timeout: timeout) ||
            !anyElementContains(text: "Registered Device", scope: firstAlert).waitForExistence(timeout: timeout)
        {
            XCTFail("Failed to register device")
        }
    }

    @MainActor
    func testAppInBackground_withPinpointRemoteNotification_recordNotificationOpened() async throws {
        initAmplify()

        grantNotificationPermissionIfNeeded()
        pressHomeButton()

        try await triggerNotification(notification: PinpointNotification(
            notification: Notification(
                title: "Test",
                substitle: nil,
                body: #function
            ),
            data: PinpointData(
                pinpoint: PinpointInfo(
                    campaign: [
                        "test": "test"
                    ],
                    journey: nil,
                    deeplink: nil
                )),
            deviceId: deviceIdentifier!
        ))

        let notification = XCUIApplication.springboard.otherElements.descendants(matching: .any)["NotificationShortLookView"]
        if notification.waitForExistence(timeout: timeout) {
            notification.tap()
        } else {
            XCTFail("Failed to receive push notification")
            return
        }

        if !app.wait(for: .runningForeground, timeout: timeout) {
            XCTFail("Failed to open App with push notification")
            return
        }

        let expectedEvent = anyElementContains(
            text: "Amplify.BasicAnalyticsEvent(name: \"_campaign.opened_notification\"",
            scope: app
        )

        if !expectedEvent.waitForExistence(timeout: 3) {
            XCTFail("Failed to receive open_notification event from hub")
        }
    }

    @MainActor
    func testAppInBackground_withBasicAppleRemoteNotification_notRecordNotificationOpened() async throws {
        initAmplify()

        grantNotificationPermissionIfNeeded()
        pressHomeButton()

        try await triggerNotification(notification: PinpointNotification(
            notification: Notification(
                title: "Test",
                substitle: nil,
                body: #function
            ),
            data: nil,
            deviceId: deviceIdentifier!
        ))

        let notification = XCUIApplication.springboard.otherElements.descendants(matching: .any)["NotificationShortLookView"]
        if notification.waitForExistence(timeout: timeout) {
            notification.tap()
        } else {
            XCTFail("Failed to receive push notification")
            return
        }

        if !app.wait(for: .runningForeground, timeout: timeout) {
            XCTFail("Failed to open App with push notification")
            return
        }

        let unexpectedEvent = anyElementContains(
            text: "Amplify.BasicAnalyticsEvent(name: \"_campaign.opened_notification\"",
            scope: app
        )
        if unexpectedEvent.waitForExistence(timeout: 3) {
            XCTFail("Should not record notification without pinpoint info.")
        }
    }

    @MainActor
    func testAppInForeground_withPinpointRemoteNotification_recordNotificationReceived() async throws {
        initAmplify()

        grantNotificationPermissionIfNeeded()

        try await triggerNotification(notification: PinpointNotification(
            notification: Notification(
                title: "Test",
                substitle: nil,
                body: #function
            ),
            data: PinpointData(
                pinpoint: PinpointInfo(
                    campaign: [
                        "test": "test"
                    ],
                    journey: nil,
                    deeplink: nil
                )),
            deviceId: deviceIdentifier!
        ))

        let expectedEvent = anyElementContains(text: "Amplify.BasicAnalyticsEvent(name: \"_campaign.received_", scope: app)
        if !expectedEvent.waitForExistence(timeout: 3) {
            XCTFail("Failed to receive open_notification event from hub")
        }
    }

    @MainActor
    func testAppInForeground_withBasicAppleRemoteNotification_notRecordNotificationReceived() async throws {
        initAmplify()

        grantNotificationPermissionIfNeeded()

        try await triggerNotification(notification: PinpointNotification(
            notification: Notification(
                title: "Test",
                substitle: nil,
                body: #function
            ),
            data: nil,
            deviceId: deviceIdentifier!
        ))

        let unexpectedEvent = anyElementContains(text: "Amplify.BasicAnalyticsEvent(name: \"_campaign.received_", scope: app)
        if unexpectedEvent.waitForExistence(timeout: timeout) {
            XCTFail("Should not record notification without pinpoint info")
        }
    }

    private func initAmplify() {
        let initAmplifyButton = app.buttons["Init Amplify"]
        if initAmplifyButton.waitForExistence(timeout: timeout) {
            initAmplifyButton.tap()
        } else {
            XCTFail("Failed to find `Init Amplify` button")
        }
    }

    private func grantNotificationPermissionIfNeeded() {
        let alert = XCUIApplication.springboard.alerts.firstMatch
        if alert.waitForExistence(timeout: timeout) {
            XCTAssertTrue(anyElementContains(text: "Would Like to Send You Notifications", scope: alert).exists)
            alert.buttons["Allow"].tap()
        }
    }

    private func triggerNotification(notification: PinpointNotification) async throws {
        let request = LocalServer.notifications(notification).urlRequest
        let (_, response) = try await URLSession.shared.data(for: request)
        XCTAssertTrue((response as! HTTPURLResponse).statusCode < 300, "Failed to trigger notification")
    }

    private func uninstallApp() async throws {
        let request = LocalServer.uninstall(deviceIdentifier!).urlRequest
        let (_, response) = try await URLSession.shared.data(for: request)
        XCTAssertTrue((response as! HTTPURLResponse).statusCode < 300, "Failed to uninstall the App")
    }

    private func pressHomeButton() {
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        let springboard = XCUIApplication.springboard
        springboard.activate()

        if !springboard.wait(for: .runningForeground, timeout: timeout) {
            XCTFail("Failed to get back to home screen")
            return
        }
        
        if !app.wait(for: .runningBackground, timeout: timeout) {
            XCTFail("Failed to put app to the background")
            return
        }
    }

    private func anyElementContains(text: String, scope: XCUIElement) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return scope.staticTexts.matching(predicate).firstMatch
    }

    @MainActor
    private func terminate() {
        app.terminate()
    }

}

extension XCUIApplication {
    static var springboard: XCUIApplication {
        XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }
}
