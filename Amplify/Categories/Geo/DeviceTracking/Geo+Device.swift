//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Geo {
    public struct Device {
        public let id: String
        //Note: Internal...
        public let _deviceCharacteristic: DeviceCharacteristic
        
        public init(id: String, deviceCharacteristic: Geo.DeviceCharacteristic = .none) {
            self.id = id
            self._deviceCharacteristic = deviceCharacteristic
        }
        
        // Customer provided device ID
        // Device ID consistent across sessions, tied to specific device but not user
        public static func unchecked(id: String) -> Device {
            Device(id: id)
        }
        
        // Amplify generated device ID
        // Device ID consistent across sessions, tied to specific device but not user
        public static func tiedToDevice() -> Device {
            return Device(id: DeviceIdStore.getDeviceId())
        }
        
        // Amplify generated device ID
        // Device ID consistent across sessions, tied to specific user but not device:
        // - <cognito-identity.amazonaws.com:sub>
        public static func tiedToUser() -> Device {
            return Device(id: "", deviceCharacteristic: .tiedToUser)
        }
        
        // Amplify generated device ID
        // Device ID consistent across sessions, tied to specific user and device combination:
        // <cognito-identity.amazonaws.com:sub>-<UUID generated for, and stored on, device>
        public static func tiedToUserAndDevice() -> Device {
            return Device(id: DeviceIdStore.getDeviceId(), deviceCharacteristic: .tiedToUserAndDevice)
        }
    }
    
    //Note: Internal...
    public enum DeviceCharacteristic {
        case none
        case tiedToUser
        case tiedToUserAndDevice
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
