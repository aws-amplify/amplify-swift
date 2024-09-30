namespace com.test

use aws.protocols#awsJson1_0
use aws.api#service
use aws.auth#sigv4

@awsJson1_0
@sigv4(name: "initial-request-test")
@service(sdkId: "InitialRequestTest")
service InitialRequestTest {
    version: "03-04-2024",
    operations: [EventStreamOp]
}

operation EventStreamOp {
    input: StructureWithStream,
    output: FillerStructure,
    errors: [SomeError]
}

structure StructureWithStream {
    @required
    eventStream: TestStream
    inputMember1: String
    inputMember2: String
}

structure FillerStructure {
    fillerMessage: String
}

@error("client")
structure SomeError {
    Message: String,
}

structure MessageWithString { @eventPayload data: String }

@streaming
union TestStream {
    MessageWithString: MessageWithString,
    SomeError: SomeError,
}