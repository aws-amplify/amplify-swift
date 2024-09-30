$version: "1.0"

namespace aws.protocoltests.json10

use aws.api#service
use aws.protocols#awsJson1_0
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Json10 Protocol")
@awsJson1_0
service AwsJson10 {
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

operation GreetingWithErrors {
    output: GreetingWithErrorsOutput,
    errors: [InvalidGreeting, ComplexError]
}

structure GreetingWithErrorsOutput {
    greeting: String,
}

@error("client")
structure InvalidGreeting {
    Message: String,
}

@error("client")
structure ComplexError {
    TopLevel: String,

    Nested: ComplexNestedErrorData,
}

structure ComplexNestedErrorData {
    Foo: String,
}