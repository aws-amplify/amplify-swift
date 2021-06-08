//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias Destination = String

/// Destination where a partical item has been delivered
public enum DeliveryDestination {

    /// Email destination with optional associated value containing the email info
    case email(Destination?)

    /// Phone destination with optional associated value containing the phone number info
    case phone(Destination?)

    /// SMS destination with optional associated value containing the number info
    case sms(Destination?)

    /// Unknown destination with optional associated value destination detail
    case unknown(Destination?)
}
