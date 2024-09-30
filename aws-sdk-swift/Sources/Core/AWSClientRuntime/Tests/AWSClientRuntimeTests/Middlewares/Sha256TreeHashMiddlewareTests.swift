//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import XCTest
import ClientRuntime
import AwsCommonRuntimeKit
import SmithyTestUtil
@testable import AWSClientRuntime
import class SmithyStreams.BufferedStream

class Sha256TreeHashMiddlewareTests: XCTestCase {

    func testTreeHashAllZeroes() async throws {
        var completed = false
        let context = ContextBuilder().build()
        let bytesIn5_5MB: Int = Int(1024 * 1024 * 5.5)
        let byteArray: [UInt8] = Array(repeating: 0, count: bytesIn5_5MB)
        let byteStream = ByteStream.stream(BufferedStream(data: .init(byteArray), isClosed: true))
        let streamInput = MockStreamInput(body: byteStream)
        var metricsAttributes = Attributes()
        metricsAttributes.set(key: OrchestratorMetricsAttributesKeys.service, value: "Service")
        metricsAttributes.set(key: OrchestratorMetricsAttributesKeys.method, value: "Method")
        let builder = OrchestratorBuilder<MockStreamInput, MockOutput, SmithyHTTPAPI.HTTPRequest, SmithyHTTPAPI.HTTPResponse>()
            .attributes(context)
            .serialize({ input, builder, ctx in
                builder.withBody(input.body)
            })
            .deserialize({ res, ctx in
                return MockOutput()
            })
            .executeRequest({ req, context in
                let linear = context.get(key: AttributeKey<String>(name: "X-Amz-Content-Sha256"))
                XCTAssertEqual(linear, "733cf513448ce6b20ad1bc5e50eb27c06aefae0c320713a5dd99f4e51bc1ca60")
                let treeHash = req.headers.value(for: "X-Amz-Sha256-Tree-Hash")
                XCTAssertEqual(treeHash, "a3a82dbe3644dd6046be472f2e3ec1f8ef47f8f3adb86d0de4de7a254f255455")
                completed = true
                return HTTPResponse(body: .noStream, statusCode: .accepted)
            })
            .telemetry(OrchestratorTelemetry(telemetryProvider: DefaultTelemetry.provider, metricsAttributes: metricsAttributes))
            .selectAuthScheme(SelectNoAuthScheme())
        builder.interceptors.add(Sha256TreeHashMiddleware<MockStreamInput, MockOutput>())
        _ = try await builder.build().execute(input: streamInput)
        XCTAssertTrue(completed)
    }
}
