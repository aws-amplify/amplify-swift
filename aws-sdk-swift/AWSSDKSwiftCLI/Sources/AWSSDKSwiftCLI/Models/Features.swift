//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCLIUtils

/// Reads the Trebuchet request & service mapping files from the parent of the current working directory.
struct FeaturesReader {
    private let requestFile = "../build-request.json"
    private let mappingFile = "../feature-service-id.json"

    public func getFeaturesFromFile() throws -> Features {
        let fileContents = try FileManager.default.loadContents(atPath: requestFile)
        return try JSONDecoder().decode(Features.self, from: fileContents)
    }

    public func getFeaturesIDToServiceNameDictFromFile() throws -> [String: String] {
        let fileContents = try FileManager.default.loadContents(atPath: mappingFile)
        return try JSONDecoder().decode([String: String].self, from: fileContents)
    }
}

struct Features: Decodable {
    let features: [Feature]
}

struct Feature: Decodable {
    let releaseNotes: String?
    let featureMetadata: FeatureMetadata

    struct FeatureMetadata: Decodable {
        let trebuchet: Trebuchet

        struct Trebuchet: Decodable {
            let featureId: String
            let featureType: String
        }
    }
}
