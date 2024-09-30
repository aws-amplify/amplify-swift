//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct APIMetadata {
    let serviceID: String
    let version: String
}

extension APIMetadata: CustomStringConvertible {

    var description: String {
        let formattedServiceID = serviceID.replacingOccurrences(of: " ", with: "_").lowercased()
        return "api/\(formattedServiceID.userAgentToken)#\(version.userAgentToken)"
    }
}
