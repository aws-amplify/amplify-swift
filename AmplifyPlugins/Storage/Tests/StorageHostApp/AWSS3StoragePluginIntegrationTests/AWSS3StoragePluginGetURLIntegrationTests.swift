//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify

import AWSClientRuntime
import AWSS3
import AWSS3StoragePlugin
import ClientRuntime
import CryptoKit
import XCTest

class AWSS3StoragePluginGetURLIntegrationTests: AWSS3StoragePluginTestBase {

    /// Given: An object in storage
    /// When: Call the getURL API
    /// Then: The operation completes successfully with the URL retrieved
    func testGetRemoteURL() async throws {
        let key = "public/" + UUID().uuidString
        try await uploadData(key: key, dataString: key)
        await wait {
            _ = try await Amplify.Storage.uploadData(
                path: .fromString(key),
                data: Data(key.utf8),
                options: .init()
            ).value
        }

        let remoteURL = try await Amplify.Storage.getURL(path: .fromString(key))

        // The presigned URL generation does not result in an SDK or HTTP call.
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method}, [])

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
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method}, [])
        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, [])
    }

    // MARK: - PUT Pre-Signed URL Tests

    /// - Given: A new key that does not yet exist in S3
    /// - When: A PUT pre-signed URL is generated, data is uploaded via URLSession, then a GET pre-signed URL is used to download
    /// - Then: The PUT upload succeeds with HTTP 200, and the downloaded data matches what was uploaded
    func testGetPutPresignedURL() async throws {
        let key = "public/" + UUID().uuidString
        let uploadContent = "test-upload-content-\(UUID().uuidString)"
        let uploadData = Data(uploadContent.utf8)

        // Generate a PUT pre-signed URL
        let putURL = try await Amplify.Storage.getURL(
            path: .fromString(key),
            options: .init(
                pluginOptions: AWSStorageGetURLOptions(method: .put)
            )
        )
        XCTAssertNotNil(putURL)

        // Upload data using URLSession with the PUT pre-signed URL
        var putRequest = URLRequest(url: putURL)
        putRequest.httpMethod = "PUT"
        putRequest.httpBody = uploadData

        let (_, putResponse) = try await URLSession.shared.data(for: putRequest)
        let putHttpResponse = try XCTUnwrap(putResponse as? HTTPURLResponse)
        XCTAssertEqual(putHttpResponse.statusCode, 200)

        // Verify the upload by downloading via a GET pre-signed URL
        let getURL = try await Amplify.Storage.getURL(path: .fromString(key))
        let (downloadedData, getResponse) = try await URLSession.shared.data(from: getURL)
        let getHttpResponse = try XCTUnwrap(getResponse as? HTTPURLResponse)
        XCTAssertEqual(getHttpResponse.statusCode, 200)

        let downloadedString = try XCTUnwrap(String(data: downloadedData, encoding: .utf8))
        XCTAssertEqual(downloadedString, uploadContent)

        // Clean up
        _ = try await Amplify.Storage.remove(path: .fromString(key))
    }

    /// - Given: A new key that does not yet exist in S3
    /// - When: A PUT pre-signed URL is generated with contentType="application/json", and JSON data is uploaded
    /// - Then: The PUT upload succeeds with HTTP 200
    func testGetPutPresignedURLWithContentType() async throws {
        let key = "public/" + UUID().uuidString
        let jsonContent = "{\"test\": \"value\", \"id\": \"\(UUID().uuidString)\"}"
        let jsonData = Data(jsonContent.utf8)

        // Generate a PUT pre-signed URL with content type
        let putURL = try await Amplify.Storage.getURL(
            path: .fromString(key),
            options: .init(
                pluginOptions: AWSStorageGetURLOptions(
                    method: .put,
                    contentType: "application/json"
                )
            )
        )
        XCTAssertNotNil(putURL)

        // Upload JSON data using URLSession with the matching content type
        var putRequest = URLRequest(url: putURL)
        putRequest.httpMethod = "PUT"
        putRequest.httpBody = jsonData
        putRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, putResponse) = try await URLSession.shared.data(for: putRequest)
        let putHttpResponse = try XCTUnwrap(putResponse as? HTTPURLResponse)
        XCTAssertEqual(putHttpResponse.statusCode, 200)

        // Verify the upload by downloading
        let getURL = try await Amplify.Storage.getURL(path: .fromString(key))
        let (downloadedData, getResponse) = try await URLSession.shared.data(from: getURL)
        let getHttpResponse = try XCTUnwrap(getResponse as? HTTPURLResponse)
        XCTAssertEqual(getHttpResponse.statusCode, 200)

        let downloadedString = try XCTUnwrap(String(data: downloadedData, encoding: .utf8))
        XCTAssertEqual(downloadedString, jsonContent)

        // Clean up
        _ = try await Amplify.Storage.remove(path: .fromString(key))
    }

    /// - Given: A key for a non-existent S3 object
    /// - When: A PUT pre-signed URL is requested with validateObjectExistence=true
    /// - Then: The URL is returned successfully without throwing (existence check is skipped for PUT)
    func testGetPutPresignedURLSkipsObjectExistenceValidation() async throws {
        let unknownKey = "public/" + UUID().uuidString

        // This should NOT throw even though the object doesn't exist,
        // because validateObjectExistence is skipped for PUT method
        let putURL = try await Amplify.Storage.getURL(
            path: .fromString(unknownKey),
            options: .init(
                pluginOptions: AWSStorageGetURLOptions(
                    validateObjectExistence: true,
                    method: .put
                )
            )
        )
        XCTAssertNotNil(putURL)

        // No HeadObject SDK call should be made for PUT URLs
        XCTAssertTrue(
            requestRecorder.sdkRequests.filter { $0.method == .head }.isEmpty,
            "Expected no HeadObject calls for PUT pre-signed URL generation"
        )
    }

    /// - Given: An object in storage
    /// - When: getURL is called without specifying a method
    /// - Then: A GET pre-signed URL is returned (backward compatibility), and the object can be downloaded
    func testGetPutPresignedURLDefaultsToGet() async throws {
        let key = "public/" + UUID().uuidString
        try await uploadData(key: key, dataString: key)
        await wait {
            _ = try await Amplify.Storage.uploadData(
                path: .fromString(key),
                data: Data(key.utf8),
                options: .init()
            ).value
        }

        // Call getURL without specifying method — should default to GET
        let url = try await Amplify.Storage.getURL(
            path: .fromString(key),
            options: .init(
                pluginOptions: AWSStorageGetURLOptions(validateObjectExistence: false)
            )
        )

        // Verify it's a working GET URL by downloading the object
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(httpResponse.statusCode, 200)

        let dataString = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(dataString, key)

        // Clean up
        _ = try await Amplify.Storage.remove(path: .fromString(key))
    }
}
