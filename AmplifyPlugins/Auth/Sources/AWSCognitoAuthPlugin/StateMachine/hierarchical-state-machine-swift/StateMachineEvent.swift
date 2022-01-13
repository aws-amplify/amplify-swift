//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Inspired by CloudEvents spec
/// - seealso: https://github.com/cloudevents/spec/blob/master/spec.md
protocol StateMachineEvent {
    // MARK: - Required attributes

    /// Identifies the event. Producers MUST ensure that source + id is unique for each
    /// distinct event. If a duplicate event is re-sent (e.g. due to a network error)
    /// it MAY have the same id. Consumers MAY assume that Events with identical source
    /// and id are duplicates.
    var id: String { get }

    /// This attribute contains a value describing the type of event related to the
    /// originating occurrence. Often this attribute is used for routing,
    /// observability, policy enforcement, etc. The format of this is producer defined
    /// and might include information such as the version of the type - see Versioning
    /// of Attributes in the Primer for more information.
    var type: String { get }

  //  var event_type_id: EventID { get }

    // MARK: - Optional attributes

    /// Timestamp of when the occurrence happened. If the time of the occurrence cannot
    /// be determined then this attribute MAY be set to some other time (such as the
    /// current time) by the CloudEvents producer, however all producers for the same
    /// source MUST be consistent in this respect. In other words, either they all use
    /// the actual time of the occurrence or they all use the same algorithm to
    /// determine the value used.
    ///
    /// If present, must serialize/deserialize into format specified by
    /// https://tools.ietf.org/html/rfc3339
    var time: Date? { get }
}

extension StateMachineEvent {
    var specVersion: String { "1.x-wip" }
}

struct EventID: Hashable {
    let id: String
}
