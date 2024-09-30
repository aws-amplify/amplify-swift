//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAuth
import SmithyHTTPAuthAPI
import AWSSDKHTTPAuth
import XCTest
import SmithyTestUtil
import ClientRuntime

class CustomSigningPropertiesSetterTests: XCTestCase {
    private var customSetter: AWSSDKHTTPAuth.CustomSigningPropertiesSetter!
    private var context: ContextBuilder!
    private var signingProperties: Attributes!

    override func setUp() {
        customSetter = CustomSigningPropertiesSetter()
        context = ContextBuilder()
        signingProperties = Attributes()
    }

    // Exception case
    func testNoOperationNamePresent() throws {
        let tempCtx = context.withServiceName(value: "S3").build()
        do {
            try customSetter.setServiceSpecificSigningProperties(
                signingProperties: &signingProperties, context: tempCtx
            )
            XCTFail("Expected exception was not thrown.")
        } catch ClientError.authError(let message){
            XCTAssertEqual(message, "Missing operation name in middleware context.")
        }
    }

    // Test unsigned body set to true for S3::getObject
    func testUnsignedBodyIsTrueForS3GetObjectWithPresignURLFlow() throws {
        let tempCtx = context
            .withServiceName(value: "S3")
            .withOperation(value: "getObject")
            .withFlowType(value: .PRESIGN_URL)
            .build()
        try customSetter.setServiceSpecificSigningProperties(
            signingProperties: &signingProperties, context: tempCtx
        )
        XCTAssertTrue(try XCTUnwrap(signingProperties.get(key: SigningPropertyKeys.unsignedBody)))
    }

    // Test unsigned body set to true for S3::putObject
    func testUnsignedBodyIsTrueForS3PutObjectWithPresignURLFlow() throws {
        let tempCtx = context
            .withServiceName(value: "S3")
            .withOperation(value: "putObject")
            .withFlowType(value: .PRESIGN_URL)
            .build()
        try customSetter.setServiceSpecificSigningProperties(
            signingProperties: &signingProperties, context: tempCtx
        )
        XCTAssertTrue(try XCTUnwrap(signingProperties.get(key: SigningPropertyKeys.unsignedBody)))
    }

    // Test unsigned body set to true if it was set to true by default (from unsignedPayload trait)
    func testUnsignedBodyIsTrueIfDefaultValueWasTrue() throws {
        // Simulate unsigned body being set to true in auth schemes,
        // e.g., SigV4AuthScheme::customizeSigningProperties
        // before being passed to service speciic setter.
        signingProperties.set(key: SigningPropertyKeys.unsignedBody, value: true)
        let tempCtx = context
            .withServiceName(value: "Glacier")
            .withOperation(value: "filler")
            .build()
        try customSetter.setServiceSpecificSigningProperties(
            signingProperties: &signingProperties, context: tempCtx
        )
        XCTAssertTrue(try XCTUnwrap(signingProperties.get(key: SigningPropertyKeys.unsignedBody)))
    }

    // Test unsigned body set to false if operation name doesn't match
    func testUnsignedBodyIsFalseForUnrelatedOp() throws {
        let tempCtx = context
            .withServiceName(value: "S3")
            .withOperation(value: "filler")
            .withFlowType(value: .PRESIGN_URL)
            .build()
        try customSetter.setServiceSpecificSigningProperties(
            signingProperties: &signingProperties, context: tempCtx
        )
        XCTAssertFalse(try XCTUnwrap(signingProperties.get(key: SigningPropertyKeys.unsignedBody)))
    }

    // Test unsigned body set to false if flow type doesn't match
    func testUnsignedBodyIsFalseForUnrelatedFlow() throws {
        let tempCtx = context
            .withServiceName(value: "S3")
            .withOperation(value: "getObject")
            .withFlowType(value: .PRESIGN_REQUEST)
            .build()
        try customSetter.setServiceSpecificSigningProperties(
            signingProperties: &signingProperties, context: tempCtx
        )
        XCTAssertFalse(try XCTUnwrap(signingProperties.get(key: SigningPropertyKeys.unsignedBody)))
    }

    // Test signedBodyHeader flag set to .contentSha256 for S3
    func testSignedBodyHeaderForS3() throws {
        let tempCtx = context
            .withServiceName(value: "S3")
            .withOperation(value: "filler")
            .build()
        try customSetter.setServiceSpecificSigningProperties(
            signingProperties: &signingProperties, context: tempCtx
        )
        XCTAssertEqual(signingProperties.get(key: SigningPropertyKeys.signedBodyHeader), .contentSha256)
    }

    // Test signedBodyHeader flag set to .contentSha256 for S3 Control
    func testSignedBodyHeaderForS3Control() throws {
        let tempCtx = context
            .withServiceName(value: "S3 Control")
            .withOperation(value: "filler")
            .build()
        try customSetter.setServiceSpecificSigningProperties(
            signingProperties: &signingProperties, context: tempCtx
        )
        XCTAssertEqual(signingProperties.get(key: SigningPropertyKeys.signedBodyHeader), .contentSha256)
    }

    // Test signedBodyHeader flag set to .contentSha256 for Glacier
    func testSignedBodyHeaderForGlacier() throws {
        let tempCtx = context
            .withServiceName(value: "Glacier")
            .withOperation(value: "filler")
            .build()
        try customSetter.setServiceSpecificSigningProperties(
            signingProperties: &signingProperties, context: tempCtx
        )
        XCTAssertEqual(signingProperties.get(key: SigningPropertyKeys.signedBodyHeader), .contentSha256)
    }

    // Test signedBodyHeader flag set to .none if unsignedBody set to true
    func testSignedBodyHeaderForUnsignedBodyContext() throws {
        signingProperties.set(key: SigningPropertyKeys.unsignedBody, value: true)
        let tempCtx = context
            .withServiceName(value: "S3")
            .withOperation(value: "filler")
            .build()
        try customSetter.setServiceSpecificSigningProperties(
            signingProperties: &signingProperties, context: tempCtx
        )
        XCTAssertEqual(signingProperties.get(key: SigningPropertyKeys.signedBodyHeader), AWSSignedBodyHeader.none)
    }

    //MARK: Test S3-Specific Flags

    func testUseDoubleURIEncodeIsFalseForS3() throws{
        let tempCtx = context
            .withServiceName(value: "S3")
            .withOperation(value: "filler")
            .build()
        try customSetter.setServiceSpecificSigningProperties(
            signingProperties: &signingProperties, context: tempCtx
        )
        XCTAssertFalse(try XCTUnwrap(signingProperties.get(key: SigningPropertyKeys.useDoubleURIEncode)))
    }

    func testShouldNormalizeURIPathIsFalseForS3() throws {
        let tempCtx = context
            .withServiceName(value: "S3")
            .withOperation(value: "filler")
            .build()
        try customSetter.setServiceSpecificSigningProperties(
            signingProperties: &signingProperties, context: tempCtx
        )
        XCTAssertFalse(try XCTUnwrap(signingProperties.get(key: SigningPropertyKeys.shouldNormalizeURIPath)))
    }
}
