//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyEventStreamsAPI
import SmithyEventStreams
import XCTest
import ClientRuntime
import class SmithyStreams.BufferedStream

final class AWSMessageDecoderStreamTests: XCTestCase {

    func testIterator() async throws {
        let bufferedStream = BufferedStream(
            data: EventStreamTestData.validMessageDataWithAllHeaders() +
            EventStreamTestData.validMessageDataEmptyPayload() +
            EventStreamTestData.validMessageDataNoHeaders(),
            isClosed: true
        )
        let messageDecoder = DefaultMessageDecoder()
        let sut = DefaultMessageDecoderStream<TestEvent>(
            stream: bufferedStream,
            messageDecoder: messageDecoder,
            unmarshalClosure: TestEvent.unmarshal
        )

        var events: [TestEvent] = []
        for try await evnt in sut {
            events.append(evnt)
        }

        XCTAssertEqual(3, events.count)
        XCTAssertEqual(TestEvent.allHeaders, events[0])
        XCTAssertEqual(TestEvent.emptyPayload, events[1])
        XCTAssertEqual(TestEvent.noHeaders, events[2])
    }
}
