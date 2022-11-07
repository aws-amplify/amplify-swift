//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Amplify

struct AWSGeoHubPayloadData {
    let error: Geo.Error?
    let locations: [Geo.Location]
    
    init(error: Geo.Error? = nil, locations: [Geo.Location] = []) {
        self.error = error
        self.locations = locations
    }
}
