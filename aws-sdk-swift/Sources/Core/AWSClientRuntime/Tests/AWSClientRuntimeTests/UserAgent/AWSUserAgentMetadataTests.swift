//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import ClientRuntime
@testable import AWSClientRuntime

class AWSUseragentMetadataTests: XCTestCase {
    let sdkMetadata = SDKMetadata(version: "0.0.1")
    let apiMetadata = APIMetadata(serviceID: "meow", version: "1.1")
    let osMetadata = OSMetadata(family: .iOS, version: "13.1")
    let languageMetadata = LanguageMetadata(version: "5.0")
    let executionEnvMetadata = ExecutionEnvMetadata(name: "e123")
    let frameworkMetadata = [FrameworkMetadata(name: "aws-amplify", version: "2.0.1")]

    #if targetEnvironment(simulator)
    func testSimulatorMetadata() {
        let sut = AWSUserAgentMetadata(sdkMetadata: sdkMetadata,
                                       apiMetadata: apiMetadata,
                                       osMetadata: osMetadata,
                                       languageMetadata: languageMetadata)
        XCTAssertEqual("aws-sdk-swift/0.0.1 ua/2.1 api/meow#1.1 os/ios#13.1 md/simulator lang/swift#5.0", sut.userAgent)
    }
    #else
    func testHappyPathMinimum() {
        let sut = AWSUserAgentMetadata(sdkMetadata: sdkMetadata,
                                       apiMetadata: apiMetadata,
                                       osMetadata: osMetadata,
                                       languageMetadata: languageMetadata)

        XCTAssertEqual("aws-sdk-swift/0.0.1 ua/2.1 api/meow#1.1 os/ios#13.1 lang/swift#5.0", sut.userAgent)
    }

    func testWithLanguageMetadataExtras() {
        let additionalMetadata = [AdditionalMetadata(name: "test1", value: "1.2.3")]
        let languageMetadataWithExtras = LanguageMetadata(version: "5.0", additionalMetadata: additionalMetadata)
        let sut = AWSUserAgentMetadata(sdkMetadata: sdkMetadata,
                                       apiMetadata: apiMetadata,
                                       osMetadata: osMetadata,
                                       languageMetadata: languageMetadataWithExtras)

        XCTAssertEqual("aws-sdk-swift/0.0.1 ua/2.1 api/meow#1.1 os/ios#13.1 lang/swift#5.0 md/test1#1.2.3", sut.userAgent)
    }

    func testWithExecutionEnv() {
        let sut = AWSUserAgentMetadata(sdkMetadata: sdkMetadata,
                                       apiMetadata: apiMetadata,
                                       osMetadata: osMetadata,
                                       languageMetadata: languageMetadata,
                                       executionEnvMetadata: executionEnvMetadata)

        XCTAssertEqual("aws-sdk-swift/0.0.1 ua/2.1 api/meow#1.1 os/ios#13.1 lang/swift#5.0 exec-env/e123", sut.userAgent)
    }

    func testWithLanguageMetadataExtrasAndExecutionEnv() {
        let additionalMetadata = [AdditionalMetadata(name: "test1", value: "1.2.3")]
        let languageMetadataWithExtras = LanguageMetadata(version: "5.0", additionalMetadata: additionalMetadata)
        let sut = AWSUserAgentMetadata(sdkMetadata: sdkMetadata,
                                       apiMetadata: apiMetadata,
                                       osMetadata: osMetadata,
                                       languageMetadata: languageMetadataWithExtras,
                                       executionEnvMetadata: executionEnvMetadata)

        XCTAssertEqual("aws-sdk-swift/0.0.1 ua/2.1 api/meow#1.1 os/ios#13.1 lang/swift#5.0 md/test1#1.2.3 exec-env/e123", sut.userAgent)
    }

    func testWithLanguageMetadataExtrasAndExecutionEnvWithFramework() {
        let additionalMetadata = [AdditionalMetadata(name: "test1", value: "1.2.3")]
        let languageMetadataWithExtras = LanguageMetadata(version: "5.0", additionalMetadata: additionalMetadata)
        let sut = AWSUserAgentMetadata(sdkMetadata: sdkMetadata,
                                       apiMetadata: apiMetadata,
                                       osMetadata: osMetadata,
                                       languageMetadata: languageMetadataWithExtras,
                                       executionEnvMetadata: executionEnvMetadata,
                                       frameworkMetadata: frameworkMetadata)

        XCTAssertEqual("aws-sdk-swift/0.0.1 ua/2.1 api/meow#1.1 os/ios#13.1 lang/swift#5.0 md/test1#1.2.3 exec-env/e123 lib/aws-amplify#2.0.1", sut.userAgent)
    }

    func testWithLanguageMetadataExtrasAndExecutionEnvWithFrameworkExtras() {
        let additionalMetadata = [AdditionalMetadata(name: "test1", value: "1.2.3")]
        let languageMetadataWithExtras = LanguageMetadata(version: "5.0", additionalMetadata: additionalMetadata)
        let frameworkMetadataWithExtras = [FrameworkMetadata(name: "aws-amplify", version: "2.0.1", additionalMetadata: [AdditionalMetadata(name: "f1", value: "c1")])]

        let sut = AWSUserAgentMetadata(sdkMetadata: sdkMetadata,
                                       apiMetadata: apiMetadata,
                                       osMetadata: osMetadata,
                                       languageMetadata: languageMetadataWithExtras,
                                       executionEnvMetadata: executionEnvMetadata,
                                       frameworkMetadata: frameworkMetadataWithExtras)

        XCTAssertEqual("aws-sdk-swift/0.0.1 ua/2.1 api/meow#1.1 os/ios#13.1 lang/swift#5.0 md/test1#1.2.3 exec-env/e123 lib/aws-amplify#2.0.1 md/f1#c1", sut.userAgent)
    }

    func testUserAgent() {
        let currentOS = ClientRuntime.currentOS
        let apiMeta = APIMetadata(serviceID: "Test Service", version: "1.2.3")
        let sdkMeta = SDKMetadata(version: apiMeta.version)
        let osMeta = OSMetadata(family: currentOS, version: "11.4")
        let langMeta = LanguageMetadata(version: "9.9")
        let awsUserAgent = AWSUserAgentMetadata(sdkMetadata: sdkMeta,
                                      apiMetadata: apiMeta,
                                      osMetadata: osMeta,
                                      languageMetadata: langMeta)
        var expected: String = ""
        switch currentOS {
        case .linux:
            expected = "aws-sdk-swift/1.2.3 ua/2.1 api/test_service#1.2.3 os/linux#11.4 lang/swift#9.9"
        case .macOS:
            expected = "aws-sdk-swift/1.2.3 ua/2.1 api/test_service#1.2.3 os/macos#11.4 lang/swift#9.9"
        case .iOS:
            expected = "aws-sdk-swift/1.2.3 ua/2.1 api/test_service#1.2.3 os/ios#11.4 lang/swift#9.9"
        case .tvOS:
            expected = "aws-sdk-swift/1.2.3 ua/2.1 api/test_service#1.2.3 os/tvos#11.4 lang/swift#9.9"
        case .visionOS:
            expected = "aws-sdk-swift/1.2.3 ua/2.1 api/test_service#1.2.3 os/visionos#11.4 lang/swift#9.9"
        case .watchOS:
            expected = "aws-sdk-swift/1.2.3 ua/2.1 api/test_service#1.2.3 os/watchos#11.4 lang/swift#9.9"
        case .unknown:
            expected = "aws-sdk-swift/1.2.3 ua/2.1 api/test_service#1.2.3 os/unknown#11.4 lang/swift#9.9"
        default:
            XCTFail("Unexpected OS")
        }
        XCTAssertEqual(awsUserAgent.userAgent, expected)
    }
    #endif
}
