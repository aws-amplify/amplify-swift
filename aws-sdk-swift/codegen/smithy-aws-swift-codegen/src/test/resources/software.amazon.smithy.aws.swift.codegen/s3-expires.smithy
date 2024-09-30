$version: "1.0"
namespace com.amazonaws.s3

use aws.api#service
use aws.protocols#restJson1
use aws.auth#sigv4

@service(sdkId: "S3")
@restJson1
service S3 {
    version: "1.0.0",
    operations: [
        Foo
    ]
}

@http(method: "POST", uri: "/foo")
operation Foo {
    input: FooInput
    output: FooOutput
}

structure FooInput {
    payload1: String,
    Expires: Timestamp
}

structure FooOutput {
    payload1: String,
    Expires: Timestamp
}

@service(sdkId: "Bar")
@restJson1
service Bar {
    version: "1.0.0",
    operations: [
        Foo
    ]
}