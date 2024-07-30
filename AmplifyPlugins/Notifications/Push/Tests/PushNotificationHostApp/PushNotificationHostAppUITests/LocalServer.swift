//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
		

import Foundation

enum LocalServer {
    static let endpoint = "http://127.0.0.1:9293"

    case notifications(PinpointNotification)
    case uninstall(String)
    case boot(String)
}

extension LocalServer {
    var httpMethod: String {
        switch self {
        case .notifications: return "POST"
        case .uninstall: return "POST"
        case .boot: return "POST"
        }
    }

    var path: String {
        switch self {
        case .notifications: return "/notifications"
        case .uninstall: return "/uninstall"
        case .boot: return "/boot"
        }
    }

    var payload: Data? {
        switch self {
        case let .notifications(notification):
            return try? JSONEncoder().encode(notification)
        case let .uninstall(deviceId):
            return try? JSONEncoder().encode(["deviceId": deviceId])
        case let .boot(deviceId):
            return try? JSONEncoder().encode(["deviceId": deviceId])
        }
    }

    var additionalRequestHeaders: [String: String]? {
        switch self {
        case .notifications, .uninstall, .boot:
            return ["Content-Type": "application/json"]
        }
    }

    var urlRequest: URLRequest {
        var request = URLRequest(url: URL(string: Self.endpoint + self.path)!)
        request.httpMethod = self.httpMethod
        request.httpBody = self.payload
        additionalRequestHeaders?.forEach({ key, value in
            request.addValue(value, forHTTPHeaderField: key)
        })
        return request
    }
}
