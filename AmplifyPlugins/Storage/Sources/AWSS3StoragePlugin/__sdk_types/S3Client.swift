//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation
import AWSPluginsCore

class S3Client: S3ClientProtocol {
    let configuration: S3ClientConfiguration

    let log = storageLogger

    private func request<Input, Output>(
        action: Action<Input, Output>,
        input: Input,
        headers: [String: String],
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) async throws -> Output {
        log.debug("[\(file)] [\(function)] [\(line)] request entry point")
        log.debug("[\(file)] [\(function)] [\(line)] input: \(input)")

        let requestData = try action.encode(input, configuration.encoder)
        log.debug("[\(file)] [\(function)] [\(line)] requestData size size: \(requestData.count)")

        let url = try action.url(region: configuration.region)
        log.debug("[\(file)] [\(function)] [\(line)] unsigned request url: \(url)")
        let credentials = try await configuration.credentialsProvider.fetchCredentials()

        // TODO: generate user-agent
        let userAgent = "amplify-swift/2.x ua/2.0 api/location#1.0 os/ios#17.0.1 lang/swift#5.8 cfg/retry-mode#legacy"
        log.debug("[\(file)] [\(function)] [\(line)] userAgent: \(userAgent)")

        let signer = SigV4Signer(
            credentials: credentials,
            serviceName: configuration.signingName,
            region: configuration.region
        )

        let signedRequest = signer.sign(
            url: url,
            method: .post,
            body: .data(requestData),
            headers: headers
        )

        log.debug("[\(file)] [\(function)] [\(line)] Signed request URL: \(signedRequest)")
        log.debug("[\(file)] [\(function)] [\(line)] Signed request Headers: \(signedRequest.allHTTPHeaderFields as Any)")
        log.debug("[\(file)] [\(function)] [\(line)] Starting network request")

        let (responseData, urlResponse) = try await URLSession.shared.upload(
            for: signedRequest,
            from: requestData
        )
        log.debug("Completed network request in \(#function) with URLResponse: \(urlResponse)")

        guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
            log.error("""
            Couldn't case from `URLResponse` to `HTTPURLResponse`
            This shouldn't happen. Received URLResponse: \(urlResponse)
            """)
            throw PlaceholderError() // this shouldn't happen
        }

        log.debug("[\(file)] [\(function)] [\(line)] HTTPURLResponse in \(#function): \(httpURLResponse)")
        guard (200..<300).contains(httpURLResponse.statusCode) else {
            log.error("Expected a 2xx status code, received: \(httpURLResponse.statusCode)")
            throw try action.mapError(responseData, httpURLResponse)
        }

        log.debug("[\(file)] [\(function)] [\(line)] Attempting to decode response object in \(#function)")
        let response = try action.decode(responseData, configuration.decoder)
        log.debug("[\(file)] [\(function)] [\(line)] Decoded response in `\(Output.self)`: \(response)")

        return response
    }

    init(configuration: S3ClientConfiguration) {
        self.configuration = configuration
    }

    func deleteObject(input: DeleteObjectInput) async throws -> DeleteObjectOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        let action = Action.deleteObject()
        let headers = input.headers

        return try await request(action: action, input: input, headers: headers)
    }


    func listObjectsV2(input: ListObjectsV2Input) async throws -> ListObjectsV2OutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        let action = Action.listObjectsV2(bucket: input.bucket)
        let headers = input.headers

        return try await request(action: action, input: input, headers: headers)
    }

    func createMultipartUpload(input: CreateMultipartUploadInput) async throws -> CreateMultipartUploadOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        let action = Action.createMultipartUpload(input: input)
        let headers = input.headers

        return try await request(action: action, input: input, headers: headers)
    }


    func listParts(input: ListPartsInput) async throws -> ListPartsOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        let action = Action.listParts(input: input)
        let headers = input.headers

        return try await request(action: action, input: input, headers: headers)
    }


    func completeMultipartUpload(input: CompleteMultipartUploadInput) async throws -> CompleteMultipartUploadOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        let action = Action.completeMultipartUpload(input: input)
        let headers = input.headers

        return try await request(action: action, input: input, headers: headers)
    }


    func abortMultipartUpload(input: AbortMultipartUploadInput) async throws -> AbortMultipartUploadOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        let action = Action.abortMultipartUpload(input: input)
        let headers = input.headers

        return try await request(action: action, input: input, headers: headers)
    }

    func headObject(input: HeadObjectInput) async throws -> HeadObjectOutputResponse {
        log.debug("\(#function) entry point")
        log.debug("\(#function) with input: \(input)")

        let action = Action.headObject(input: input)
        let headers = input.headers

        return try await request(action: action, input: input, headers: headers)
    }
}

protocol S3ClientProtocol {
    func deleteObject(input: DeleteObjectInput) async throws -> DeleteObjectOutputResponse
    func listObjectsV2(input: ListObjectsV2Input) async throws -> ListObjectsV2OutputResponse
    func createMultipartUpload(input: CreateMultipartUploadInput) async throws -> CreateMultipartUploadOutputResponse
    func listParts(input: ListPartsInput) async throws -> ListPartsOutputResponse
    func completeMultipartUpload(input: CompleteMultipartUploadInput) async throws -> CompleteMultipartUploadOutputResponse
    func abortMultipartUpload(input: AbortMultipartUploadInput) async throws -> AbortMultipartUploadOutputResponse
    func headObject(input: HeadObjectInput) async throws -> HeadObjectOutputResponse
}
