//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AmplifyTestCommon
import XCTest

final class NotificationsCategoryTests: XCTestCase {
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
            push: PushNotificationsCategoryConfiguration(
                plugins: [notificationsPlugin.key: true]
            )
        )
        try Amplify.add(plugin: notificationsPlugin)
        try Amplify.configure(AmplifyConfiguration(notifications:notificationsConfig))

        let configuredCategories = category.subcategories
        XCTAssertEqual(configuredCategories.count, 1)
        XCTAssertTrue(configuredCategories.first is PushNotificationsCategory)
    }
}
