$version: "1.0"

namespace aws.protocoltests.ec2

use aws.api#service
use aws.protocols#ec2Query
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

/// An EC2 query service that sends query requests and XML responses.
@service(sdkId: "EC2 Protocol")
@ec2Query
@xmlNamespace(uri: "https://example.com/")
service AwsEc2 {
    version: "2020-01-08",
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