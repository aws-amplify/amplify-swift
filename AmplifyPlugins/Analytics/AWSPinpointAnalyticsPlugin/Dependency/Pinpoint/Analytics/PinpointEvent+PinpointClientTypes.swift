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
        return PinpointClientTypes.Session(duration: Int(session.duration), id: session.sessionId, startTimestamp: session.startTime.iso8601FractionalSeconds(), stopTimestamp: session.stopTime?.iso8601FractionalSeconds())
    }
    
    var clientTypeEvent: PinpointClientTypes.Event {
        let timeStamp = Date(timeIntervalSince1970: TimeInterval(eventTimestamp)).iso8601FractionalSeconds()
        
        //TODO: get the swift sdk version and name
        return PinpointClientTypes.Event(appPackageName: Bundle.main.appPackageName, appTitle: Bundle.main.appName, appVersionCode: Bundle.main.appVersion, attributes: attributes, clientSdkVersion: "", eventType: eventType, metrics: metrics, sdkName: "", session: clientTypeSession, timestamp: timeStamp)
    }
}

extension Bundle {
    var appPackageName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? ""
    }

    var appName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    }
    
    var appBuild: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }

    var appVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}
