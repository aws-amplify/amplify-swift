//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyHTTPAuth
import SmithyHTTPAuthAPI
import AWSSDKHTTPAuth
import XCTest
import Smithy

class SigV4AuthSchemeTests: XCTestCase {
    private var contextBuilder: ContextBuilder!
    private var sigV4AuthScheme: AWSSDKHTTPAuth.SigV4AuthScheme!

    override func setUp() async throws {
        try await super.setUp()
        contextBuilder = ContextBuilder()
            .withSigningName(value: "TestSigningName")
            .withSigningRegion(value: "TestSigningRegion")
        sigV4AuthScheme = SigV4AuthScheme()
    }

    // AttributeKeys.bidirectionalStreaming flag

    func testBidirectionalStreamingIsTrueWhenTrueInContext() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: true)
            .withServiceName(value: "filler")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertTrue(try XCTUnwrap(updatedProperties.get(key: SigningPropertyKeys.bidirectionalStreaming)))
    }

    func testBidirectionalStreamingIsFalseWhenFalseInContext() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "filler")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertFalse(try XCTUnwrap(updatedProperties.get(key: SigningPropertyKeys.bidirectionalStreaming)))
    }

    // AttributeKeys.signingName flag

    func testSigningNameIsCopiedCorrectly() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "filler")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertEqual("TestSigningName", updatedProperties.get(key: SigningPropertyKeys.signingName))
    }

    // AttributeKeys.signingRegion flag

    func testSigningRegionIsCopiedCorrectly() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "filler")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertEqual("TestSigningRegion", updatedProperties.get(key: SigningPropertyKeys.signingRegion))
    }

    // AttributeKeys.expiration flag

    func testExpirationValueIsZeroWhenNotSetInContext() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "filler")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertEqual(0, updatedProperties.get(key: SigningPropertyKeys.expiration))
    }

    func testExpirationValueIsCopiedCorrectlyFromContext() throws {
        let context = contextBuilder
            .withExpiration(value: 12345)
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "filler")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertEqual(12345, updatedProperties.get(key: SigningPropertyKeys.expiration))
    }

    // AttributeKeys.signatureType flag

    func testSignatureTypeForPresignURLFlowIsRequestQueryParams() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "filler")
            .withFlowType(value: .PRESIGN_URL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertEqual(AWSSignatureType.requestQueryParams, updatedProperties.get(key: SigningPropertyKeys.signatureType))
    }

    func testSignatureTypeForNormalFlowIsRequestHeaders() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "filler")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertEqual(AWSSignatureType.requestHeaders, updatedProperties.get(key: SigningPropertyKeys.signatureType))
    }

    func testSignatureTypeForPresignRequestFlowIsRequestHeaders() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "filler")
            .withFlowType(value: .PRESIGN_REQUEST)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertEqual(AWSSignatureType.requestHeaders, updatedProperties.get(key: SigningPropertyKeys.signatureType))
    }

    // AttributeKeys.unsignedBody flag

    func testUnsignedBodyIsFalseWhenUnsignedPayloadTraitFlagAndForceUnsignedBodyFlagAreBothFalse() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "filler")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertFalse(try XCTUnwrap(updatedProperties.get(key: SigningPropertyKeys.unsignedBody)))
    }

    func testUnsignedBodyIsTrueWhenUnsignedPayloadTraitFlagIsFalseAndShouldForceUnsignedBodyIsTrue() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "filler")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: true)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertTrue(try XCTUnwrap(updatedProperties.get(key: SigningPropertyKeys.unsignedBody)))
    }

    func testUnsignedBodyIsTrueWhenUnsignedPayloadTraitFlagIsTrueAndShouldForceUnsignedBodyIsFalse() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "S3")
            .withFlowType(value: .PRESIGN_URL)
            .withOperation(value: "getObject")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertTrue(try XCTUnwrap(updatedProperties.get(key: SigningPropertyKeys.unsignedBody)))
    }

    // AttributeKeys.signedBodyHeader flag

    func testUseSignedBodyHeaderWhenServiceIsS3AndUseUnsignedBodyIsFalse() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "S3")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertEqual(updatedProperties.get(key: SigningPropertyKeys.signedBodyHeader), .contentSha256)
    }

    func testUseSignedBodyHeaderWhenServiceIsGlacierAndUseUnsignedBodyIsFalse() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "Glacier")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertEqual(updatedProperties.get(key: SigningPropertyKeys.signedBodyHeader), .contentSha256)
    }

    func testUseSignedBodyHeaderWhenServiceIsS3ControlAndUseUnsignedBodyIsFalse() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "S3 Control")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertEqual(updatedProperties.get(key: SigningPropertyKeys.signedBodyHeader), .contentSha256)
    }

    func testDontUseSignedBodyHeaderWhenUseUnsignedBodyIsTrue() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "S3")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: true)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertEqual(AWSSignedBodyHeader.none, updatedProperties.get(key: SigningPropertyKeys.signedBodyHeader))
    }

    // S3-specific customizations

    // AttributeKeys.useDoubleURIEncode flag

    func testUseDoubleURIEncodeIsFalseWhenServiceIsS3() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "S3")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertFalse(try XCTUnwrap(updatedProperties.get(key: SigningPropertyKeys.useDoubleURIEncode)))
    }

    func testUseDoubleURIEncodeIsTrueWhenServiceIsntS3() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "NonS3")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertTrue(try XCTUnwrap(updatedProperties.get(key: SigningPropertyKeys.useDoubleURIEncode)))
    }

    // AttributeKeys.shouldNormalizeURIPath flag

    func testShouldNormalizeURIPathIsFalseWhenServiceIsS3() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "S3")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertFalse(try XCTUnwrap(updatedProperties.get(key: SigningPropertyKeys.shouldNormalizeURIPath)))
    }

    func testShouldNormalizeURIPathIsTrueWhenServiceIsntS3() throws {
        let context = contextBuilder
            .withBidirectionalStreamingEnabled(value: false)
            .withServiceName(value: "NonS3")
            .withFlowType(value: .NORMAL)
            .withOperation(value: "filler")
            .withUnsignedPayloadTrait(value: false)
            .build()
        let updatedProperties = try sigV4AuthScheme.customizeSigningProperties(signingProperties: Attributes(), context: context)
        XCTAssertTrue(try XCTUnwrap(updatedProperties.get(key: SigningPropertyKeys.shouldNormalizeURIPath)))
    }
}
