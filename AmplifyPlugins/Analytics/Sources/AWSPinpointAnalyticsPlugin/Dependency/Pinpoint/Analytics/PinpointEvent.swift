//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class PinpointEvent: AnalyticsPropertiesModel {
    let id: String
    let eventType: String
    let eventDate: Date
    let session: PinpointSession
    private(set) lazy var attributes: [String: String] = [:]
    private(set) lazy var metrics: [String: Double] = [:]

    init(id: String = UUID().uuidString,
         eventType: String,
         eventDate: Date = Date(),
         session: PinpointSession) {
        self.id = id
        self.eventType = eventType
        self.eventDate = eventDate
        self.session = session
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

// MARK: - Equatable
extension PinpointEvent: Equatable {
    static func == (lhs: PinpointEvent, rhs: PinpointEvent) -> Bool {
        return lhs.eventType == rhs.eventType
        && lhs.eventDate == rhs.eventDate
        && lhs.session == rhs.session
        && lhs.attributes == rhs.attributes
        && lhs.metrics == rhs.metrics
    }
}

// MARK: - DefaultLogger
extension PinpointEvent: DefaultLogger {}

extension PinpointEvent {
    private struct Constants {
        static let maxNumberOfAttributesAndMetrics = 40
        static let maxKeyLength = 50
        static let maxValueLenght = 200
    }
}
