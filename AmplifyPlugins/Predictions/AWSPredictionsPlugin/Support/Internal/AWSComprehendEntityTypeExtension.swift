//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSComprehend

extension AWSComprehendEntityType {

    // swiftlint:disable:next cyclomatic_complexity
    func toAmplifyEntityType() -> EntityType {
        switch self {
        case .person:
            return .person
        case .location:
            return .location
        case .organization:
            return .organization
        case .commercialItem:
            return .commercialItem
        case .event:
            return .event
        case .date:
            return .date
        case .quantity:
            return .quantity
        case .title:
            return .title
        case .other:
            return .other
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}
