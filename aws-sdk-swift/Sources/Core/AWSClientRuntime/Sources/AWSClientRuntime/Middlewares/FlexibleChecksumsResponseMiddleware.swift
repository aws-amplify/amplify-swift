// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import Smithy
import SmithyHTTPAPI
import enum SmithyChecksumsAPI.ChecksumAlgorithm
import enum SmithyChecksums.ChecksumMismatchException
import ClientRuntime

public struct FlexibleChecksumsResponseMiddleware<OperationStackInput, OperationStackOutput> {

    public let id: String = "FlexibleChecksumsResponseMiddleware"

    // The priority to validate response checksums, if multiple are present
    let CHECKSUM_HEADER_VALIDATION_PRIORITY_LIST: [String] = [
        ChecksumAlgorithm.crc32c,
        .crc32,
        .sha1,
        .sha256
    ].sorted().map { $0.toString() }

    let validationMode: Bool
    let priorityList: [String]

    public init(validationMode: Bool, priorityList: [String] = []) {
        self.validationMode = validationMode
        self.priorityList = !priorityList.isEmpty
            ? withPriority(checksums: priorityList)
            : CHECKSUM_HEADER_VALIDATION_PRIORITY_LIST
    }

    private func validateChecksum(response: HTTPResponse, logger: any LogAgent, attributes: Context) async throws {
        // Exit if validation should not be performed
        if !validationMode {
            logger.info("Checksum validation should not be performed! Skipping workflow...")
            return
        }

        let checksumHeaderIsPresent = priorityList.first {
            response.headers.value(for: "x-amz-checksum-\($0)") != nil
        }

        guard let checksumHeader = checksumHeaderIsPresent else {
            let message =
                "User requested checksum validation, but the response headers did not contain any valid checksums"
            logger.warn(message)
            return
        }

        let fullChecksumHeader = "x-amz-checksum-" + checksumHeader

        logger.debug("Validating checksum from \(fullChecksumHeader)")
        attributes.set(key: AttributeKey<String>(name: "ChecksumHeaderValidated"), value: fullChecksumHeader)

        let checksumString = checksumHeader.removePrefix("x-amz-checksum-")
        guard let responseChecksum = ChecksumAlgorithm.from(string: checksumString) else {
            throw ClientError.dataNotFound("Checksum found in header is not supported!")
        }

        guard let expectedChecksum = response.headers.value(for: fullChecksumHeader) else {
            throw ClientError.dataNotFound("Could not determine the expected checksum!")
        }

        // Handle body vs handle stream
        switch response.body {
        case .data(let data):
            guard let data else {
                throw ClientError.dataNotFound("Cannot calculate checksum of empty body!")
            }

            let responseChecksumHasher = responseChecksum.createChecksum()
            try responseChecksumHasher.update(chunk: data)
            let actualChecksum = try responseChecksumHasher.digest().toBase64String()

            guard expectedChecksum == actualChecksum else {
                let message = "Checksum mismatch. Expected \(expectedChecksum) but was \(actualChecksum)"
                throw ChecksumMismatchException.message(message)
            }
        case .stream(let stream):
            let validatingStream = ByteStream.getChecksumValidatingBody(
                stream: stream,
                expectedChecksum: expectedChecksum,
                checksumAlgorithm: responseChecksum
            )

            // Set the response to a validating stream
            attributes.httpResponse = response
            attributes.httpResponse?.body = validatingStream
        case .noStream:
            throw ClientError.dataNotFound("Cannot calculate the checksum of an empty body!")
        }
    }
}

extension FlexibleChecksumsResponseMiddleware: Interceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public func modifyBeforeRetryLoop(context: some MutableRequest<InputType, RequestType>) async throws {
        context.getAttributes().set(key: AttributeKey<String>(name: "ChecksumHeaderValidated"), value: nil)
    }

    public func modifyBeforeDeserialization(
        context: some MutableResponse<InputType, RequestType, ResponseType>
    ) async throws {
        guard let logger = context.getAttributes().getLogger() else {
            throw ClientError.unknownError("No logger found!")
        }

        let response = context.getResponse()
        try await validateChecksum(response: response, logger: logger, attributes: context.getAttributes())
        context.updateResponse(updated: response)
    }
}

private func withPriority(checksums: [String]) -> [String] {
    let checksumsMap = checksums.compactMap { ChecksumAlgorithm.from(string: $0) }
    return checksumsMap.sorted().map { $0.toString() }
}
