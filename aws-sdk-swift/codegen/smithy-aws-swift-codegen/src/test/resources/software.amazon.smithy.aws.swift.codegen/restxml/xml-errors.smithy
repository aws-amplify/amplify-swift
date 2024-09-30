$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml errors")
@restXml
service RestXml {
    version: "2019-12-16",
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

@idempotent
@http(uri: "/GreetingWithErrors", method: "PUT")
operation GreetingWithErrors {
    output: GreetingWithErrorsOutput,
    errors: [InvalidGreeting, ComplexXMLError]
}

structure GreetingWithErrorsOutput {
    @httpHeader("X-Greeting")
    greeting: String,
}

@error("client")
@httpError(400)
structure InvalidGreeting {
    Message: String,
}

@error("client")
@httpError(403)
structure ComplexXMLError {
    // Errors support HTTP bindings!
    @httpHeader("X-Header")
    Header: String,

    TopLevel: String,

    Nested: ComplexXMLNestedErrorData,
}

structure ComplexXMLNestedErrorData {
    Foo: String,
}