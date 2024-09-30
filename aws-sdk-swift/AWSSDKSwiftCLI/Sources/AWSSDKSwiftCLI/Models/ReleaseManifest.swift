//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ReleaseManifest: Codable {
    let name: String
    let tagName: String
    let body: String
    let assets: [Asset]
}

extension ReleaseManifest {
    struct Asset: Codable {
        let artifactId: String
        let name: String
    }
}

extension ReleaseManifest {
    static func fromFile(_ filePath: String) throws -> Self {
        let fileContents = try FileManager.default.loadContents(atPath: filePath)
        return try JSONDecoder().decode(Self.self, from: fileContents)
    }
}
