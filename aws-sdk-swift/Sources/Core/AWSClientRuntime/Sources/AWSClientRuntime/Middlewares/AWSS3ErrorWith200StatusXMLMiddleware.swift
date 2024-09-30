//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.ByteStream
import class Smithy.Context
import ClientRuntime
import SmithyHTTPAPI
@_spi(SmithyReadWrite) import SmithyXML
import struct Foundation.Data
import SmithyStreams

public struct AWSS3ErrorWith200StatusXMLMiddleware<OperationStackInput, OperationStackOutput> {
    public let id: String = "AWSS3ErrorWith200StatusXMLMiddleware"
    private let errorStatusCode: HTTPStatusCode = .internalServerError

    public init() {}

    private func isRootErrorElement(data: Data) throws -> Bool {
        let reader = try Reader.from(data: data)

        // Check if there's an "Error" node at the root of the XML response
        return reader.nodeInfo.name == "Error"
    }
}

extension AWSS3ErrorWith200StatusXMLMiddleware: Interceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public func modifyBeforeDeserialization(
        context: some MutableResponse<Self.InputType, Self.RequestType, Self.ResponseType>
    ) async throws {
        let response = context.getResponse()

        // Check if the status code is OK (200)
        guard response.statusCode == .ok else {
            return
        }

        guard let data = try await response.body.readData() else {
            return
        }

        let statusCode = try isRootErrorElement(data: data) ? errorStatusCode : response.statusCode

        // For event streams the body needs to be copied as buffered streams are non-seekable
        let updatedBody = response.body.copy(data: data)

        let updatedResponse = response.copy(
            body: updatedBody,
            statusCode: statusCode
        )

        context.updateResponse(updated: updatedResponse)
    }
}

extension ByteStream {

    // Copy an existing ByteStream, optionally with new data
    public func copy(data: Data?) -> ByteStream {
        switch self {
        case .data(let existingData):
            return .data(data ?? existingData)
        case .stream(let existingStream):
            return .stream(data != nil ? BufferedStream(data: data, isClosed: true) : existingStream)
        case .noStream:
            return .noStream
        }
    }
}
