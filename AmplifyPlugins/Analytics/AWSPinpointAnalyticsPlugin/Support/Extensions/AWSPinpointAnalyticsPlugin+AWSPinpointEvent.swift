//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

// TODO: Implement in PinpointEvent

//extension AWSPinpointEvent {
//    func addProperties(_ properties: [String: AnalyticsPropertyValue]) {
//        for (key, value) in properties {
//            if let value = value as? String {
//                addAttribute(value, forKey: key)
//            } else if let value = value as? Int {
//                addMetric(value as NSNumber, forKey: key)
//            } else if let value = value as? Double {
//                addMetric(value as NSNumber, forKey: key)
//            } else if let value = value as? Bool {
//                addAttribute(String(value), forKey: key)
//            }
//        }
//    }
//}
