namespace com.test

use aws.protocols#restXml
use aws.api#service
use aws.auth#sigv4

@restXml
@sigv4(name: "event-stream-test")
@service(sdkId: "EventStreamTest")
service EventStreamTest {
    version: "03-04-2024",
    operations: [EventStreamOp]
}

@http(method: "PUT", uri: "/test", code: 200)
operation EventStreamOp {
    input: StructureWithStream,
    output: StructureWithStream
    errors: [SomeError]
}

structure StructureWithStream {
    @required
    @httpPayload
    eventStream: TestEvents

    @httpHeader("inputHeader1")
    inputMember1: String

    @httpHeader("inputHeader2")
    inputMember2: String
}

@error("client")
structure SomeError {
    Message: String,
}

structure MessageWithString { @eventPayload data: String }
structure MessageWithAudio {
    @eventHeader
    exampleHeader: String

    @eventPayload
    audio: Audio
}
structure Audio {
    rawAudio: rawData
}

blob rawData

@streaming
union TestEvents {
    MessageEvent: MessageWithString,
    AudioEvent: MessageWithAudio,
    SomeError: SomeError,
}