//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum LocalServer {
    static let endpoint = "http://127.0.0.1:9293"
    
    case boot
    case enroll
    case match
    case uninstall
}

extension LocalServer {
    var httpMethod: String {
        return "POST"
    }

    var path: String {
        switch self {
        case .boot: return "/boot"
        case .enroll: return "/enroll"
        case .match: return "/match"
        case .uninstall: return "/uninstall"
        }
    }

    var payload: Data? {
        switch self {
        case .boot,
             .enroll,
             .match,
             .uninstall:
            return try? JSONEncoder().encode(["deviceId": ""])
        }
    }

    var urlRequest: URLRequest {
        var request = URLRequest(url: URL(string: Self.endpoint + self.path)!)
        request.httpMethod = self.httpMethod
        request.httpBody = self.payload
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}
