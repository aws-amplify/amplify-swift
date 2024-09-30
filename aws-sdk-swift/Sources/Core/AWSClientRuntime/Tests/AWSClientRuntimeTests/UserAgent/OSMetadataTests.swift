//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSClientRuntime
import XCTest

class OSMetadataTests: XCTestCase {

    #if !targetEnvironment(simulator)
    func test_description_itIncludesSanitizedFamilyAndVersion() {
        let subject = OSMetadata(family: .iOS, version: "1.2.3🤡")
        XCTAssertEqual(subject.description, "os/ios#1.2.3-")
    }

    func test_description_itOmitsVersionIfItIsNil() {
        let subject = OSMetadata(family: .iOS, version: nil)
        XCTAssertEqual(subject.description, "os/ios")
    }

    func test_description_itOmitsVersionIfItIsAnEmptyString() {
        let subject = OSMetadata(family: .iOS, version: "")
        XCTAssertEqual(subject.description, "os/ios")
    }

    func test_description_itHasCorrectStringsForOperatingSystems() {
        XCTAssertEqual(OSMetadata(family: .windows).description, "os/windows")
        XCTAssertEqual(OSMetadata(family: .linux).description, "os/linux")
        XCTAssertEqual(OSMetadata(family: .iOS).description, "os/ios")
        XCTAssertEqual(OSMetadata(family: .macOS).description, "os/macos")
        XCTAssertEqual(OSMetadata(family: .watchOS).description, "os/watchos")
        XCTAssertEqual(OSMetadata(family: .tvOS).description, "os/tvos")
        XCTAssertEqual(OSMetadata(family: .visionOS).description, "os/visionos")
        XCTAssertEqual(OSMetadata(family: .unknown).description, "os/other")
    }
    #endif
}
