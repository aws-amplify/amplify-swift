//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
		

import XCTest

final class PushNotificationHostAppUITests: XCTestCase {
    let timeout = TimeInterval(6)
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

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        try await bootDevice()
    #if os(iOS)
        XCUIDevice.shared.orientation = .portrait
    #endif

        if ProcessInfo.processInfo.arguments.contains("GEN2") {
            app.launchArguments.append("GEN2")
        }

        app.launch()
    }

    override func tearDown() async throws {
        await terminate()
        try await uninstallApp()
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
        #if os(tvOS)
            identifyUserButton.select(direction: .vertical)
        #else
            identifyUserButton.tap()
        #endif

        } else {
            XCTFail("Failed to find 'Identify User' button")
        }

        let firstAlert = firstAlertElement()
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

        let registerDeviceButton = app.buttons["Register Device"]
        if registerDeviceButton.waitForExistence(timeout: timeout) {
        #if os(tvOS)
            registerDeviceButton.select(direction: .vertical)
        #else
            registerDeviceButton.tap()
        #endif

        } else {
            XCTFail("Failed to find 'Register Device' button")
        }

        let firstAlert = firstAlertElement()
        if !firstAlert.waitForExistence(timeout: timeout) ||
            !anyElementContains(text: "Registered Device", scope: firstAlert).waitForExistence(timeout: timeout)
        {
            XCTFail("Failed to register device")
        }
    }

#if !os(tvOS)
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

        let notification = notificationElement()
        if notification.waitForExistence(timeout: timeout) {
            notification.tap()
        } else {
            XCTFail("Failed to receive push notification")
        }

        if !app.wait(for: .runningForeground, timeout: timeout) {
            XCTFail("Failed to open App with push notification")
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

        let notification = notificationElement()
        if notification.waitForExistence(timeout: timeout) {
            notification.tap()
        } else {
            XCTFail("Failed to receive push notification")
        }

        if !app.wait(for: .runningForeground, timeout: timeout) {
            XCTFail("Failed to open App with push notification")
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
#endif

    private func initAmplify() {
        let initAmplifyButton = app.buttons["Init Amplify"]
        if initAmplifyButton.waitForExistence(timeout: timeout) {
        #if os(tvOS)
            initAmplifyButton.select(direction: .vertical)
        #else
            initAmplifyButton.tap()
        #endif

        } else {
            XCTFail("Failed to find `Init Amplify` button")
        }
    }

    private func grantNotificationPermissionIfNeeded() {
    #if os(tvOS)
        let alert = XCUIApplication.homeScreen.windows["PBDialogWindow"].firstMatch
    #else
        let alert = XCUIApplication.homeScreen.alerts.firstMatch
    #endif
        if alert.waitForExistence(timeout: timeout) {
            XCTAssertTrue(anyElementContains(text: "Would Like to Send You Notifications", scope: alert).exists)
        #if os(tvOS)
            alert.buttons["Allow"].firstMatch.select(direction: .horizontal)
        #elseif os(watchOS)
            alert.swipeUp()
            alert.buttons["Allow"].tap()
        #else
            alert.buttons["Allow"].tap()
        #endif
        }
    }
    
    private func firstAlertElement() -> XCUIElement {
    #if os(watchOS)
        // `SwiftUI.View.alert(isPresented:)` views re matched as tables in watchOS 🤷‍♂️
        return app.tables.firstMatch
    #else
        return app.alerts.firstMatch
    #endif
    }
    
    private func notificationElement() -> XCUIElement {
    #if os(watchOS)
        return XCUIApplication.homeScreen.otherElements["PushNotificationsWatchApp"]
    #else
        return XCUIApplication.homeScreen.otherElements.descendants(matching: .any)["NotificationShortLookView"]
    #endif
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

    private func bootDevice() async throws {
        let request = LocalServer.boot(deviceIdentifier!).urlRequest
        let (_, response) = try await URLSession.shared.data(for: request)
        XCTAssertTrue((response as! HTTPURLResponse).statusCode < 300, "Failed to boot the device")
    }

    private func pressHomeButton() {
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        let springboard = XCUIApplication.homeScreen
    #if !os(watchOS)
        springboard.activate()
    #endif

        if !springboard.wait(for: .runningForeground, timeout: timeout) {
            XCTFail("Failed to get back to home screen")
        }
    #if !os(watchOS)
        if !app.wait(for: .runningBackground, timeout: timeout) {
            XCTFail("Failed to put app to the background")
            return
        }
    #endif
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

#if os(tvOS)
extension XCUIElement {
    func select(direction: Direction) {
        XCUIRemote.shared.select(self, direction: direction)
    }
}

enum Direction {
    case horizontal
    case vertical

    func next() -> XCUIRemote.Button {
        switch self {
        case .horizontal:
            return .right
        case .vertical:
            return .down
        }
    }

    func previous() -> XCUIRemote.Button {
        switch self {
        case .horizontal:
            return .left
        case .vertical:
            return .up
        }
    }
}

extension XCUIRemote {
    func select(_ element: XCUIElement, direction: Direction) {
        let app = XCUIApplication()
        var isEndReached = false
        while !element.hasFocus {
            let previousElement = app.focusedElement
            press(isEndReached ? direction.previous() : direction.next())
            if previousElement == app.focusedElement {
                if isEndReached {
                    XCTFail("Element \(element) was not found.")
                    return
                }
                isEndReached = true
            }
        }
        
        print("Element \(element) was found and has been focused, pressing SELECT")
        press(.select)
    }
}
#endif

extension XCUIApplication {
    static var homeScreen: XCUIApplication {
    #if os(iOS)
        XCUIApplication(bundleIdentifier: "com.apple.springboard")
    #elseif os(tvOS)
        XCUIApplication(bundleIdentifier: "com.apple.PineBoard")
    #else
        XCUIApplication(bundleIdentifier: "com.apple.Carousel")
    #endif
    }
    
    var focusedElement: XCUIElement {
        descendants(matching: .any).element(matching: NSPredicate(format: "hasFocus == true"))
    }
}
