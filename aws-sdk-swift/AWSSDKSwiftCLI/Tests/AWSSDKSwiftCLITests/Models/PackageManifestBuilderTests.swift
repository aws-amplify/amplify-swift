//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSSDKSwiftCLI
import XCTest

class PackageManifestBuilderTests: XCTestCase {

    let expected = """
<contents of prefix>
// MARK: - Dynamic Content

let clientRuntimeVersion: Version = "1.2.3"
let crtVersion: Version = "4.5.6"

let excludeRuntimeUnitTests = false

let serviceTargets: [String] = [
    "A",
    "B",
    "C",
    "D",
    "E",
]

<contents of base package>
"""

    func testBuild() throws {
        let subject = try PackageManifestBuilder(
            clientRuntimeVersion: .init("1.2.3"),
            crtVersion: .init("4.5.6"),
            services: ["A","B","C","D","E"].map { PackageManifestBuilder.Service(name: $0) },
            excludeRuntimeTests: false,
            prefixContents: { "<contents of prefix>" },
            basePackageContents: { "<contents of base package>" }
        )
        let result = try! subject.build()
        print("")
        print(result)
        print("")
        XCTAssertEqual(result, expected)
    }
}
