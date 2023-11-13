//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension PinpointClientTypes.EndpointLocation {
    mutating func update(with location: UserProfileLocation) {
        latitude = location.latitude ?? latitude
        longitude = location.longitude ?? longitude
        city = location.city ?? city
        region = location.region ?? region
        country = location.country ?? country
    }
}
