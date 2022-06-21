//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

class PinpointEndpointProfile: Codable, AnalyticsPropertiesModel {
    typealias DeviceToken = String

    var applicationId: String
    var endpointId: String
    var deviceToken: DeviceToken?
    var effectiveDate: Date
    var isDebug: Bool
    var isOptOut: Bool
    var location: PinpointClientTypes.EndpointLocation
    var demographic: PinpointClientTypes.EndpointDemographic
    private(set) var user: PinpointClientTypes.EndpointUser
    private(set) var attributes: [String: [String]] = [:]
    private(set) var metrics: [String: Double] = [:]

    init(applicationId: String,
         endpointId: String,
         deviceToken: DeviceToken? = nil,
         effectiveDate: Date = Date(),
         isDebug: Bool = false,
         isOptOut: Bool = false,
         location: PinpointClientTypes.EndpointLocation = .init(),
         demographic: PinpointClientTypes.EndpointDemographic = .init(),
         user: PinpointClientTypes.EndpointUser = .init()) {
        self.applicationId = applicationId
        self.endpointId = endpointId
        self.deviceToken = deviceToken
        self.effectiveDate = effectiveDate
        self.isDebug = isDebug
        self.isOptOut = isOptOut
        self.location = location
        self.demographic = demographic
        self.user = user
    }

    func addIdentityId(_ identityId: String) {
        user.userId = identityId
    }

    func addUserProfile(_ userProfile: AnalyticsUserProfile) {
        if let email = userProfile.email {
            addAttribute(email, forKey: Constants.AttributeKeys.email)
        }

        if let name = userProfile.name {
            addAttribute(name, forKey: Constants.AttributeKeys.name)
        }

        if let plan = userProfile.plan {
            addAttribute(plan, forKey: Constants.AttributeKeys.plan)
        }

        if let properties = userProfile.properties {
            addProperties(properties)
        }

        if let userLocation = userProfile.location {
            location.update(with: userLocation)
        }
    }

    func addAttribute(_ attribute: String, forKey key: String) {
        attributes[key] = [attribute]
    }

    func addAttributes(_ newAttributes: [String], forKey key: String) {
        attributes[key] = newAttributes
    }

    func removeAttributes(forKey key: String) {
        attributes[key] = nil
    }

    func addMetric(_ metric: Int, forKey key: String) {
        addMetric(Double(metric), forKey: key)
    }

    func addMetric(_ metric: Double, forKey key: String) {
        metrics[key] = metric
    }

    func removeMetric(forKey key: String) {
        metrics[key] = nil
    }

    func removeAllAttributes() {
        attributes = [:]
    }

    func removeAllMetrics() {
        metrics = [:]
    }
}

extension Optional where Wrapped == PinpointEndpointProfile.DeviceToken {
    var isNotEmpty: Bool {
        guard let self = self else { return false }
        return !self.isEmpty
    }
}

extension PinpointEndpointProfile {
    struct Constants {
        struct AttributeKeys {
            static let email = "email"
            static let name = "name"
            static let plan = "plan"
        }
    }

    var channelType: PinpointClientTypes.ChannelType {
        return isDebug ? .apns : .apnsSandbox
    }

    var effectiveDateIso8601FractionalSeconds: String {
        effectiveDate.iso8601FractionalSeconds()
    }

    var optOut: String {
        return isOptOut ? EndpointClient.Constants.OptOut.all : EndpointClient.Constants.OptOut.none
    }
}
