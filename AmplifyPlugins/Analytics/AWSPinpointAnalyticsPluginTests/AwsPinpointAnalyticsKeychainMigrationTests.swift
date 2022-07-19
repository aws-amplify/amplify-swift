//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
import AWSPinpoint
@testable import Amplify
@testable import AWSPinpointAnalyticsPlugin

class AWSPinpointAnalyticsKeyValueStoreTests: XCTestCase {
    private let keychain = MockKeychainStore()
    private let archiver = AmplifyArchiver()
    private let userDefaults = UserDefaults.standard
    private let pinpointClient = MockPinpointClient()
    private let device = MockDevice()
    private let currentApplicationId = "applicationId"
    private let currentEndpointId = "endpointId"
    
    override func setUp() {
        userDefaults.removeObject(forKey: EndpointClient.Constants.deviceTokenKey)
        userDefaults.removeObject(forKey: EndpointClient.Constants.endpointProfileKey)
        userDefaults.removeObject(forKey: EndpointClient.Constants.attributesKey)
        userDefaults.removeObject(forKey: EndpointClient.Constants.metricsKey)
        keychain.resetCounters()
        do {
            try keychain.removeAll()
        } catch {
            XCTFail("Failed to setup AWSPinpointAnalyticsKeyValueStoreTests")
        }
    }
    
    func testDeviceTokenMigrateFromUserDefaultsToKeychain() {
        let deviceToken = "000102030405060708090a0b0c0d0e0f"
        let deviceTokenData = deviceToken.data(using: .utf8)
        userDefaults.setValue(deviceTokenData, forKey: EndpointClient.Constants.deviceTokenKey)
        
        var currentKeychainDeviceToken = try? self.keychain.getData(EndpointClient.Constants.deviceTokenKey)
        XCTAssertNil(currentKeychainDeviceToken)
        XCTAssertNotNil(userDefaults.data(forKey:EndpointClient.Constants.deviceTokenKey))
        
        _ = EndpointClient(configuration: .init(appId: currentApplicationId,
                                                             uniqueDeviceId: currentEndpointId,
                                                             isDebug: false,
                                                             isOptOut: false),
                                        pinpointClient: pinpointClient,
                                        archiver: archiver,
                                        currentDevice: device,
                                        userDefaults: userDefaults,
                                        keychain: keychain)
        
        currentKeychainDeviceToken = try? self.keychain.getData(EndpointClient.Constants.deviceTokenKey)
        XCTAssertNil(userDefaults.data(forKey:EndpointClient.Constants.deviceTokenKey))
        XCTAssertNotNil(currentKeychainDeviceToken)
    }
    
    func testEndpointProfileMigrateFromUserDefaultsToKeychain() {
        let profile = PinpointEndpointProfile(applicationId: "appId", endpointId: "endpointId")
        let profileData = try? archiver.encode(profile)
        userDefaults.setValue(profileData, forKey: EndpointClient.Constants.endpointProfileKey)
        
        var currentKeychainProfile = try? self.keychain.getData(EndpointClient.Constants.endpointProfileKey)
        XCTAssertNil(currentKeychainProfile)
        XCTAssertNotNil(userDefaults.data(forKey:EndpointClient.Constants.endpointProfileKey))
        
        _ = EndpointClient(configuration: .init(appId: currentApplicationId,
                                                             uniqueDeviceId: currentEndpointId,
                                                             isDebug: false,
                                                             isOptOut: false),
                                        pinpointClient: pinpointClient,
                                        archiver: archiver,
                                        currentDevice: device,
                                        userDefaults: userDefaults,
                                        keychain: keychain)
        
        currentKeychainProfile = try? self.keychain.getData(EndpointClient.Constants.endpointProfileKey)
        XCTAssertNil(userDefaults.data(forKey:EndpointClient.Constants.endpointProfileKey))
        XCTAssertNotNil(currentKeychainProfile)
    }
    
    func testAttributesMigrateFromUserDefaultsToKeychain() {
        let attributes: [String: [String]] = ["Attributes1": ["Value1"]]
        userDefaults.setValue(attributes, forKey: EndpointClient.Constants.attributesKey)
        
        var currentAttributes = try? self.keychain.getData(EndpointClient.Constants.attributesKey)
        XCTAssertNil(currentAttributes)
        XCTAssertNotNil(userDefaults.object(forKey:EndpointClient.Constants.attributesKey))
        
        _ = EndpointClient(configuration: .init(appId: currentApplicationId,
                                                             uniqueDeviceId: currentEndpointId,
                                                             isDebug: false,
                                                             isOptOut: false),
                                        pinpointClient: pinpointClient,
                                        archiver: archiver,
                                        currentDevice: device,
                                        userDefaults: userDefaults,
                                        keychain: keychain)
        
        currentAttributes = try? self.keychain.getData(EndpointClient.Constants.attributesKey)
        XCTAssertNil(userDefaults.object(forKey:EndpointClient.Constants.attributesKey))
        XCTAssertNotNil(currentAttributes)
    }

    func testMetricsMigrateFromUserDefaultsToKeychain() {
        let metrics = ["Attributes1": 123]
        userDefaults.setValue(metrics, forKey: EndpointClient.Constants.metricsKey)
        
        var currentMetrics = try? self.keychain.getData(EndpointClient.Constants.metricsKey)
        XCTAssertNil(currentMetrics)
        XCTAssertNotNil(userDefaults.object(forKey:EndpointClient.Constants.metricsKey))
        
        _ = EndpointClient(configuration: .init(appId: currentApplicationId,
                                                             uniqueDeviceId: currentEndpointId,
                                                             isDebug: false,
                                                             isOptOut: false),
                                        pinpointClient: pinpointClient,
                                        archiver: archiver,
                                        currentDevice: device,
                                        userDefaults: userDefaults,
                                        keychain: keychain)
        
        currentMetrics = try? self.keychain.getData(EndpointClient.Constants.metricsKey)
        XCTAssertNil(userDefaults.object(forKey:EndpointClient.Constants.metricsKey))
        XCTAssertNotNil(currentMetrics)
    }
}

