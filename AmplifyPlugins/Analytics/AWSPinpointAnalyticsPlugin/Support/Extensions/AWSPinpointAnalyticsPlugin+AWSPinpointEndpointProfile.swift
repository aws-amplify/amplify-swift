//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

// TODO: Implement in PinpointEndpointProfile

//extension AWSPinpointEndpointProfile {
//    func addIdentityId(_ identityId: String) {
//        let pinpointEndpointProfileUser = user ?? AWSPinpointEndpointProfileUser()
//        pinpointEndpointProfileUser.userId = identityId
//        user = pinpointEndpointProfileUser
//    }
//
//    func addProperties(_ properties: [String: AnalyticsPropertyValue]) {
//        for (key, value) in properties {
//            if let value = value as? String {
//                addAttribute([value], forKey: key)
//            } else if let value = value as? Int {
//                addMetric(value as NSNumber, forKey: key)
//            } else if let value = value as? Double {
//                addMetric(value as NSNumber, forKey: key)
//            } else if let value = value as? Bool {
//                addAttribute([String(value)], forKey: key)
//            }
//        }
//    }
//
//    func addUserProfile(_ userProfile: AnalyticsUserProfile) {
//        if let email = userProfile.email {
//            addAttribute([email], forKey: "email")
//        }
//
//        if let name = userProfile.name {
//            addAttribute([name], forKey: "name")
//        }
//
//        if let plan = userProfile.plan {
//            addAttribute([plan], forKey: "plan")
//        }
//
//        if let properties = userProfile.properties {
//            addProperties(properties)
//        }
//
//        if let locationValue = userProfile.location {
//            let pinpointEndpointProfileLocation = location ?? AWSPinpointEndpointProfileLocation()
//            pinpointEndpointProfileLocation.addLocation(locationValue)
//            location = pinpointEndpointProfileLocation
//        }
//    }
//}
