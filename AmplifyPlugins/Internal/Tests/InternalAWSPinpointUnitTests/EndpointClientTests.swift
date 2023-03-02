//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
import XCTest
import AWSPinpoint
import UserNotifications

class EndpointClientTests: XCTestCase {
    private let newTokenHex = "646576696365546f6b656e"

    private var endpointClient: EndpointClient!
    private var archiver: MockArchiver!
    private var userDefaults: MockUserDefaults!
    private var pinpointClient: MockPinpointClient!
    private var endpointInformation: MockEndpointInformation!
    private var remoteNotificationsHelper: MockRemoteNotifications!
    private var currentApplicationId = "applicationId"
    private var currentEndpointId = "endpointId"
    private var keychain: MockKeychainStore!
    override func setUp() {
        archiver = MockArchiver()
        userDefaults = MockUserDefaults()
        pinpointClient = MockPinpointClient()
        endpointInformation = MockEndpointInformation()
        keychain = MockKeychainStore()
        remoteNotificationsHelper = MockRemoteNotifications()
        endpointClient = EndpointClient(configuration: .init(appId: currentApplicationId,
                                                             uniqueDeviceId: currentEndpointId,
                                                             isDebug: false),
                                        pinpointClient: pinpointClient,
                                        archiver: archiver,
                                        endpointInformation: endpointInformation,
                                        userDefaults: userDefaults,
                                        keychain: keychain,
                                        remoteNotificationsHelper: remoteNotificationsHelper)
    }

    override func tearDown() {
        archiver = nil
        userDefaults = nil
        pinpointClient = nil
        endpointInformation = nil
        endpointClient = nil
        keychain = nil
        remoteNotificationsHelper = nil
    }

    func testCurrentEndpointProfile_withValidStoredProfile_shouldReturnUpdatedStored() async {
        let oldDemographic = PinpointClientTypes.EndpointDemographic(appVersion: "oldVersion")
        let storedEndpointProfile = PinpointEndpointProfile(applicationId: currentApplicationId,
                                                            endpointId: "oldEndpoint",
                                                            deviceToken: "oldToken",
                                                            demographic: oldDemographic)
        let newToken = "newToken".data(using: .utf8)
        do {
            try keychain._set(Data(), key: EndpointClient.Constants.endpointProfileKey)
            try keychain._set(newToken!, key: EndpointClient.Constants.deviceTokenKey)
        } catch {
            XCTFail("Fail to setup test data")
        }

        archiver.decoded = storedEndpointProfile

        let endpointProfile = await endpointClient.currentEndpointProfile()

        XCTAssertEqual(userDefaults.dataForKeyCount, 2)
        XCTAssertEqual(userDefaults.dataForKeyCountMap[EndpointClient.Constants.endpointProfileKey], 1)
        XCTAssertEqual(userDefaults.dataForKeyCountMap[EndpointClient.Constants.deviceTokenKey], 1)
        XCTAssertEqual(keychain.dataValues.count, 2)
        XCTAssertNotNil(keychain.dataValues[EndpointClient.Constants.endpointProfileKey])
        XCTAssertNotNil(keychain.dataValues[EndpointClient.Constants.deviceTokenKey])
        XCTAssertEqual(archiver.decodeCount, 1)
        XCTAssertTrue(endpointProfile === storedEndpointProfile, "Expected stored PinpointEndpointProfile object")
        XCTAssertEqual(endpointProfile.applicationId, currentApplicationId)
        XCTAssertEqual(endpointProfile.endpointId, currentEndpointId)
        XCTAssertEqual(endpointProfile.deviceToken, newToken?.asHexString())
        XCTAssertNotEqual(endpointProfile.demographic, oldDemographic)
        XCTAssertEqual(endpointProfile.demographic.appVersion, endpointInformation.appVersion)
        XCTAssertEqual(endpointProfile.demographic.make, "apple")
        XCTAssertEqual(endpointProfile.demographic.platform, endpointInformation.platform.name)
        XCTAssertEqual(endpointProfile.demographic.platformVersion, endpointInformation.platform.version)
    }

    func testCurrentEndpointProfile_withInvalidStoredProfile_shouldRemoveStored_andReturnNew() async {
        let oldEffectiveDate = Date().addingTimeInterval(-1000)
        let oldDemographic = PinpointClientTypes.EndpointDemographic(appVersion: "oldVersion")
        let storedEndpointProfile = PinpointEndpointProfile(applicationId: "oldApplicationId",
                                                            endpointId: "oldEndpoint",
                                                            deviceToken: "oldToken",
                                                            effectiveDate: oldEffectiveDate,
                                                            demographic: oldDemographic)
        let newToken = storeToken("newToken")
        keychain.resetCounters()
        archiver.decoded = storedEndpointProfile

        let endpointProfile = await endpointClient.currentEndpointProfile()

        XCTAssertEqual(keychain.dataForKeyCount, 2)
        XCTAssertEqual(keychain.dataForKeyCountMap[EndpointClient.Constants.endpointProfileKey], 1)
        XCTAssertEqual(keychain.dataForKeyCountMap[EndpointClient.Constants.deviceTokenKey], 1)
        XCTAssertEqual(archiver.decodeCount, 0)
        XCTAssertFalse(endpointProfile === storedEndpointProfile, "Expected new PinpointEndpointProfile object")
        XCTAssertEqual(endpointProfile.applicationId, currentApplicationId)
        XCTAssertEqual(endpointProfile.endpointId, currentEndpointId)
        XCTAssertEqual(endpointProfile.deviceToken, newToken?.asHexString())
        XCTAssertNotEqual(endpointProfile.effectiveDate, oldEffectiveDate)
        XCTAssertNotEqual(endpointProfile.demographic, oldDemographic)
        XCTAssertEqual(endpointProfile.demographic.appVersion, endpointInformation.appVersion)
        XCTAssertEqual(endpointProfile.demographic.make, "apple")
        XCTAssertEqual(endpointProfile.demographic.platform, endpointInformation.platform.name)
        XCTAssertEqual(endpointProfile.demographic.platformVersion, endpointInformation.platform.version)
    }

    func testUpdateEndpointProfile_shouldSendUpdateRequestAndSave() async {
        keychain.resetCounters()
        try? await endpointClient.updateEndpointProfile()

        XCTAssertEqual(pinpointClient.updateEndpointCount, 1)
        XCTAssertEqual(archiver.encodeCount, 1)
        XCTAssertEqual(keychain.saveDataCount, 1)
    }

    func testUpdateEndpointProfile_withAPNsToken_withoutStoredToken_shouldSaveToken() async {
        keychain.resetCounters()

        let endpoint = PinpointEndpointProfile(applicationId: "applicationId",
                                               endpointId: "endpointId")
        endpoint.setAPNsToken(Data(hexString: newTokenHex)!)
        try? await endpointClient.updateEndpointProfile(with: endpoint)

        XCTAssertEqual(keychain.removeObjectCount, 0)
        XCTAssertEqual(keychain.dataForKeyCountMap[EndpointClient.Constants.deviceTokenKey, default: 0], 1)
        XCTAssertEqual(keychain.saveDataCountMap[EndpointClient.Constants.deviceTokenKey, default: 0], 1)
    }

    func testUpdateEndpointProfile_withAPNsToken_withOldStoredToken_shouldSaveToken() async {
        storeToken("oldToken")
        keychain.resetCounters()

        let endpoint = PinpointEndpointProfile(applicationId: "applicationId",
                                               endpointId: "endpointId")
        endpoint.setAPNsToken(Data(hexString: newTokenHex)!)
        try? await endpointClient.updateEndpointProfile(with: endpoint)

        XCTAssertEqual(keychain.removeObjectCount, 0)
        XCTAssertEqual(keychain.dataForKeyCountMap[EndpointClient.Constants.deviceTokenKey, default: 0], 1)
        XCTAssertEqual(keychain.saveDataCountMap[EndpointClient.Constants.deviceTokenKey, default: 0], 1)
    }

    func testUpdateEndpointProfile_withAPNsToken_withSameStoredToken_shouldNotSaveToken() async {
        storeToken(newTokenHex)
        keychain.resetCounters()

        let endpoint = PinpointEndpointProfile(applicationId: "applicationId",
                                               endpointId: "endpointId")
        endpoint.setAPNsToken(Data(hexString: newTokenHex)!)
        try? await endpointClient.updateEndpointProfile(with: endpoint)

        XCTAssertEqual(keychain.removeObjectCount, 0)
        XCTAssertEqual(keychain.dataForKeyCountMap[EndpointClient.Constants.deviceTokenKey, default: 0], 1)
        XCTAssertEqual(keychain.saveDataCountMap[EndpointClient.Constants.deviceTokenKey, default: 0], 0)
    }

    func testUpdateEndpointProfile_withoutAPNsToken_withStoredToken_shouldRemoveToken() async {
        storeToken("oldToken")
        keychain.resetCounters()

        let endpoint = PinpointEndpointProfile(applicationId: "applicationId",
                                               endpointId: "endpointId")
        try? await endpointClient.updateEndpointProfile(with: endpoint)

        XCTAssertEqual(keychain.removeObjectCount, 1)
        XCTAssertEqual(keychain.dataForKeyCountMap[EndpointClient.Constants.deviceTokenKey, default: 0], 0)
        XCTAssertEqual(keychain.saveDataCountMap[EndpointClient.Constants.deviceTokenKey, default: 0], 0)
    }

    func testConvertToPublicEndpoint_shouldReturnPublicEndpoint() async {
        let endpointProfile = await endpointClient.currentEndpointProfile()
        let publicEndpoint = endpointClient.convertToPublicEndpoint(endpointProfile)
        let mockModel = MockEndpointInformation()
        XCTAssertNotNil(publicEndpoint)
        XCTAssertNil(publicEndpoint.address)
        XCTAssertEqual(publicEndpoint.attributes?.count, 0)
        XCTAssertEqual(publicEndpoint.metrics?.count, 0)
        XCTAssertNil(publicEndpoint.channelType)
        XCTAssertEqual(publicEndpoint.optOut, "NONE")
        XCTAssertEqual(publicEndpoint.demographic?.appVersion, mockModel.appVersion)
        XCTAssertEqual(publicEndpoint.demographic?.make, "apple")
        XCTAssertEqual(publicEndpoint.demographic?.model, mockModel.model)
        XCTAssertEqual(publicEndpoint.demographic?.platform, mockModel.platform.name)
        XCTAssertEqual(publicEndpoint.demographic?.platformVersion, mockModel.platform.version)
    }

    @discardableResult
    private func storeToken(_ deviceToken: String) -> Data? {
        let newToken = Data(hexString: deviceToken) ?? deviceToken.data(using: .utf8)
        do {
            try keychain._set(newToken!, key: EndpointClient.Constants.deviceTokenKey)
        } catch {
            XCTFail("Fail to setup test data")
        }
        return newToken
    }
}

class MockEndpointInformation: EndpointInformation {
    var model: String = "mockModel"
    var appVersion: String = "mockAppVersion"
    var platform: Platform = (name: "mockPlatformName", version: "mockPlatformVersion")
}

class MockRemoteNotifications: RemoteNotificationsBehaviour {
    var isRegisteredForRemoteNotifications = true

    func requestAuthorization(_ options: UNAuthorizationOptions) async throws -> Bool {
        return true
    }

    func registerForRemoteNotifications() async {}
}
