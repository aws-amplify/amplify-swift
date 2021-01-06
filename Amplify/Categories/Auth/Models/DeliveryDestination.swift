//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias Destination = String

public enum DeliveryDestination {

    case email(Destination?)

    case phone(Destination?)

    case sms(Destination?)

    case unknown(Destination?)
}
