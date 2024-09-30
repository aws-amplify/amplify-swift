$version: "1.0"

namespace aws.protocoltests.restjson1

use aws.api#service
use aws.protocols#restJson1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Json 1 Protocol")
@restJson1
service RestJson1 {
    version: "2023-09-08",
    operations: [
        GreetingWithErrors,
    ]
    errors: [ExampleServiceError]
}

@error("client")
@httpError(403)
structure ExampleServiceError {
    Message: String,
}

@http(method: "GET", uri: "/test", code: 200)
operation GreetingWithErrors {
    output: GreetingWithErrorsOutput,
    errors: [InvalidGreeting, ComplexError]
}

structure GreetingWithErrorsOutput {
    greeting: String,
}

@error("client")
@httpError(404)
structure InvalidGreeting {
    Message: String,
}

@error("client")
@httpError(405)
structure ComplexError {
    TopLevel: String,

    Nested: ComplexNestedErrorData,
}

structure ComplexNestedErrorData {
    Foo: String,
}