//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public typealias Destination = String

/// <#Description#>
public enum DeliveryDestination {

    /// <#Description#>
    case email(Destination?)

    /// <#Description#>
    case phone(Destination?)

    /// <#Description#>
    case sms(Destination?)

    /// <#Description#>
    case unknown(Destination?)
}
