//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
		

import Foundation

struct PinpointNotification: Codable {
    let notification: Notification
    let data: PinpointData?
    let deviceId: String
}

struct Notification: Codable {
    let title: String
    let substitle: String?
    let body: String
}

struct PinpointData: Codable {
    let pinpoint: PinpointInfo?
}

struct PinpointInfo: Codable {
    let campaign: [String: String]?
    let journey: [String: String]?
    let deeplink: String?
}
