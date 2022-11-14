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
        
        /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
        ///   by host applications. The behavior of this may change without warning.
        public let _deviceCharacteristic: DeviceCharacteristic
        
        public init(id: String, deviceCharacteristic: Geo.DeviceCharacteristic = .none) {
            self.id = id
            self._deviceCharacteristic = deviceCharacteristic
        }
        
        /// Create your own device id. Use this at your own risk
        /// - Warning: Ensure provided identifier excludes discernable pattern or personally identifiable information and
        /// follows security best practices.  Recommendation is to use Geo.Device.tiedToUser()
        /// - Parameter id: The device ID
        /// - Returns: A `Device` with your provided `id`.
        public static func unchecked(id: String) -> Device {
            Device(id: id)
        }
        
        /// Create an Amplify generated device ID
        /// Device ID is consistent across sessions, tied to specific device but not user
        /// - Returns: A `Device` with identifier tied to the device.
        public static func tiedToDevice() -> Device {
            return Device(id: DeviceIdStore.getDeviceId())
        }
        
        /// Create an Amplify generated device ID
        /// Device ID is consistent across sessions, tied to specific user
        /// - Returns: A `Device` with identifier tied to user's cognito identity id.
        public static func tiedToUser() -> Device {
            return Device(id: "", deviceCharacteristic: .tiedToUser)
        }
        
        /// Create an Amplify generated device ID
        /// Device ID is consistent across sessions, tied to specific user and device combination
        /// - Returns: A `Device` with identifier tied to user's cognito identity id and device combination
        public static func tiedToUserAndDevice() -> Device {
            return Device(id: DeviceIdStore.getDeviceId(), deviceCharacteristic: .tiedToUserAndDevice)
        }
    }
    
    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public enum DeviceCharacteristic {
        case none
        case tiedToUser
        case tiedToUserAndDevice
    }
    
    private struct DeviceIdStore {
        private static let deviceIdKey = ""
        static func getDeviceId() -> String {
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
