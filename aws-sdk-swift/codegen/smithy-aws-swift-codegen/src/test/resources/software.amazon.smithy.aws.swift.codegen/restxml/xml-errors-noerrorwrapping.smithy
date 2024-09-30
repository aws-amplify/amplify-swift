$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml errors")
@restXml(noErrorWrapping: true)
service RestXml {
    version: "2019-12-16",
    operations: [
        GreetingWithErrorsNoErrorWrapping,
    ]
}

@idempotent
@http(uri: "/GreetingWithErrorsNoErrorWrapping", method: "PUT")
operation GreetingWithErrorsNoErrorWrapping {
    output: GreetingWithErrorsOutput,
    errors: [ComplexXMLErrorNoErrorWrapping]
}

structure GreetingWithErrorsOutput {
    @httpHeader("X-Greeting")
    greeting: String,
}

@error("client")
@httpError(403)
structure ComplexXMLErrorNoErrorWrapping {
    // Errors support HTTP bindings!
    @httpHeader("X-Header")
    Header: String,

    TopLevel: String,

    Nested: ComplexXMLNestedErrorData,
}

structure ComplexXMLNestedErrorData {
    Foo: String,
}