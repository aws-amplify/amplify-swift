//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPinpointAnalyticsPlugin
import XCTest
import AWSPinpoint

class EndpointClientTests: XCTestCase {
    private var endpointClient: EndpointClient!
    private var archiver: MockArchiver!
    private var userDefaults: MockUserDefaults!
    private var pinpointClient: MockPinpointClient!
    private var device: MockDevice!
    private var currentApplicationId = "applicationId"
    private var currentEndpointId = "endpointId"
    private var keychain: MockKeychainStore!
    override func setUp() {
        archiver = MockArchiver()
        userDefaults = MockUserDefaults()
        pinpointClient = MockPinpointClient()
        device = MockDevice()
        keychain = MockKeychainStore()
        endpointClient = EndpointClient(configuration: .init(appId: currentApplicationId,
                                                             uniqueDeviceId: currentEndpointId,
                                                             isDebug: false,
                                                             isOptOut: false),
                                        pinpointClient: pinpointClient,
                                        archiver: archiver,
                                        currentDevice: device,
                                        userDefaults: userDefaults,
                                        keychain: keychain)
    }

    override func tearDown() {
        archiver = nil
        userDefaults = nil
        pinpointClient = nil
        device = nil
        endpointClient = nil
        keychain = nil
    }

    func testCurrentEndpointProfile_withValidStoredProfile_shouldReturnUpdatedStored() async {
        let oldEffectiveDate = Date().addingTimeInterval(-1000)
        let oldDemographic = PinpointClientTypes.EndpointDemographic(appVersion: "oldVersion")
        let storedEndpointProfile = PinpointEndpointProfile(applicationId: currentApplicationId,
                                                            endpointId: "oldEndpoint",
                                                            deviceToken: "oldToken",
                                                            effectiveDate: oldEffectiveDate,
                                                            demographic: oldDemographic)
        let newToken = "newToken".data(using: .utf8)
        do {
            try keychain.set(Data(), key: EndpointClient.Constants.endpointProfileKey)
            try keychain.set(newToken!, key: EndpointClient.Constants.deviceTokenKey)
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
        XCTAssertNotEqual(endpointProfile.effectiveDate, oldEffectiveDate)
        XCTAssertNotEqual(endpointProfile.demographic, oldDemographic)
        XCTAssertEqual(endpointProfile.demographic.appVersion, device.appVersion)
        XCTAssertEqual(endpointProfile.demographic.make, "apple")
        XCTAssertEqual(endpointProfile.demographic.platform, device.platform.name)
        XCTAssertEqual(endpointProfile.demographic.platformVersion, device.platform.version)
    }

    func testCurrentEndpointProfile_withInvalidStoredProfile_shouldRemoveStored_andReturnNew() async {
        let oldEffectiveDate = Date().addingTimeInterval(-1000)
        let oldDemographic = PinpointClientTypes.EndpointDemographic(appVersion: "oldVersion")
        let storedEndpointProfile = PinpointEndpointProfile(applicationId: "oldApplicationId",
                                                            endpointId: "oldEndpoint",
                                                            deviceToken: "oldToken",
                                                            effectiveDate: oldEffectiveDate,
                                                            demographic: oldDemographic)
        keychain.resetCounters()
        let newToken = "newToken".data(using: .utf8)
        do {
            try keychain.set(newToken!, key: EndpointClient.Constants.deviceTokenKey)
        } catch {
            XCTFail("Fail to setup test data")
        }
        archiver.decoded = storedEndpointProfile
        

        let endpointProfile = await endpointClient.currentEndpointProfile()

        XCTAssertEqual(keychain.dataForKeyCount, 2)
        XCTAssertEqual(keychain.dataForKeyCountMap[EndpointClient.Constants.endpointProfileKey], 1)
        XCTAssertEqual(keychain.dataForKeyCountMap[EndpointClient.Constants.deviceTokenKey], 2)
        XCTAssertEqual(archiver.decodeCount, 0)
        XCTAssertFalse(endpointProfile === storedEndpointProfile, "Expected new PinpointEndpointProfile object")
        XCTAssertEqual(endpointProfile.applicationId, currentApplicationId)
        XCTAssertEqual(endpointProfile.endpointId, currentEndpointId)
        XCTAssertEqual(endpointProfile.deviceToken, newToken?.asHexString())
        XCTAssertNotEqual(endpointProfile.effectiveDate, oldEffectiveDate)
        XCTAssertNotEqual(endpointProfile.demographic, oldDemographic)
        XCTAssertEqual(endpointProfile.demographic.appVersion, device.appVersion)
        XCTAssertEqual(endpointProfile.demographic.make, "apple")
        XCTAssertEqual(endpointProfile.demographic.platform, device.platform.name)
        XCTAssertEqual(endpointProfile.demographic.platformVersion, device.platform.version)
    }

    func testCurrentEndpointProfile_shouldUpdateAttributesAndMetrics() async {
        let storedEndpointProfile = PinpointEndpointProfile(applicationId: "oldApplicationId",
                                                            endpointId: "oldEndpoint")
        storedEndpointProfile.addAttribute("value", forKey: "oldAttribute")
        storedEndpointProfile.addMetric(0, forKey: "oldMetric")
        archiver.decoded = storedEndpointProfile

        await endpointClient.addAttributes(["newValue"], forKey: "newAttribute")
        await endpointClient.addAttributes(["newerValue"], forKey: "newerAttribute")
        await endpointClient.addMetric(1, forKey: "newMetric")
        await endpointClient.addMetric(2, forKey: "newerMetric")
        let endpointProfile = await endpointClient.currentEndpointProfile()

        XCTAssertEqual(endpointProfile.attributes.count, 2)
        XCTAssertEqual(endpointProfile.metrics.count, 2)
        XCTAssertNil(endpointProfile.attributes["oldAttribute"])
        XCTAssertNil(endpointProfile.metrics["oldMetric"])
    }

    func testUpdateEndpointProfile_shouldSendUpdateRequestAndSave() async {
        keychain.resetCounters()
        try? await endpointClient.updateEndpointProfile()

        XCTAssertEqual(pinpointClient.updateEndpointCount, 1)
        XCTAssertEqual(archiver.encodeCount, 1)
        XCTAssertEqual(keychain.saveDataCount, 1)
    }

    func testUpdateEndpointProfile_withProfile_shouldUpdateandSendUpdateRequestAndSave() async {
        keychain.resetCounters()
        await endpointClient.addAttributes(["value"], forKey: "attribute")
        await endpointClient.addMetric(1, forKey: "metric")

        let pinpointProfile = PinpointEndpointProfile(applicationId: currentApplicationId,
                                                      endpointId: currentEndpointId)

        XCTAssertTrue(pinpointProfile.attributes.isEmpty)
        XCTAssertTrue(pinpointProfile.metrics.isEmpty)
        XCTAssertEqual(keychain.saveDataCount, 2)
        XCTAssertEqual(archiver.encodeCount, 2)
        keychain.resetCounters()
        archiver.resetCounters()

        try? await endpointClient.updateEndpointProfile(with: pinpointProfile)
        XCTAssertEqual(pinpointProfile.attributes.count, 1)
        XCTAssertEqual(pinpointProfile.metrics.count, 1)
        XCTAssertEqual(pinpointClient.updateEndpointCount, 1)
        XCTAssertEqual(archiver.encodeCount, 1)
        XCTAssertEqual(keychain.saveDataCount, 1)
    }

    func testConvertToPublicEndpoint_shouldReturnPublicEndpoint() async {
        let endpointProfile = await endpointClient.currentEndpointProfile()
        let publicEndpoint = endpointClient.convertToPublicEndpoint(endpointProfile)
        let mockModel = MockDevice()
        XCTAssertNotNil(publicEndpoint)
        XCTAssertNil(publicEndpoint.address)
        XCTAssertEqual(publicEndpoint.attributes?.count, 0)
        XCTAssertEqual(publicEndpoint.metrics?.count, 0)
        XCTAssertEqual(publicEndpoint.channelType, .apns)
        XCTAssertEqual(publicEndpoint.optOut, "ALL")
        XCTAssertEqual(publicEndpoint.demographic?.appVersion, mockModel.appVersion)
        XCTAssertEqual(publicEndpoint.demographic?.make, "apple")
        XCTAssertEqual(publicEndpoint.demographic?.model, mockModel.model)
        XCTAssertEqual(publicEndpoint.demographic?.platform, mockModel.platform.name)
        XCTAssertEqual(publicEndpoint.demographic?.platformVersion, mockModel.platform.version)
    }
}

class MockDevice: Device {
    var model: String = "mockModel"
    var appVersion: String? = "mockAppVersion"
    var platform: Platform = (name: "mockPlatformName", version: "mockPlatformVersion")
}
