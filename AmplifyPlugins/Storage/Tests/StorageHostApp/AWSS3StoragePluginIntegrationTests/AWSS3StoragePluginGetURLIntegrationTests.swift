//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify

import AWSS3StoragePlugin
import ClientRuntime
import AWSClientRuntime
import CryptoKit
import XCTest
import AWSS3

class AWSS3StoragePluginGetURLIntegrationTests: AWSS3StoragePluginTestBase {

    /// Given: An object in storage
    /// When: Call the getURL API
    /// Then: The operation completes successfully with the URL retrieved
    func testGetRemoteURL() async throws {
        let key = "public/" + UUID().uuidString
        try await uploadData(key: key, dataString: key)
        _ = try await Amplify.Storage.uploadData(
            path: .fromString(key),
            data: Data(key.utf8),
            options: .init()
        ).value

        let remoteURL = try await Amplify.Storage.getURL(path: .fromString(key))

        // The presigned URL generation does not result in an SDK or HTTP call.
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method} , [])

        let (data, response) = try await URLSession.shared.data(from: remoteURL)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(httpResponse.statusCode, 200)

        let dataString = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(dataString, key)

        _ = try await Amplify.Storage.remove(path: .fromString(key))
    }

    /// - Given: A key for a non-existent S3 object
    /// - When: A pre-signed URL is requested for that key with `validateObjectExistence = true`
    /// - Then: A StorageError.keyNotFound error is thrown
    func testGetURLForUnknownKeyWithValidation() async throws {
        let unknownKey = "public/" + UUID().uuidString
        do {
            let url = try await Amplify.Storage.getURL(
                path: .fromString(unknownKey),
                options: .init(
                    pluginOptions: AWSStorageGetURLOptions(validateObjectExistence: true)
                )
            )
            XCTFail("Expecting failure but got url: \(url)")
        } catch StorageError.keyNotFound(let key, _, _, _) {
            XCTAssertTrue(key.contains(unknownKey))
        }

        // A S3 HeadObject call is expected
        XCTAssert(requestRecorder.sdkRequests.map(\.method).allSatisfy { $0 == .head })

        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, [])
    }

    /// - Given: A key for a non-existent S3 object
    /// - When: A pre-signed URL is requested for that key with `validateObjectExistence = false`
    /// - Then: A pre-signed URL is returned
    func testGetURLForUnknownKeyWithoutValidation() async throws {
        let unknownKey = UUID().uuidString
        let url = try await Amplify.Storage.getURL(
            path: .fromString(unknownKey),
            options: .init(
                pluginOptions: AWSStorageGetURLOptions(validateObjectExistence: false)
            )
        )
        XCTAssertNotNil(url)

        // No SDK or URLRequest calls expected
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method} , [])
        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, [])
    }
}
