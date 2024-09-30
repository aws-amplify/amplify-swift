//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyIdentityAPI
import Foundation
import XCTest
import AWSS3
import AWSClientRuntime
import SmithyIdentity

class S3ErrorTests: S3XCTestCase {

    func test_noSuchKey_throwsNoSuchKeyWhenUnknownKeyIsUsed() async throws {
        do {
            let input = GetObjectInput(bucket: bucketName, key: UUID().uuidString)
            _ = try await client.getObject(input: input)
            XCTFail("Request should not have succeeded")
        } catch let error as NoSuchKey {
            XCTAssertEqual(error.httpResponse.statusCode, .notFound)
            XCTAssertEqual(error.message, "The specified key does not exist.")
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

    func test_noSuchBucket_throwsNoSuchBucketWhenUnknownBucketIsUsed() async throws {
        do {
            let input = ListObjectsV2Input(bucket: bucketName + "x")
            _ = try await client.listObjectsV2(input: input)
            XCTFail("Request should not have succeeded")
        } catch let error as NoSuchBucket {
            XCTAssertEqual(error.httpResponse.statusCode, .notFound)
            XCTAssertEqual(error.message, "The specified bucket does not exist")
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

    func test_requestID_hasARequestIDAndRequestID2() async throws {
        do {
            let input = GetObjectInput(bucket: bucketName, key: UUID().uuidString)
            _ = try await client.getObject(input: input)
            XCTFail("Request should not have succeeded")
        } catch let error as NoSuchKey {
            let requestID = try XCTUnwrap(error.requestID)
            let requestID2 = try XCTUnwrap(error.requestID2)
            XCTAssertFalse(requestID.isEmpty)
            XCTAssertFalse(requestID2.isEmpty)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

    func test_InvalidObjectState_hasReadableProperties() async throws {
        do {
            let key = UUID().uuidString + ".txt"
            let putInput = PutObjectInput(bucket: bucketName, key: key, storageClass: .glacier)
            _ = try await client.putObject(input: putInput)
            let getInput = GetObjectInput(bucket: bucketName, key: key)
            _ = try await client.getObject(input: getInput)
            XCTFail("Request should not have succeeded")
        } catch let error as InvalidObjectState {
            XCTAssertEqual(error.properties.accessTier, nil)
            XCTAssertEqual(error.properties.storageClass, .glacier)
            XCTAssertEqual(error.message, "The operation is not valid for the object\'s storage class")
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

    func test_InvalidAccessKeyID_isThrownWhenAppropriate() async throws {
        do {
            let credentials = AWSCredentialIdentity(accessKey: "AKIDEXAMPLE", secret: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY")
            let awsCredentialIdentityResolver = try StaticAWSCredentialIdentityResolver(credentials)
            let config = try await S3Client.S3ClientConfiguration(awsCredentialIdentityResolver: awsCredentialIdentityResolver, region: region)
            let input = GetObjectInput(bucket: bucketName, key: UUID().uuidString)
            _ = try await S3Client(config: config).getObject(input: input)
            XCTFail("Request should not have succeeded")
        } catch let error as InvalidAccessKeyId {
            XCTAssertEqual(error.httpResponse.statusCode, .forbidden)
            XCTAssertEqual(error.message, "The AWS Access Key Id you provided does not exist in our records.")
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
}
