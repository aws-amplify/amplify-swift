//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

protocol EndpointClientBehaviour: Actor {
    nonisolated var pinpointClient: PinpointClientProtocol { get }

    func currentEndpointProfile() async -> PinpointEndpointProfile
    func updateEndpointProfile() async throws
    func updateEndpointProfile(with endpointProfile: PinpointEndpointProfile) async throws
    func addAttributes(_ attributes: [String], forKey key: String)
    func removeAttributes(forKey key: String)
    func addMetric(_ metric: Double, forKey key: String)
    func removeMetric(forKey key: String)
    nonisolated func convertToPublicEndpoint(_ endpointProfile: PinpointEndpointProfile) -> PinpointClientTypes.PublicEndpoint
}

actor EndpointClient: EndpointClientBehaviour {
    struct Configuration {
        let appId: String
        let uniqueDeviceId: String
        let isDebug: Bool
        let isOptOut: Bool
    }

    let pinpointClient: PinpointClientProtocol

    private let configuration: EndpointClient.Configuration
    private let archiver: AmplifyArchiverBehaviour
    private let currentDevice: Device
    private let userDefaults: UserDefaultsBehaviour

    private var globalAttributes: [String: [String]] = [:]
    private var globalMetrics: [String: Double] = [:]

    private var endpointProfile: PinpointEndpointProfile?
    private static let defaultDateFormatter = ISO8601DateFormatter()

    init(configuration: EndpointClient.Configuration,
         pinpointClient: PinpointClientProtocol,
         archiver: AmplifyArchiverBehaviour = AmplifyArchiver(),
         currentDevice: Device = DeviceProvider.current,
         userDefaults: UserDefaultsBehaviour = UserDefaults.standard) {
        self.configuration = configuration
        self.pinpointClient = pinpointClient
        self.archiver = archiver
        self.currentDevice = currentDevice
        self.userDefaults = userDefaults

        if let attributes = userDefaults.object(forKey: Constants.attributesKey) as? [String: [String]] {
            globalAttributes = attributes
        }

        if let metrics = userDefaults.object(forKey: Constants.metricsKey) as? [String: Double] {
            globalMetrics = metrics
        }
    }

    func currentEndpointProfile() async -> PinpointEndpointProfile {
        let endpointProfile = await retrieveOrCreateEndpointProfile()

        // Refresh Attributes and Metrics
        endpointProfile.removeAllAttributes()
        endpointProfile.removeAllMetrics()
        addAttributesAndMetrics(to: endpointProfile)

        self.endpointProfile = endpointProfile
        return endpointProfile
    }

    func updateEndpointProfile() async throws {
        try await updateEndpoint(with: currentEndpointProfile())
    }

    func updateEndpointProfile(with endpointProfile: PinpointEndpointProfile) async throws {
        addAttributesAndMetrics(to: endpointProfile)
        try await updateEndpoint(with: endpointProfile)
    }

    func addAttributes(_ attributes: [String], forKey key: String) {
        precondition(!key.isEmpty, "Attributes and metrics must have a valid key")
        globalAttributes[key] = attributes
        userDefaults.save(globalAttributes, forKey: Constants.attributesKey)
    }

    func removeAttributes(forKey key: String) {
        globalAttributes[key] = nil
    }

    func addMetric(_ metric: Double, forKey key: String) {
        precondition(!key.isEmpty, "Attributes and metrics must have a valid key")
        globalMetrics[key] = metric
        userDefaults.save(globalAttributes, forKey: Constants.metricsKey)
    }

    func removeMetric(forKey key: String) {
        globalMetrics[key] = nil
    }

    private func addAttributesAndMetrics(to endpointProfile: PinpointEndpointProfile) {
        // Add global attributes
        log.verbose("Applying Global Endpoint Attributes: \(globalAttributes)")
        for (key, attributes) in globalAttributes {
            endpointProfile.addAttributes(attributes, forKey: key)
        }

        // Add global metrics
        log.verbose("Applying Global Endpoint Metrics: \(globalMetrics)")
        for (key, metric) in globalMetrics {
            endpointProfile.addMetric(metric, forKey: key)
        }
    }

    private func retrieveOrCreateEndpointProfile() async -> PinpointEndpointProfile {
        // 1. Look for the local endpointProfile variable
        if let endpointProfile = endpointProfile {
            return await configure(endpointProfile: endpointProfile)
        }

        // 2. Look for a valid PinpointEndpointProfile object stored in UserDefaults. It needs to match the current applicationId, otherwise we'll discard it.
        if let endpointProfileData = userDefaults.data(forKey: Constants.endpointProfileKey),
           let decodedEndpointProfile = try? archiver.decode(PinpointEndpointProfile.self, from: endpointProfileData),
           decodedEndpointProfile.applicationId == configuration.appId {
            return await configure(endpointProfile: decodedEndpointProfile)
        }

        userDefaults.removeObject(forKey: Constants.endpointProfileKey)
        // 3. Look for a valid PinpointEndpointProfile object stored in the Keychain. It needs to match the current applicationId, otherwise we'll discard it.
        // TODO: Implement once the migration is completed in the legacy SDK.

        // Create a new PinpointEndpointProfile
        return await configure(endpointProfile: PinpointEndpointProfile(applicationId: configuration.appId,
                                                                  endpointId: configuration.uniqueDeviceId))
    }

    private func configure(endpointProfile: PinpointEndpointProfile) async -> PinpointEndpointProfile {
        var deviceToken: PinpointEndpointProfile.DeviceToken?
        if let tokenData = userDefaults.data(forKey: Constants.deviceTokenKey) {
            deviceToken = tokenData.asHexString()
        }

        let areNotificationsEnabled = await AWSPinpointAnalyticsNotifications.areNotificationsEnabled
        let isUsingPinpointForNotifications = areNotificationsEnabled && deviceToken.isNotEmpty
        let isOptOut = configuration.isOptOut || !isUsingPinpointForNotifications

        endpointProfile.applicationId = configuration.appId
        endpointProfile.endpointId = configuration.uniqueDeviceId
        endpointProfile.deviceToken = deviceToken
        endpointProfile.location = .init()
        endpointProfile.demographic = .init(device: currentDevice)
        endpointProfile.effectiveDate = Date()
        endpointProfile.isOptOut = isOptOut
        endpointProfile.isDebug = configuration.isDebug

        return endpointProfile
    }

    private func updateEndpoint(with endpointProfile: PinpointEndpointProfile) async throws {
        let input = createUpdateInput(from: endpointProfile)
        log.verbose("UpdateEndpointInput: \(input)")
        do {
            let output = try await pinpointClient.updateEndpoint(input: input)
            if let encodedData = try? archiver.encode(endpointProfile) {
                userDefaults.save(encodedData, forKey: Constants.endpointProfileKey)
            }
            self.endpointProfile = endpointProfile
            log.verbose("Endpoint Updated Successfully! \(output)")
        } catch {
            log.error("Unable to successfully update endpoint. Error Message: \(error.localizedDescription)")
            log.error(error: error)
            throw error
        }
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
}

extension EndpointClient: DefaultLogger {}

extension EndpointClient {
    struct Constants {
        struct OptOut {
            static let all = "ALL"
            static let none = "NONE"
        }

        static let attributesKey = "AWSPinpointEndpointAttributesKey"
        static let metricsKey = "AWSPinpointEndpointMetricsKey"
        static let endpointProfileKey = "AWSPinpointEndpointProfileKey"
        static let deviceTokenKey = "com.amazonaws.AWSDeviceTokenKey"
    }
}

extension PinpointClientTypes.EndpointDemographic {
    struct Constants {
        static let appleMake = "apple"
        static let unknown = "Unknown"
    }

    init(device: Device,
         locale: String = Locale.autoupdatingCurrent.identifier,
         timezone: String = TimeZone.current.identifier) {
        self.init(appVersion: device.appVersion ?? Constants.unknown,
                  locale: locale,
                  make: Constants.appleMake,
                  model: device.model,
                  platform: device.platform.name,
                  platformVersion: device.platform.version,
                  timezone: timezone)
    }
}

extension Data {
    func asHexString() -> String {
        reduce("") { "\($0)\(String(format: "%02x", $1))" }
    }
}
