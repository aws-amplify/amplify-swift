//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class PinpointEvent {
    let eventType: String
    let eventTimestamp: Date.Millisecond
    let session: PinpointSession
    private(set) lazy var attributes: [String: String] = [:]
    private(set) lazy var metrics: [String: Double] = [:]
    
    init(eventType: String,
         eventTimestamp: Date.Millisecond = Date().utcTimeMillis,
         session: PinpointSession) {
        self.eventType = eventType
        self.eventTimestamp = eventTimestamp
        self.session = session
    }
    
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
    
    func addAttribute(_ attribute: String, forKey key: String) {
        guard numberOfAttributesAndMetrics < Constants.maxNumberOfAttributesAndMetrics  else {
            log.warn("Max number of attributes/metrics reached, dropping attribute with key \(key)")
            return
        }

        attributes[trimmedKey(key)] = trimmedValue(attribute)
    }
    
    func addMetric(_ metric: Double, forKey key: String) {
        guard numberOfAttributesAndMetrics < Constants.maxNumberOfAttributesAndMetrics  else {
            log.warn("Max number of attributes/metrics reached, dropping attribute with key \(key)")
            return
        }

        metrics[trimmedKey(key)] = metric
    }
    
    func addMetric(_ metric: Int, forKey key: String) {
        addMetric(Double(metric), forKey: key)
    }
    
    func attribute(forKey key: String) -> String? {
        return attributes[key]
    }
    
    func metric(forKey key: String) -> Double? {
        return metrics[key]
    }
    
    private var numberOfAttributesAndMetrics: Int {
        return attributes.count + metrics.count
    }
    
    private func trimmedKey(_ string: String) -> String {
        return String(string.prefix(Constants.maxKeyLength))
    }
    
    private func trimmedValue(_ string: String) -> String {
        return String(string.prefix(Constants.maxValueLenght))
    }
}

// MARK: - DefaultLogger
extension PinpointEvent: DefaultLogger {}

extension PinpointEvent {
    private struct Constants {
        static let maxNumberOfAttributesAndMetrics = 50
        static let maxKeyLength = 50
        static let maxValueLenght = 1000
    }
}
