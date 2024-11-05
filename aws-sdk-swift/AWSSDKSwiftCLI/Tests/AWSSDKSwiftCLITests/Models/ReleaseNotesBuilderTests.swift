//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSSDKSwiftCLI
import AWSCLIUtils
import XCTest

/*
 *  Regression tests for protection against change in generated release notes markdown content.
 */
class ReleaseNotesBuilderTests: CLITestCase {
    /* Reusable feature strings */

    // New feature 1
    private let feature1 = """
    {
        "releaseNotes": "New feature description A.",
        "featureMetadata": {
            "trebuchet": {
                "featureId": "feature-id-a",
                "featureType": "NEW_FEATURE",
            }
        }
    }
    """

    // New feature 2
    private let feature2 = """
    {
        "releaseNotes": "New feature description B.",
        "featureMetadata": {
            "trebuchet": {
                "featureId": "feature-id-b",
                "featureType": "NEW_FEATURE",
            }
        }
    }
    """

    // Documentation update
    private let feature3 = """
    {
        "releaseNotes": "Doc update description C.",
        "featureMetadata": {
            "trebuchet": {
                "featureId": "feature-id-c",
                "featureType": "DOC_UPDATE",
            }
        }
    }
    """

    // Feature with null releaseNotes field
    private let feature4 = """
    {
        "releaseNotes": null,
        "featureMetadata": {
            "trebuchet": {
                "featureId": "feature-id-d",
                "featureType": "DOC_UPDATE",
            }
        }
    }
    """

    // Dictionary of feature ID to name of the service
    private let mapping = """
    {
        "feature-id-a": "Service 1",
        "feature-id-b": "Service 2",
        "feature-id-c": "Service 3",
        "feature-id-d": "Service 4"
    }
    """

    func testAllSectionsPresent() throws {
        let buildRequest = """
        { "features": [\(feature1), \(feature2), \(feature3)] }
        """
        setUpBuildRequestAndMappingJSONs(buildRequest, mapping)
        let builder = try setUpBuilder(testCommits: ["fix: Fix X", "feat: Feat Y"])
        let releaseNotes = try builder.build()
        let expected = """
        ## What's Changed
        ### Service Features
        * **AWS Service 1**: New feature description A.
        * **AWS Service 2**: New feature description B.
        ### Service Documentation
        * **AWS Service 3**: Doc update description C.
        ### Miscellaneous
        * fix: Fix X
        * feat: Feat Y

        **Full Changelog**: https://github.com/awslabs/aws-sdk-swift/compare/1.0.0...1.0.1
        """
        XCTAssertEqual(releaseNotes, expected)
    }

    func testNoServiceFeatureSectionPresent() throws {
        let buildRequest = """
        { "features": [\(feature3)] }
        """
        setUpBuildRequestAndMappingJSONs(buildRequest, mapping)
        let builder = try setUpBuilder(testCommits: ["fix: Fix X", "feat: Feat Y"])
        let releaseNotes = try builder.build()
        let expected = """
        ## What's Changed
        ### Service Documentation
        * **AWS Service 3**: Doc update description C.
        ### Miscellaneous
        * fix: Fix X
        * feat: Feat Y

        **Full Changelog**: https://github.com/awslabs/aws-sdk-swift/compare/1.0.0...1.0.1
        """
        XCTAssertEqual(releaseNotes, expected)
    }

    func testNoServiceDocSectionPresent() throws {
        let buildRequest = """
        { "features": [\(feature1), \(feature2)] }
        """
        setUpBuildRequestAndMappingJSONs(buildRequest, mapping)
        let builder = try setUpBuilder(testCommits: ["fix: Fix X", "feat: Feat Y"])
        let releaseNotes = try builder.build()
        let expected = """
        ## What's Changed
        ### Service Features
        * **AWS Service 1**: New feature description A.
        * **AWS Service 2**: New feature description B.
        ### Miscellaneous
        * fix: Fix X
        * feat: Feat Y

        **Full Changelog**: https://github.com/awslabs/aws-sdk-swift/compare/1.0.0...1.0.1
        """
        XCTAssertEqual(releaseNotes, expected)
    }

    func testNoSDKChangeSectionPresent() throws {
        let buildRequest = """
        { "features": [\(feature1), \(feature2), \(feature3)] }
        """
        setUpBuildRequestAndMappingJSONs(buildRequest, mapping)
        let builder = try setUpBuilder()
        let releaseNotes = try builder.build()
        let expected = """
        ## What's Changed
        ### Service Features
        * **AWS Service 1**: New feature description A.
        * **AWS Service 2**: New feature description B.
        ### Service Documentation
        * **AWS Service 3**: Doc update description C.

        **Full Changelog**: https://github.com/awslabs/aws-sdk-swift/compare/1.0.0...1.0.1
        """
        XCTAssertEqual(releaseNotes, expected)
    }

    func testNoSectionsPresentAndIrrelevantCommitsAreFiltered() throws {
        let buildRequest = """
        { "features":[] }
        """
        setUpBuildRequestAndMappingJSONs(buildRequest, mapping)
        let builder = try setUpBuilder(testCommits: ["chore: Commit A", "Update X"])
        let releaseNotes = try builder.build()
        let expected = """
        ## What's Changed

        **Full Changelog**: https://github.com/awslabs/aws-sdk-swift/compare/1.0.0...1.0.1
        """
        XCTAssertEqual(releaseNotes, expected)
    }

    func testNullReleaseNotesFieldGetsHandledWithoutError() throws {
        let buildRequest = """
        { "features": [\(feature4)] }
        """
        setUpBuildRequestAndMappingJSONs(buildRequest, mapping)
        let builder = try setUpBuilder()
        let releaseNotes = try builder.build()
        let expected = """
        ## What's Changed
        ### Service Documentation
        * **AWS Service 4**: No description provided.

        **Full Changelog**: https://github.com/awslabs/aws-sdk-swift/compare/1.0.0...1.0.1
        """
        XCTAssertEqual(releaseNotes, expected)
    }

    private func setUpBuildRequestAndMappingJSONs(_ buildRequest: String, _ mapping: String) {
        // In real scenario, the JSON files we need are located one level above, in the workspace directory.
        // So, the dummy files are created in the parent of the current directory to match a real build.
        FileManager.default.createFile(atPath: "../build-request.json", contents: Data(buildRequest.utf8))
        FileManager.default.createFile(atPath: "../feature-service-id.json", contents: Data(mapping.utf8))
    }

    private func setUpBuilder(testCommits: [String] = []) throws -> ReleaseNotesBuilder {
        return try ReleaseNotesBuilder(
            previousVersion: Version("1.0.0"),
            newVersion: Version("1.0.1"),
            repoOrg: .awslabs,
            repoType: .awsSdkSwift,
            commits: testCommits,
            // Parameterize behavior of FeaturesReader with paths used to create JSON test files
            features: FeaturesReader().getFeaturesFromFile(),
            featuresIDToServiceName: FeaturesReader().getFeaturesIDToServiceNameDictFromFile()
        )
    }
}
