//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol AnalyticsPropertiesModel {
    func addAttribute(_ attribute: String, forKey key: String)
    func addMetric(_ metric: Double, forKey key: String)
    func addMetric(_ metric: Int, forKey key: String)
}

extension AnalyticsPropertiesModel {
    func addProperties(_ properties: [String: AnalyticsPropertyValue]) {
        for (key, value) in properties {
            if let value = value as? String {
                addAttribute(value, forKey: key)
            } else if let value = value as? Int {
                addMetric(value, forKey: key)
            } else if let value = value as? Double {
                addMetric(value, forKey: key)
            } else if let value = value as? Bool {
                addAttribute(String(value), forKey: key)
            }
        }
    }
}
