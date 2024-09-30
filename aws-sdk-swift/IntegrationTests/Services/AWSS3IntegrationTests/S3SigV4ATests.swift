//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Smithy
import AWSSDKHTTPAuth
import XCTest
import AWSS3
import AWSS3Control
import AWSSTS
import ClientRuntime
import AWSClientRuntime

/// Tests SigV4A signing flow using S3's Multi-Region Access Point (MRAP).
class S3SigV4ATests: S3XCTestCase {
    // The custom S3 client configured with only SigV4A auth scheme
    // Used to put object to bucket via MRAP
    private var sigv4aClient: S3Client!
    private var sigv4aConfig: S3Client.S3ClientConfiguration!

    // MRAP ARN format
    // arn:aws:s3::\{account-id}:accesspoint/\{MultiRegionAccessPoint_alias}
    private var mrapArnFormat = "arn:aws:s3::%@:accesspoint/%@"
    private var mrapArn: String!
    private var mrapAlias: String!
    private let mrapNamePrefix = "aws-sdk-s3-integration-test-"
    private let mrapName = "aws-sdk-s3-integration-test-" + UUID().uuidString.split(separator: "-").first!.lowercased()
    private var mrapConfig: S3ControlClientTypes.CreateMultiRegionAccessPointInput!

    // The S3 control client used to create and delete MRAP
    private var s3ControlClient: S3ControlClient!

    // The STS client for fetching AWS account ID
    private var stsClient: STSClient!
    private var accountId: String!

    // Key string used for putting object in tests
    private let key = UUID().uuidString.split(separator: "-").first!.lowercased()

    private let NSEC_PER_SEC = 1_000_000_000

    // MARK: - SETUP & TEARDOWN

    override func setUp() async throws {
        s3ControlClient = try S3ControlClient(region: region)

        // Create sigv4a-only S3 client to be used for tests.
        sigv4aConfig = try await S3Client.S3ClientConfiguration(region: region)
        sigv4aConfig.authSchemes = [SigV4AAuthScheme()]
        sigv4aClient = S3Client(config: sigv4aConfig)

        // Fetch account ID
        stsClient = try STSClient(region: region)
        accountId = try await stsClient.getCallerIdentity(input: GetCallerIdentityInput()).account

        // Save mrapArn without creating new MRAP if it already exists.
        if let preexistingMRAP = try await checkIfMRAPExists(), let alias = preexistingMRAP.alias {
            mrapArn = String(format: mrapArnFormat, accountId, alias)
        } else {
            // Otherwise, create a new MRAP.
            // Create a bucket to be linked to MRAP at construction.
            try await super.setUp()
            // Construct MRAP and save its ARN for use in tests.
            _ = try await constructMRAP()
        }
    }

    override func tearDown() async throws {
        /*
         * Note that MRAP is not deleted to be re-used in subsequent test runs.
         * And because MRAP is not deleted, the bucket associated with it cannot
         * be deleted either, hence the override with no-op.
         */
        // Delete the previously added object from the bucket.
        _ = try await sigv4aClient.deleteObject(input: DeleteObjectInput(
            bucket: mrapArn,
            key: key
        ))
    }

    // MARK: - TEST CASES

    func testS3MRAPSigV4A() async throws {
        // Put an object to bucket via MRAP using SigV4A-only client
        _ = try await sigv4aClient.putObject(input: PutObjectInput(
            body: ByteStream.data(Data()),
            bucket: mrapArn,
            key: key,
            metadata: ["filename": key]
        ))

        // Confirm object has been successfully uploaded via MRAP
        let response = try await sigv4aClient.listObjectsV2(
            input: ListObjectsV2Input(bucket: mrapArn)
        )
        XCTAssertNotNil(response.contents?.first { $0.key == key })
    }

    func testS3MRAPSigV4APresignedRequest() async throws {
        // Construct input
        let putObjectInput = PutObjectInput(
            body: .noStream,
            bucket: mrapArn,
            key: key,
            metadata: ["filename": key]
        )

        // Presign the input with SigV4A (sigv4aConfig has only SigV4A configured)
        let presignedRequest = try await putObjectInput.presign(
            config: sigv4aConfig,
            expiration: 60
        )
        guard let presignedRequest else {
            XCTFail("Presigning PutObjectInput failed.")
            // return added for compiler to not complain.
            return
        }

        // Execute request
        _ = try await sigv4aConfig.httpClientEngine.send(request: presignedRequest)

        // Confirm object has been uploaded via MRAP
        let response = try await sigv4aClient.listObjectsV2(
            input: ListObjectsV2Input(bucket: mrapArn)
        )
        XCTAssertNotNil(response.contents?.first { $0.key == key })
    }

    func testS3MRAPSigV4APresignedURL() async throws {
        // Construct input with bucketName set to mrapArn to send request to MRAP
        let putObjectInput = PutObjectInput(body: .data(Data()), bucket: mrapArn, key: key, metadata: ["filename": key])

        // Get presigned URL using SigV4A (sigv4aConfig has only SigV4A configured)
        let presignedURLOrNil = try await putObjectInput.presignURL(config: sigv4aConfig, expiration: 30.0)
        let presignedURL = try XCTUnwrap(presignedURLOrNil)

        // Construct then send URL request using presigned URL
        var urlRequest = URLRequest(url: presignedURL)
        urlRequest.httpMethod = "PUT"
        urlRequest.httpBody = Data()
        _ = try await perform(urlRequest: urlRequest)

        // Confirm object has been uploaded via MRAP
        let response = try await sigv4aClient.listObjectsV2(
            input: ListObjectsV2Input(bucket: mrapArn)
        )
        XCTAssertNotNil(response.contents?.first { $0.key == key })
    }

    // MARK: - HELPER FUNCTIONS

    // Check if MRAP exists by checking names of existing MRAPs against integ-test MRAP prefix.
    private func checkIfMRAPExists() async throws -> S3ControlClientTypes.MultiRegionAccessPointReport? {
        let mraps = try await s3ControlClient.listMultiRegionAccessPoints(input: ListMultiRegionAccessPointsInput(accountId: accountId)).accessPoints
        return mraps?.first { $0.name?.hasPrefix(mrapNamePrefix) ?? false }
    }

    private func constructMRAPConfig() {
        let publicAccessBlock = S3ControlClientTypes.PublicAccessBlockConfiguration(
            blockPublicAcls: false,
            blockPublicPolicy: false,
            ignorePublicAcls: false,
            restrictPublicBuckets: false
        )
        let regions = [S3ControlClientTypes.Region(bucket: bucketName, bucketAccountId: accountId)]
        mrapConfig = S3ControlClientTypes.CreateMultiRegionAccessPointInput(
            name: mrapName,
            publicAccessBlock: publicAccessBlock,
            regions: regions
        )
    }

    private func constructMRAP() async throws {
        // Construct MRAP config to use
        constructMRAPConfig()
        // Create S3 Multi-Region Access Point (MRAP)
        let createMRAPInput = CreateMultiRegionAccessPointInput(
            accountId: accountId,
            clientToken: UUID().uuidString.split(separator: "-").first!.lowercased(),
            details: mrapConfig
        )
        _ = try await s3ControlClient.createMultiRegionAccessPoint(input: createMRAPInput)

        // Wait until MRAP creation finishes, with max polling count of 20.
        let pollLimit = 20
        var pollCount = 0
        var status: S3ControlClientTypes.MultiRegionAccessPointStatus? = .creating
        repeat {
            let seconds = TimeInterval(20)
            try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))

            status = try await s3ControlClient.getMultiRegionAccessPoint(input: GetMultiRegionAccessPointInput(
                accountId: accountId,
                name: mrapName
            )).accessPoint?.status
            pollCount += 1
        } while status == .creating && pollCount < pollLimit

        // Fetch MRAP alias then format & save MRAP ARN
        // This MRAP ARN is used in place of bucket name in subsequent calls
        mrapAlias = try await s3ControlClient.getMultiRegionAccessPoint(input: GetMultiRegionAccessPointInput(
            accountId: accountId,
            name: mrapName
        )).accessPoint?.alias
        mrapArn = String(format: mrapArnFormat, accountId, mrapAlias)
    }
}
