$version: "1.0"

namespace com.test

use aws.api#service
use aws.protocols#awsJson1_0
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Example")
@awsJson1_0
service JsonRpc10 {
    version: "2020-07-14",
    operations: [
        // Basic input and output tests
        NoInputAndNoOutput,
        NoInputAndOutput,
        EmptyInputAndEmptyOutput,
        // Errors
        GreetingWithErrors,
    ]
}

operation NoInputAndNoOutput {}

apply NoInputAndNoOutput @httpRequestTests([
    {
        id: "AwsJson10NoInputAndNoOutput",
        documentation: "No input serializes no payload",
        protocol: awsJson1_0,
        method: "POST",
        headers: {
            "Content-Type": "application/x-amz-json-1.0",
            "X-Amz-Target": "JsonRpc10.NoInputAndNoOutput",
        },
        uri: "/",
    }
])

apply NoInputAndNoOutput @httpResponseTests([
   {
        id: "AwsJson10NoInputAndNoOutput",
        documentation: "No output serializes no payload",
        protocol: awsJson1_0,
        headers: {
            "Content-Type": "application/x-amz-json-1.0",
        },
        code: 200,
   }
])

/// The example tests how requests and responses are serialized when there's
/// no request or response payload because the operation has no input and the
/// output is empty. While this should be rare, code generators must support
/// this.
operation NoInputAndOutput {
    output: NoInputAndOutputOutput
}

apply NoInputAndOutput @httpRequestTests([
    {
        id: "AwsJson10NoInputAndOutput",
        documentation: "No input serializes no payload",
        protocol: awsJson1_0,
        method: "POST",
        headers: {
            "Content-Type": "application/x-amz-json-1.0",
            "X-Amz-Target": "JsonRpc10.NoInputAndOutput",
        },
        uri: "/"
    }
])

apply NoInputAndOutput @httpResponseTests([
    {
        id: "AwsJson10NoInputAndOutput",
        documentation: "Empty output serializes no payload",
        protocol: awsJson1_0,
        headers: {
            "Content-Type": "application/x-amz-json-1.0"
        },
        code: 200
    }
])

structure NoInputAndOutputOutput {}

/// The example tests how requests and responses are serialized when there's
/// no request or response payload because the operation has an empty input
/// and empty output structure that reuses the same shape. While this should
/// be rare, code generators must support this.
operation EmptyInputAndEmptyOutput {
    input: EmptyInputAndEmptyOutputInput,
    output: EmptyInputAndEmptyOutputInput
}

apply EmptyInputAndEmptyOutput @httpRequestTests([
    {
        id: "AwsJson10EmptyInputAndEmptyOutput",
        documentation: "Empty input serializes no payload",
        protocol: awsJson1_0,
        method: "POST",
        uri: "/",
        body: "",
        headers: {
            "Content-Type": "application/x-amz-json-1.0",
            "X-Amz-Target": "JsonRpc10.EmptyInputAndEmptyOutput",
        },
        bodyMediaType: "application/json"
    },
])

apply EmptyInputAndEmptyOutput @httpResponseTests([
    {
        id: "AwsJson10EmptyInputAndEmptyOutput",
        documentation: "Empty output serializes no payload",
        protocol: awsJson1_0,
        code: 200,
        body: "",
        headers: {"Content-Type": "application/x-amz-json-1.0"},
        bodyMediaType: "application/json"
    },
    {
        id: "AwsJson10EmptyInputAndEmptyJsonObjectOutput",
        documentation: "Empty output serializes no payload",
        protocol: awsJson1_0,
        code: 200,
        body: "{}",
        headers: {"Content-Type": "application/x-amz-json-1.0"},
        bodyMediaType: "application/json"
    },
])

structure EmptyInputAndEmptyOutputInput {}

@idempotent
operation GreetingWithErrors {
    output: GreetingWithErrorsOutput,
    errors: [InvalidGreeting, ComplexError, FooError]
}

structure GreetingWithErrorsOutput {
    greeting: String,
}

/// This error is thrown when an invalid greeting value is provided.
@error("client")
structure InvalidGreeting {
    Message: String,
}

apply InvalidGreeting @httpResponseTests([
    {
        id: "AwsJson10InvalidGreetingError",
        documentation: "Parses simple JSON errors",
        protocol: awsJson1_0,
        params: {
            Message: "Hi"
        },
        code: 400,
        headers: {
            "Content-Type": "application/x-amz-json-1.0"
        },
        body: """
              {
                  "__type": "aws.protocoltests.json10#InvalidGreeting",
                  "Message": "Hi"
              }""",
        bodyMediaType: "application/json",
    },
])

/// This error is thrown when a request is invalid.
@error("client")
structure ComplexError {
    TopLevel: String,
    Nested: ComplexNestedErrorData,
}

structure ComplexNestedErrorData {
    @jsonName("Fooooo")
    Foo: String,
}

apply ComplexError @httpResponseTests([
    {
        id: "AwsJson10ComplexError",
        documentation: "Parses a complex error with no message member",
        protocol: awsJson1_0,
        params: {
            TopLevel: "Top level",
            Nested: {
                Foo: "bar"
            }
        },
        code: 400,
        headers: {
            "Content-Type": "application/x-amz-json-1.0"
        },
        body: """
              {
                  "__type": "aws.protocoltests.json10#ComplexError",
                  "TopLevel": "Top level",
                  "Nested": {
                      "Fooooo": "bar"
                  }
              }""",
        bodyMediaType: "application/json",
    },
    {
        id: "AwsJson10EmptyComplexError",
        documentation: "Parses a complex error with an empty body",
        protocol: awsJson1_0,
        code: 400,
        headers: {
            "Content-Type": "application/x-amz-json-1.0"
        },
        body: """
              {
                  "__type": "aws.protocoltests.json10#ComplexError"
              }""",
        bodyMediaType: "application/json"
    },
])

/// This error has test cases that test some of the dark corners of Amazon service
/// framework history. It should only be implemented by clients.
@error("server")
@tags(["client-only"])
structure FooError {}

apply FooError @httpResponseTests([
    {
        id: "AwsJson10FooErrorUsingXAmznErrorType",
        documentation: "Serializes the X-Amzn-ErrorType header. For an example service, see Amazon EKS.",
        protocol: awsJson1_0,
        code: 500,
        headers: {
            "X-Amzn-Errortype": "FooError",
        },
    },
    {
        id: "AwsJson10FooErrorUsingXAmznErrorTypeWithUri",
        documentation: """
            Some X-Amzn-Errortype headers contain URLs. Clients need to split the URL on ':' and take \
            only the first half of the string. For example, 'ValidationException:http://internal.amazon.com/coral/com.amazon.coral.validate/'
            is to be interpreted as 'ValidationException'.

            For an example service see Amazon Polly.""",
        protocol: awsJson1_0,
        code: 500,
        headers: {
            "X-Amzn-Errortype": "FooError:http://internal.amazon.com/coral/com.amazon.coral.validate/",
        },
    },
    {
        id: "AwsJson10FooErrorUsingXAmznErrorTypeWithUriAndNamespace",
        documentation: """
                     X-Amzn-Errortype might contain a URL and a namespace. Client should extract only the shape \
                     name. This is a pathalogical case that might not actually happen in any deployed AWS service.""",
        protocol: awsJson1_0,
        code: 500,
        headers: {
            "X-Amzn-Errortype": "aws.protocoltests.json10#FooError:http://internal.amazon.com/coral/com.amazon.coral.validate/",
        },
    },
    {
        id: "AwsJson10FooErrorUsingCode",
        documentation: """
                     This example uses the 'code' property in the output rather than X-Amzn-Errortype. Some \
                     services do this though it's preferable to send the X-Amzn-Errortype. Client implementations \
                     must first check for the X-Amzn-Errortype and then check for a top-level 'code' property.

                     For example service see Amazon S3 Glacier.""",
        protocol: awsJson1_0,
        code: 500,
        headers: {
            "Content-Type": "application/x-amz-json-1.0"
        },
        body: """
              {
                  "code": "FooError"
              }""",
        bodyMediaType: "application/json",
    },
    {
        id: "AwsJson10FooErrorUsingCodeAndNamespace",
        documentation: """
                     Some services serialize errors using code, and it might contain a namespace. \
                     Clients should just take the last part of the string after '#'.""",
        protocol: awsJson1_0,
        code: 500,
        headers: {
            "Content-Type": "application/x-amz-json-1.0"
        },
        body: """
              {
                  "code": "aws.protocoltests.json10#FooError"
              }""",
        bodyMediaType: "application/json",
    },
    {
        id: "AwsJson10FooErrorUsingCodeUriAndNamespace",
        documentation: """
                     Some services serialize errors using code, and it might contain a namespace. It also might \
                     contain a URI. Clients should just take the last part of the string after '#' and before ":". \
                     This is a pathalogical case that might not occur in any deployed AWS service.""",
        protocol: awsJson1_0,
        code: 500,
        headers: {
            "Content-Type": "application/x-amz-json-1.0"
        },
        body: """
              {
                  "code": "aws.protocoltests.json10#FooError:http://internal.amazon.com/coral/com.amazon.coral.validate/"
              }""",
        bodyMediaType: "application/json",
    },
    {
        id: "AwsJson10FooErrorWithDunderType",
        documentation: "Some services serialize errors using __type.",
        protocol: awsJson1_0,
        code: 500,
        headers: {
            "Content-Type": "application/x-amz-json-1.0"
        },
        body: """
              {
                  "__type": "FooError"
              }""",
        bodyMediaType: "application/json",
    },
    {
        id: "AwsJson10FooErrorWithDunderTypeAndNamespace",
        documentation: """
                     Some services serialize errors using __type, and it might contain a namespace. \
                     Clients should just take the last part of the string after '#'.""",
        protocol: awsJson1_0,
        code: 500,
        headers: {
            "Content-Type": "application/x-amz-json-1.0"
        },
        body: """
              {
                  "__type": "aws.protocoltests.json10#FooError"
              }""",
        bodyMediaType: "application/json",
    },
    {
        id: "AwsJson10FooErrorWithDunderTypeUriAndNamespace",
        documentation: """
                     Some services serialize errors using __type, and it might contain a namespace. It also might \
                     contain a URI. Clients should just take the last part of the string after '#' and before ":". \
                     This is a pathalogical case that might not occur in any deployed AWS service.""",
        protocol: awsJson1_0,
        code: 500,
        headers: {
            "Content-Type": "application/x-amz-json-1.0"
        },
        body: """
              {
                  "__type": "aws.protocoltests.json10#FooError:http://internal.amazon.com/coral/com.amazon.coral.validate/"
              }""",
        bodyMediaType: "application/json",
    }
])