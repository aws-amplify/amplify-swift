//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

private typealias Constants = AWSPinpointAnalytics.Constants.Event

/// - Note: `final` and `@unchecked Sendable`. The identity and session fields are `let`, so those are
///   genuinely immutable. `attributes` and `metrics` are not: they are `lazy var` with `public` mutators
///   (`addAttribute(_:forKey:)`, `addMetric(_:forKey:)`), and they are unsynchronized.
///
///   The intended lifecycle is build-then-submit — attributes are added while composing the event, and it
///   is immutable in practice once handed to the recorder. But that is a caller contract, not something
///   this type enforces: nothing stops a caller retaining the event and adding an attribute after it is
///   enqueued, and because events are queued for a later flush the two can genuinely overlap. `lazy`
///   makes it slightly worse, since even a first *read* mutates the storage.
///
///   The exposure predates this annotation, which only stops the compiler from asking about it.
@_spi(InternalAWSPinpoint)
public final class PinpointEvent: AnalyticsPropertiesModel, @unchecked Sendable {
    let id: String
    public let eventType: String
    let eventDate: Date
    let session: PinpointSession
    let retryCount: Int
    public private(set) lazy var attributes: [String: String] = [:]
    public private(set) lazy var metrics: [String: Double] = [:]

    init(
        id: String = UUID().uuidString,
        eventType: String,
        eventDate: Date = Date(),
        session: PinpointSession,
        retryCount: Int = 0
    ) {
        self.id = id
        self.eventType = eventType
        self.eventDate = eventDate
        self.session = session
        self.retryCount = retryCount
    }

    public func addAttribute(_ attribute: String, forKey key: String) {
        guard attributes.count < Constants.maximumNumberOfAttributes  else {
            log.warn("Max number of attributes reached, dropping attribute with key \(key)")
            return
        }

        attributes[trimmedKey(key)] = trimmedValue(attribute, forKey: key)
    }

    public func addMetric(_ metric: Double, forKey key: String) {
        guard metrics.count < Constants.maximumNumberOfMetrics  else {
            log.warn("Max number of metrics reached, dropping metric with key \(key)")
            return
        }

        metrics[trimmedKey(key)] = metric
    }

    public func addMetric(_ metric: Int, forKey key: String) {
        addMetric(Double(metric), forKey: key)
    }

    func attribute(forKey key: String) -> String? {
        return attributes[key]
    }

    func metric(forKey key: String) -> Double? {
        return metrics[key]
    }

    private func trimmedKey(_ string: String) -> String {
        if string.count > Constants.maximumKeyLength {
            log.warn("The \(string) key has been trimmed to a length of \(Constants.maximumKeyLength) characters")
        }
        return String(string.prefix(Constants.maximumKeyLength))
    }

    private func trimmedValue(_ string: String, forKey key: String) -> String {
        if string.count > Constants.maximumValueLength {
            log.warn("The value for key \(key) has been trimmed to a length of \(Constants.maximumValueLength) characters")
        }
        return String(string.prefix(Constants.maximumValueLength))
    }
}

// MARK: - Equatable
extension PinpointEvent: Equatable {
    public static func == (lhs: PinpointEvent, rhs: PinpointEvent) -> Bool {
        return lhs.eventType == rhs.eventType
        && lhs.eventDate == rhs.eventDate
        && lhs.session == rhs.session
        && lhs.attributes == rhs.attributes
        && lhs.metrics == rhs.metrics
    }
}

// MARK: - DefaultLogger
extension PinpointEvent: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.analytics.displayName, forNamespace: String(describing: self))
    }

    public var log: Logger {
        Self.log
    }
}

// MARK: - CustomStringConvertible
extension PinpointEvent: CustomStringConvertible {
    public var description: String {
        let string = """
        {
            "id": "\(id)",
            "eventType": "\(eventType)",
            "session": {
                "sessionId": "\(session.sessionId)"
                "startTime:" "\(session.startTime)"
                "stopTime": "\(String(describing: session.stopTime))"
            },
            attributes: \(string(from: attributes)),
            metrics: \(string(from: metrics))
        }
        """
        return string
    }

    private func string(from dictionary: AnalyticsProperties) -> String {
        if dictionary.isEmpty {
            return "[:]"
        }

        var string = ""
        for (key, value) in dictionary.sorted(by: { $0.key < $1.key}) {
            string += "\n\t\t\"\(key)\": \"\(value)\""
        }
        return "[\(string)\n\t]"
    }
}
