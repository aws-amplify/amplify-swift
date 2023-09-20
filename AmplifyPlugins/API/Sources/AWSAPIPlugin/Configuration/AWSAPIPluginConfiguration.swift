//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

public struct AWSAPIPluginConfiguration: Codable {

    typealias APIName = String
    
    let apis: [APIName: Configuration]
    
    struct Configuration: Codable {
        let endpointType: String
        let endpoint: URL
        let region: String
        let authorizationType: String
    }
}
