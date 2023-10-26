//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct LocationClientConfiguration {
    let region: String
    let credentialsProvider: CredentialsProvider
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    static let servicName = "Location"
    static let clientName = "LocationClient"
    let signingName = "geo"
}
