//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

extension Geo.Device {
    public struct Error: Swift.Error, CustomDebugStringConvertible {
        public let debugDescription: String
        
        public static let missingUserID = Self(
            debugDescription: """
            This device option requires a user id that is not available.
            Please ensure that the user id is accessible or use a device
            option that isn't tied to a specific user.
            """
        )
    }
}

extension Geo {
    public struct Device {
        public let id: String
        
        init(id: String) {
            self.id = id
        }
        
        // Customer provided device ID
        // Device ID consistent across sessions, tied to specific device but not user
        public static func unchecked(id: String) -> Device {
            Device(id: id)
        }
        
        // Amplify generated device ID
        // Device ID consistent across sessions, tied to specific user but not device:
        // - <cognito-identity.amazonaws.com:sub>
        public static func tiedToUser() async throws -> Device {
            guard let id = try? await Amplify.Auth.getCurrentUser().userId else { throw Error.missingUserID }
            return Device(id: id)
        }
        
        // Amplify generated device ID
        // Device ID consistent across sessions, tied to specific user and device combination:
        // <cognito-identity.amazonaws.com:sub>-<UUID generated for, and stored on, device>
        public static func tiedToUserAndDevice() async throws -> Device {
            guard let id = try? await Amplify.Auth.getCurrentUser().userId else { throw Error.missingUserID }
            return Device(id: "\(id)-\(DeviceIdStore.getDeviceId())")
        }
        
        // Amplify generated device ID
        // Device ID consistent across sessions, tied to specific device but not user
        public static func tiedToDevice() -> Device {
            return Device(id: DeviceIdStore.getDeviceId())
        }
    }
    
    private struct DeviceIdStore {
        private static let deviceIdKey = ""
        public static func getDeviceId() -> String {
            if let deviceId = UserDefaults.standard.string(forKey:  Self.deviceIdKey) {
                return deviceId
            } else {
                let newDeviceId = UUID().uuidString
                UserDefaults.standard.set(newDeviceId, forKey: Self.deviceIdKey)
                return newDeviceId
            }
        }
    }
}
