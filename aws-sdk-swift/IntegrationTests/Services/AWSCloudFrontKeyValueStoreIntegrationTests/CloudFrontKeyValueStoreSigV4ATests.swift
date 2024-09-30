//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSSDKHTTPAuth
import XCTest
import ClientRuntime
import AWSClientRuntime
import AWSCloudFront
import AWSCloudFrontKeyValueStore

/// Tests SigV4a signing flow using CloudFrontKeyValueStore.
class CloudFrontKeyValueStoreSigV4ATests: XCTestCase {
    // The CloudFront client to create / delete key value store (KVS)
    private var client: CloudFrontClient!
    // The sig4a-only KVS client to call CloudFrontKeyValueStore::listKeys
    private var kvsClient: CloudFrontKeyValueStoreClient!
    private var kvsConfig: CloudFrontKeyValueStoreClient.CloudFrontKeyValueStoreClientConfiguration!
    // Region to use for clients
    private let region = "us-east-1"

    // Temporary name of the KVS to use for the test
    private let kvsName = "sigv4a-test-kvs-" + UUID().uuidString.split(separator: "-").first!.lowercased()

    // The Etag to use to call CloudFront::deletKeyValueStore
    private var cfEtag: String!
    // The Etag to use to call CloudFrontKeyValueStore::putKey
    private var cfKvsEtag: String!

    // The ARN of the KVS
    private var kvsArn: String!
    // String status of the KVS while it's being created
    private let wipStatus = "PROVISIONING"

    // Key-value pair to pass into CloudFrontKeyValueStore::putKey
    private let key = "kvs-sigv4a-integration-test"
    private let value = "{}"

    private let NSEC_PER_SEC = 1_000_000_000

    override func setUp() async throws {
        // Initialize CloudFront client
        client = try CloudFrontClient(region: region)
        // Initiailize KVS client with only SigV4A enabled
        kvsConfig = try await CloudFrontKeyValueStoreClient.CloudFrontKeyValueStoreClientConfiguration(region: region)
        kvsConfig.authSchemes = [SigV4AAuthScheme()]
        kvsClient = CloudFrontKeyValueStoreClient(config: kvsConfig)

        // Create a key value store (KVS) and save its ARN
        kvsArn = try await client.createKeyValueStore(input: CreateKeyValueStoreInput(name: kvsName)).keyValueStore?.arn

        // Wait until KVS is provisioned & ready
        var status: String? = wipStatus
        repeat {
            status = try await client.describeKeyValueStore(input: DescribeKeyValueStoreInput(name: kvsName)).keyValueStore?.status
            let seconds = 2.5
            try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
        } while status == wipStatus

        // Fetch Etag of the KVS that was just created for both CF and CFKVS clients
        cfEtag = try await client.describeKeyValueStore(input: DescribeKeyValueStoreInput(name: kvsName)).eTag
        cfKvsEtag = try await kvsClient.describeKeyValueStore(input: DescribeKeyValueStoreInput(kvsARN: kvsArn)).eTag
    }

    override func tearDown() async throws {
        // Delete the key value store
        _ = try await client.deleteKeyValueStore(input: DeleteKeyValueStoreInput(
            ifMatch: cfEtag,
            name: kvsName
        ))
    }

    func testKeyValueStoreSigV4A() async throws {
        // Put a dummy key onto KVS
        _ = try await kvsClient.putKey(input: PutKeyInput(
            ifMatch: cfKvsEtag,
            key: key,
            kvsARN: kvsArn,
            value: value
        ))
        // Confirm that the key was uploaded successfully using SigV4A signing flow
        let keys = try await kvsClient.listKeys(input: ListKeysInput(kvsARN: kvsArn))
        let items = try XCTUnwrap(keys.items)
        XCTAssertEqual(items[0].key, key)
        XCTAssertEqual(items[0].value, value)
    }
}
