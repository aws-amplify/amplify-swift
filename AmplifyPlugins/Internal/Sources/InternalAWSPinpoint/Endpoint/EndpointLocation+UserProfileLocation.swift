//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint

extension PinpointClientTypes.EndpointLocation {
    mutating func update(with location: UserProfileLocation) {
        if let latitudeValue = location.latitude {
            latitude = latitudeValue
        }

        if let longitudeValue = location.longitude {
            longitude = longitudeValue
        }

        if let postalCodeValue = location.postalCode {
            postalCode = postalCodeValue
        }

        if let cityValue = location.city {
            city = cityValue
        }

        if let regionValue = location.region {
            region = regionValue
        }

        if let countryValue = location.country {
            country = countryValue
        }
    }
}
