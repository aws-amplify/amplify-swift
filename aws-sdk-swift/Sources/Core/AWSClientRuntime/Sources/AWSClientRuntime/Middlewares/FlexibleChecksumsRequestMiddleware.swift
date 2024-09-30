//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum SmithyChecksumsAPI.ChecksumAlgorithm
import enum SmithyChecksums.ChecksumMismatchException
import enum Smithy.ClientError
import class Smithy.Context
import AwsCommonRuntimeKit
import AWSSDKChecksums
import ClientRuntime
import SmithyHTTPAPI

public struct FlexibleChecksumsRequestMiddleware<OperationStackInput, OperationStackOutput> {

    public let id: String = "FlexibleChecksumsRequestMiddleware"

    let checksumAlgorithm: String?

    public init(checksumAlgorithm: String?) {
        self.checksumAlgorithm = checksumAlgorithm
    }

    private func addHeaders(builder: HTTPRequestBuilder, attributes: Context) async throws {
        if case(.stream(let stream)) = builder.body {
            attributes.isChunkedEligibleStream = stream.isEligibleForChunkedStreaming
            if stream.isEligibleForChunkedStreaming {
                try builder.setAwsChunkedHeaders() // x-amz-decoded-content-length
            }
        }

        // Initialize logger
        guard let logger = attributes.getLogger() else {
            throw ClientError.unknownError("No logger found!")
        }

        guard let checksumString = checksumAlgorithm else {
            logger.info("No checksum provided! Skipping flexible checksums workflow...")
            return
        }

        guard let checksumHashFunction = ChecksumAlgorithm.from(string: checksumString) else {
            logger.info("Found no supported checksums! Skipping flexible checksums workflow...")
            return
        }

        // Determine the header name
        let headerName = "x-amz-checksum-\(checksumHashFunction)"
        logger.debug("Resolved checksum header name: \(headerName)")

        // Check if any checksum header is already provided by the user
        let checksumHeaderPrefix = "x-amz-checksum-"
        if builder.headers.headers.contains(where: {
            $0.name.lowercased().starts(with: checksumHeaderPrefix) &&
            $0.name.lowercased() != "x-amz-checksum-algorithm"
        }) {
            logger.debug("Checksum header already provided by the user. Skipping calculation.")
            return
        }

        // Handle body vs handle stream
        switch builder.body {
        case .data(let data):
            guard let data else {
                throw ClientError.dataNotFound("Cannot calculate checksum of empty body!")
            }

            if builder.headers.value(for: headerName) == nil {
                logger.debug("Calculating checksum")
            }

            // Create checksum instance
            let checksum = checksumHashFunction.createChecksum()

            // Pass data to hash
            try checksum.update(chunk: data)

            // Retrieve the hash
            let hash = try checksum.digest().toBase64String()

            builder.updateHeader(name: headerName, value: [hash])
        case .stream:
            // Will handle calculating checksum and setting header later
            attributes.checksum = checksumHashFunction
            builder.updateHeader(name: "x-amz-trailer", value: [headerName])
        case .noStream:
            throw ClientError.dataNotFound("Cannot calculate the checksum of an empty body!")
        }
    }
}

extension FlexibleChecksumsRequestMiddleware: Interceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput
    public typealias RequestType = SmithyHTTPAPI.HTTPRequest
    public typealias ResponseType = HTTPResponse

    public func modifyBeforeRetryLoop(context: some MutableRequest<InputType, RequestType>) async throws {
        let builder = context.getRequest().toBuilder()
        try await addHeaders(builder: builder, attributes: context.getAttributes())
        context.updateRequest(updated: builder.build())
    }
}
