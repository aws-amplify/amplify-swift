//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyUtilsNotifications
import AWSPinpoint
@_spi(KeychainStore) import AWSPluginsCore
import Foundation

@_spi(InternalAWSPinpoint)
public protocol EndpointClientBehaviour: Actor {
    nonisolated var pinpointClient: PinpointClientProtocol { get }

    func currentEndpointProfile() async -> PinpointEndpointProfile
    func updateEndpointProfile() async throws
    func updateEndpointProfile(with endpointProfile: PinpointEndpointProfile) async throws
    nonisolated func convertToPublicEndpoint(_ endpointProfile: PinpointEndpointProfile) -> PinpointClientTypes.PublicEndpoint
}

actor EndpointClient: EndpointClientBehaviour {
    struct Configuration {
        let appId: String
        let uniqueDeviceId: String
        let isDebug: Bool
    }

    let pinpointClient: PinpointClientProtocol

    private let configuration: EndpointClient.Configuration
    private let archiver: AmplifyArchiverBehaviour
    private let endpointInformation: EndpointInformation
    private let userDefaults: UserDefaultsBehaviour
    private let keychain: KeychainStoreBehavior
    private let remoteNotificationsHelper: RemoteNotificationsBehaviour

    private var endpointProfile: PinpointEndpointProfile?
    private static let defaultDateFormatter = ISO8601DateFormatter()

    init(configuration: EndpointClient.Configuration,
         pinpointClient: PinpointClientProtocol,
         archiver: AmplifyArchiverBehaviour = AmplifyArchiver(),
         endpointInformation: EndpointInformation = .current,
         userDefaults: UserDefaultsBehaviour = UserDefaults.standard,
         keychain: KeychainStoreBehavior = KeychainStore(service: PinpointContext.Constants.Keychain.service),
         remoteNotificationsHelper: RemoteNotificationsBehaviour = .default
    ) {
        self.configuration = configuration
        self.pinpointClient = pinpointClient
        self.archiver = archiver
        self.endpointInformation = endpointInformation
        self.userDefaults = userDefaults
        self.keychain = keychain
        self.remoteNotificationsHelper = remoteNotificationsHelper

        Self.migrateStoredValues(from: userDefaults, to: keychain, using: archiver)
    }

    func currentEndpointProfile() async -> PinpointEndpointProfile {
        let endpointProfile = await retrieveOrCreateEndpointProfile()
        self.endpointProfile = endpointProfile
        return endpointProfile
    }

    func updateEndpointProfile() async throws {
        try await updateEndpoint(with: currentEndpointProfile())
    }

    func updateEndpointProfile(with endpointProfile: PinpointEndpointProfile) async throws {
        try updateStoredAPNsToken(from: endpointProfile)
        try await updateEndpoint(with: endpointProfile)
    }

    private func retrieveOrCreateEndpointProfile() async -> PinpointEndpointProfile {
        // 1. Look for the local endpointProfile variable
        if let endpointProfile = endpointProfile {
            // Update endpoint's optOut flag, as the user might have disabled notifications since the last time
            endpointProfile.isOptOut = await isNotEligibleForPinpointNotifications(endpointProfile)
            return endpointProfile
        }

        // 2. Look for a valid PinpointEndpointProfile object stored locally. It needs to match the current applicationId, otherwise we'll discard it.
        if let endpointProfileData = Self.getStoredData(from: keychain, forKey: Constants.endpointProfileKey, fallbackTo: userDefaults),
           let decodedEndpointProfile = try? archiver.decode(PinpointEndpointProfile.self, from: endpointProfileData),
           decodedEndpointProfile.applicationId == configuration.appId {
            return await configure(endpointProfile: decodedEndpointProfile)
        }

        try? keychain._remove(Constants.endpointProfileKey)
        // Create a new PinpointEndpointProfile
        return await configure(endpointProfile: PinpointEndpointProfile(applicationId: configuration.appId,
                                                                        endpointId: configuration.uniqueDeviceId))
    }

    private func configure(endpointProfile: PinpointEndpointProfile) async -> PinpointEndpointProfile {
        var deviceToken: PinpointEndpointProfile.DeviceToken?
        if let tokenData = Self.getStoredData(from: keychain, forKey: Constants.deviceTokenKey, fallbackTo: userDefaults) {
            deviceToken = tokenData.asHexString()
        }

        endpointProfile.endpointId = configuration.uniqueDeviceId
        endpointProfile.deviceToken = deviceToken
        endpointProfile.location = .init()
        endpointProfile.demographic = .init(device: endpointInformation)
        endpointProfile.isOptOut = await isNotEligibleForPinpointNotifications(endpointProfile)
        endpointProfile.isDebug = configuration.isDebug

        return endpointProfile
    }

    private func updateEndpoint(with endpointProfile: PinpointEndpointProfile) async throws {
        endpointProfile.effectiveDate = Date()
        let input = createUpdateInput(from: endpointProfile)
        log.verbose("UpdateEndpointInput: \(input)")
        do {
            let output = try await pinpointClient.updateEndpoint(input: input)
            if let encodedData = try? archiver.encode(endpointProfile) {
                try? keychain._set(encodedData, key: Constants.endpointProfileKey)
            }
            self.endpointProfile = endpointProfile
            log.verbose("Endpoint Updated Successfully! \(output)")
        } catch {
            log.error("Unable to successfully update endpoint. Error Message: \(error.localizedDescription)")
            log.error(error: error)
            throw error
        }
    }

    private func updateStoredAPNsToken(from endpointProfile: PinpointEndpointProfile) throws {
        guard let deviceToken = endpointProfile.deviceToken,
              let apnsToken = Data(hexString: deviceToken) else {
            try keychain._remove(Constants.deviceTokenKey)
            return
        }

        let currentToken = try keychain._getData(Constants.deviceTokenKey)
        if currentToken != apnsToken {
            try keychain._set(apnsToken, key: Constants.deviceTokenKey)
        }
    }

    private func isNotEligibleForPinpointNotifications(_ endpointProfile: PinpointEndpointProfile) async -> Bool {
        guard endpointProfile.deviceToken.isNotEmpty else {
            return true
        }

        return !(await remoteNotificationsHelper.isRegisteredForRemoteNotifications)
    }

    private func createUpdateInput(from endpointProfile: PinpointEndpointProfile) -> UpdateEndpointInput {
        let channelType = getChannelType(from: endpointProfile)
        let effectiveDate = getEffectiveDateIso8601FractionalSeconds(from: endpointProfile)
        let optOut = getOptOut(from: endpointProfile)
        let endpointRequest =  PinpointClientTypes.EndpointRequest(address: endpointProfile.deviceToken,
                                                                   attributes: endpointProfile.attributes,
                                                                   channelType: channelType,
                                                                   demographic: endpointProfile.demographic,
                                                                   effectiveDate: effectiveDate,
                                                                   location: endpointProfile.location,
                                                                   metrics: endpointProfile.metrics,
                                                                   optOut: optOut,
                                                                   user: endpointProfile.user)
        return UpdateEndpointInput(applicationId: endpointProfile.applicationId,
                                   endpointId: endpointProfile.endpointId,
                                   endpointRequest: endpointRequest)
    }

    nonisolated func convertToPublicEndpoint(_ endpointProfile: PinpointEndpointProfile) -> PinpointClientTypes.PublicEndpoint {
        let channelType = getChannelType(from: endpointProfile)
        let effectiveDate = getEffectiveDateIso8601FractionalSeconds(from: endpointProfile)
        let optOut = getOptOut(from: endpointProfile)
        let publicEndpoint = PinpointClientTypes.PublicEndpoint(
            address: endpointProfile.deviceToken,
            attributes: endpointProfile.attributes,
            channelType: channelType,
            demographic: endpointProfile.demographic,
            effectiveDate: effectiveDate,
            location: endpointProfile.location,
            metrics: endpointProfile.metrics,
            optOut: optOut,
            user: endpointProfile.user)
        return publicEndpoint
    }

    nonisolated private func getChannelType(from endpointProfile: PinpointEndpointProfile) -> PinpointClientTypes.ChannelType {
        return endpointProfile.isDebug ? .apnsSandbox : .apns
    }

    nonisolated private func getEffectiveDateIso8601FractionalSeconds(from endpointProfile: PinpointEndpointProfile) -> String {
        endpointProfile.effectiveDate.asISO8601String
    }

    nonisolated private func getOptOut(from endpointProfile: PinpointEndpointProfile) -> String {
        return endpointProfile.isOptOut ? EndpointClient.Constants.OptOut.all : EndpointClient.Constants.OptOut.none
    }

    private static func migrateStoredValues(from userDefaults: UserDefaultsBehaviour, to keychain: KeychainStoreBehavior, using archiver: AmplifyArchiverBehaviour) {
        if let endpointProfileData = userDefaults.data(forKey: Constants.endpointProfileKey) {
            do {
                try keychain._set(endpointProfileData, key: Constants.endpointProfileKey)
                userDefaults.removeObject(forKey: Constants.endpointProfileKey)
            } catch {
                log.error("Unable to migrate Analytics key-value store for key \(Constants.endpointProfileKey)")
            }
        }
        
        let keychainTokenData = try? keychain._getData(Constants.deviceTokenKey)
        if let tokenData = userDefaults.data(forKey: Constants.deviceTokenKey), keychainTokenData == nil {
            do {
                try keychain._set(tokenData, key: Constants.deviceTokenKey)
                userDefaults.removeObject(forKey: Constants.deviceTokenKey)
            } catch {
                log.error("Unable to migrate Analytics key-value store for key \(Constants.deviceTokenKey)")
            }
        }
    }

    private static func getStoredData(
        from keychain: KeychainStoreBehavior,
        forKey key: String,
        fallbackTo defaultSource: UserDefaultsBehaviour
    ) -> Data? {
        if let data = try? keychain._getData(key) {
            return data
        } else {
            return defaultSource.data(forKey: key)
        }
    }
}

extension EndpointClient: DefaultLogger {}

extension EndpointClient {
    struct Constants {
        struct OptOut {
            static let all = "ALL"
            static let none = "NONE"
        }

        static let endpointProfileKey = "AWSPinpointEndpointProfileKey"
        static let deviceTokenKey = "com.amazonaws.AWSDeviceTokenKey"
    }
}

extension PinpointClientTypes.EndpointDemographic {
    struct Constants {
        static let appleMake = "apple"
        static let unknown = "Unknown"
    }

    init(device: EndpointInformation,
         locale: String = Locale.autoupdatingCurrent.identifier,
         timezone: String = TimeZone.current.identifier) {
        self.init(appVersion: device.appVersion,
                  locale: locale,
                  make: Constants.appleMake,
                  model: device.model,
                  platform: device.platform.name,
                  platformVersion: device.platform.version,
                  timezone: timezone)
    }
}
