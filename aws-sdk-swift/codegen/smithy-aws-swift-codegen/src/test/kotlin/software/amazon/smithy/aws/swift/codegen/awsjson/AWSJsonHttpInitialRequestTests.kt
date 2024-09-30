package software.amazon.smithy.aws.swift.codegen.awsjson

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.TestContext
import software.amazon.smithy.aws.swift.codegen.TestUtils
import software.amazon.smithy.aws.swift.codegen.protocols.awsjson.AWSJSON1_0ProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.shouldSyntacticSanityCheck
import software.amazon.smithy.aws.traits.protocols.AwsJson1_0Trait

class AWSJsonHttpInitialRequestTests {
    @Test
    fun `001 Conformance to MessageMarshallable gets generated correctly`() {
        val context = setupTests(
            "awsjson/initial-request.smithy",
            "com.test#InitialRequestTest"
        )
        val contents = TestUtils.getFileContents(
            context.manifest,
            "Sources/Example/models/TestStream+MessageMarshallable.swift"
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension InitialRequestTestClientTypes.TestStream {
    static var marshal: SmithyEventStreamsAPI.MarshalClosure<InitialRequestTestClientTypes.TestStream> {
        { (self) in
            var headers: [SmithyEventStreamsAPI.Header] = [.init(name: ":message-type", value: .string("event"))]
            var payload: Foundation.Data? = nil
            switch self {
            case .messagewithstring(let value):
                headers.append(.init(name: ":event-type", value: .string("MessageWithString")))
                headers.append(.init(name: ":content-type", value: .string("text/plain")))
                payload = value.data?.data(using: .utf8)
            case .sdkUnknown(_):
                throw Smithy.ClientError.unknownError("cannot serialize the unknown event type!")
            }
            return SmithyEventStreamsAPI.Message(headers: headers, payload: payload ?? .init())
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 EventStreamBodyMiddleware gets generated into operation stack with initialRequestMessage`() {
        val context = setupTests(
            "awsjson/initial-request.smithy",
            "com.test#InitialRequestTest"
        )
        val contents = TestUtils.getFileContents(
            context.manifest,
            "Sources/Example/InitialRequestTestClient.swift"
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
        builder.serialize(ClientRuntime.EventStreamBodyMiddleware<EventStreamOpInput, EventStreamOpOutput, InitialRequestTestClientTypes.TestStream>(keyPath: \.eventStream, defaultBody: "{}", marshalClosure: InitialRequestTestClientTypes.TestStream.marshal, initialRequestMessage: try input.makeInitialRequestMessage()))
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 Encodable conformance is generated for input struct with streaming union member with streaming member excluded`() {
        val context = setupTests(
            "awsjson/initial-request.smithy",
            "com.test#InitialRequestTest"
        )
        val contents = TestUtils.getFileContents(
            context.manifest,
            "Sources/Example/models/EventStreamOpInput+Write.swift"
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension EventStreamOpInput {

    static func write(value: EventStreamOpInput?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["inputMember1"].write(value.inputMember1)
        try writer["inputMember2"].write(value.inputMember2)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 makeInitialRequestMessage method gets generated for input struct in extension`() {
        val context = setupTests(
            "awsjson/initial-request.smithy",
            "com.test#InitialRequestTest"
        )
        val contents = TestUtils.getFileContents(
            context.manifest,
            "Sources/Example/models/EventStreamOpInput+MakeInitialRequestMessage.swift"
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension EventStreamOpInput {
    func makeInitialRequestMessage() throws -> SmithyEventStreamsAPI.Message {
        let writer = SmithyJSON.Writer(nodeInfo: "")
        try writer.write(self, with: EventStreamOpInput.write(value:to:))
        let initialRequestPayload = try writer.data()
        let initialRequestMessage = SmithyEventStreamsAPI.Message(
            headers: [
                SmithyEventStreamsAPI.Header(name: ":message-type", value: .string("event")),
                SmithyEventStreamsAPI.Header(name: ":event-type", value: .string("initial-request")),
                SmithyEventStreamsAPI.Header(name: ":content-type", value: .string("application/x-amz-json-1.0"))
            ],
            payload: initialRequestPayload
        )
        return initialRequestMessage
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestUtils.executeDirectedCodegen(smithyFile, serviceShapeId, AwsJson1_0Trait.ID)
        AWSJSON1_0ProtocolGenerator().run {
            generateMessageMarshallable(context.ctx)
            generateSerializers(context.ctx)
            initializeMiddleware(context.ctx)
            generateProtocolClient(context.ctx)
        }
        context.ctx.delegator.flushWriters()
        return context
    }
}
