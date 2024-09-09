//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

@_spi(InternalAWSPinpoint)
public struct PinpointEndpointProfile: Codable, Equatable {
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

    init(
        applicationId: String,
        endpointId: String,
        deviceToken: DeviceToken? = nil,
        effectiveDate: Date = Date(),
        isDebug: Bool = false,
        isOptOut: Bool = false,
        location: PinpointClientTypes.EndpointLocation = .init(),
        demographic: PinpointClientTypes.EndpointDemographic = .init(),
        user: PinpointClientTypes.EndpointUser = .init()
    ) {
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

    public mutating func addUserId(_ userId: String) {
        user.userId = userId
    }

    public mutating func addUserProfile(_ userProfile: UserProfile) {
        if let email = userProfile.email {
            setCustomProperty(email, forKey: Constants.AttributeKeys.email)
        }

        if let name = userProfile.name {
            setCustomProperty(name, forKey: Constants.AttributeKeys.name)
        }

        if let plan = userProfile.plan {
            setCustomProperty(plan, forKey: Constants.AttributeKeys.plan)
        }

        addCustomProperties(userProfile.customProperties)
        if let pinpointUser = userProfile as? PinpointUserProfile {
            addUserAttributes(pinpointUser.userAttributes)
            if let optedOutOfMessages = pinpointUser.optedOutOfMessages {
                isOptOut = optedOutOfMessages
            }
        }

        if let userLocation = userProfile.location {
            location.update(with: userLocation)
        }
    }

    public mutating func setAPNsToken(_ apnsToken: Data) {
        deviceToken = apnsToken.asHexString()
    }

    private mutating func addCustomProperties(_ properties: [String: UserProfilePropertyValue]?) {
        guard let properties else { return }
        for (key, value) in properties {
            setCustomProperty(value, forKey: key)
        }
    }

    private mutating func addUserAttributes(_ attributes: [String: [String]]?) {
        guard let attributes else { return }
        let userAttributes = user.userAttributes ?? [:]
        user.userAttributes = userAttributes.merging(
            attributes,
            uniquingKeysWith: { _, new in new }
        )
    }

    private mutating func setCustomProperty(
        _ value: UserProfilePropertyValue,
        forKey key: String
    ) {
        if let value = value as? String {
            attributes[key] = [value]
        } else if let values = value as? [String] {
            attributes[key] = values
        } else if let value = value as? Bool {
            attributes[key] = [String(value)]
        } else if let value = value as? Int {
            metrics[key] = Double(value)
        } else if let value = value as? Double {
            metrics[key] = value
        }
    }
}

extension PinpointEndpointProfile.DeviceToken? {
    var isNotEmpty: Bool {
        guard let self else { return false }
        return !self.isEmpty
    }
}

extension PinpointEndpointProfile {
    enum Constants {
        enum AttributeKeys {
            static let email = "email"
            static let name = "name"
            static let plan = "plan"
        }
    }
}
