//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
final class NotificationsCategoryTests: XCTestCase, @unchecked Sendable {
    private var category: NotificationsCategory!

    override func setUp() async throws {
        await Amplify.reset()
        category = Amplify.Notifications
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }

    func testSubcategories_withNoSubcategoryConfigured_shouldReturnEmpty() {
        let configuredCategories = category.subcategories
        XCTAssertTrue(configuredCategories.isEmpty)
    }

    func testSubcategories_withPushConfigured_shouldReturnPush() throws {
        let notificationsPlugin = MockPushNotificationsCategoryPlugin()
        let notificationsConfig = NotificationsCategoryConfiguration(
            plugins: [notificationsPlugin.key: true]
        )
        try Amplify.add(plugin: notificationsPlugin)
        try Amplify.configure(AmplifyConfiguration(notifications: notificationsConfig))

        let configuredCategories = category.subcategories
        XCTAssertEqual(configuredCategories.count, 1)
        XCTAssertTrue(configuredCategories.first is PushNotificationsCategory)
    }
}
