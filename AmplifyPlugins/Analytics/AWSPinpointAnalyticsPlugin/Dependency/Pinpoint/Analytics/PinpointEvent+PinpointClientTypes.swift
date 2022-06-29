//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation

extension PinpointEvent {
    var clientTypeSession: PinpointClientTypes.Session {
        return PinpointClientTypes.Session(duration: Int(session.duration),
                                           id: session.sessionId,
                                           startTimestamp: session.startTime.asISO8601String,
                                           stopTimestamp: session.stopTime?.asISO8601String)
    }

    var clientTypeEvent: PinpointClientTypes.Event {
        // TODO: get the swift sdk version and name
        return PinpointClientTypes.Event(appPackageName: Bundle.main.appPackageName,
                                         appTitle: Bundle.main.appName,
                                         appVersionCode: Bundle.main.appVersion,
                                         attributes: attributes,
                                         eventType: eventType,
                                         metrics: metrics,
                                         session: clientTypeSession,
                                         timestamp: eventDate.asISO8601String)
    }
}

extension Bundle {
    var appPackageName: String {
        object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? ""
    }

    var appName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    }

    var appBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }

    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}
