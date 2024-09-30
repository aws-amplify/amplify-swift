// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import class Smithy.Context
import AwsCCal
import AwsCommonRuntimeKit
import ClientRuntime
import SmithyHTTPAPI
import struct Foundation.Data
import struct Smithy.AttributeKey

public struct Sha256TreeHashMiddleware<OperationStackInput, OperationStackOutput> {
    public let id: String = "Sha256TreeHash"

    private let X_AMZ_SHA256_TREE_HASH_HEADER_NAME = "X-Amz-Sha256-Tree-Hash"

    private let X_AMZ_CONTENT_SHA256_HEADER_NAME = "X-Amz-Content-Sha256"

    public init() {}

    private func addHashes(
        request: SmithyHTTPAPI.HTTPRequest,
        builder: SmithyHTTPAPI.HTTPRequestBuilder,
        context: Context
    ) async throws {
        switch request.body {
        case .data:
            break
        case .stream(let stream):
            let streamBytes: Data?
            let currentPosition = stream.position
            if stream.isSeekable {
                streamBytes = try await stream.readToEndAsync()
                try stream.seek(toOffset: currentPosition)
            } else {
                // If the stream is not seekable, we need to cache the stream in memory
                // so we can compute the hash and still be able to send the stream to the service.
                // This is not ideal, but it is the best we can do.
                streamBytes = try await stream.readToEndAsync()
                builder.withBody(.data(streamBytes))
            }
            guard let streamBytes = streamBytes, !streamBytes.isEmpty else {
                return
            }
            let (linearHash, treeHash) = try computeHashes(data: streamBytes)
            if let treeHash = treeHash, let linearHash = linearHash {
                builder.withHeader(name: X_AMZ_SHA256_TREE_HASH_HEADER_NAME, value: treeHash)
                // provide the value but let CRT add the SHA256 header during signing
                context.attributes.set(key: AttributeKey(name: X_AMZ_CONTENT_SHA256_HEADER_NAME), value: linearHash)
            }
        case .noStream:
            break
        }
    }

    /// Computes the tree-hash and linear hash of Data.
    /// See http://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html for more information.
    private func computeHashes(data: Data) throws -> (String?, String?) {
        let ONE_MB = 1024 * 1024
        let hashes: [[UInt8]] = try data.chunked(size: ONE_MB).map { try $0.computeSHA256().bytes() }
        return try (data.computeSHA256().encodeToHexString(), computeTreeHash(hashes: hashes))
    }

    /// Builds a tree hash root node given a slice of hashes. Glacier tree hash to be derived from SHA256 hashes
    /// of 1MB chunks of the data.
    /// See http://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html
    /// for more information.
    private func computeTreeHash(hashes: [[UInt8]]) throws -> String? {
        guard !hashes.isEmpty else {
            return nil
        }
        var previousLevelHashes = hashes
        while previousLevelHashes.count > 1 {
            var currentLevelHashes = [[UInt8]]()
            for index in stride(from: 0, to: previousLevelHashes.count, by: 2) {
                if previousLevelHashes.count - index > 1 {
                    var concatenatedLevelHash = [UInt8]()
                    concatenatedLevelHash.append(contentsOf: previousLevelHashes[index])
                    concatenatedLevelHash.append(contentsOf: previousLevelHashes[index + 1])
                    let data = Data(concatenatedLevelHash)
                    currentLevelHashes.append(try data.computeSHA256().bytes())

                } else {
                    currentLevelHashes.append(previousLevelHashes[index])
                }
            }
            previousLevelHashes = currentLevelHashes
        }

        let data = Data(previousLevelHashes[0])
        return data.encodeToHexString()
    }
}

extension Sha256TreeHashMiddleware: Interceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput
    public typealias RequestType = SmithyHTTPAPI.HTTPRequest
    public typealias ResponseType = HTTPResponse

    public func modifyBeforeSigning(context: some MutableRequest<Self.InputType, Self.RequestType>) async throws {
        let request = context.getRequest()
        let builder = request.toBuilder()
        try await addHashes(request: request, builder: builder, context: context.getAttributes())
        context.updateRequest(updated: builder.build())
    }
}
