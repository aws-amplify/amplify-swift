namespace com.amazonaws.s3

use aws.protocols#restXml
use aws.auth#sigv4
use aws.api#service
@trait(selector: "*")

structure presignable { }

@restXml
@sigv4(name: "s3")
@service(sdkId: "S3")
service AmazonS3 {
    version: "1.0.0",
    operations: [PutObject, GetObject]
}

@presignable
@idempotent
@http(method: "PUT", uri: "/foo")
operation PutObject {
    input: PutObjectInput
}

structure PutObjectInput {
    payload: String
}

@presignable
@readonly
@http(method: "GET", uri: "/foo")
operation GetObject {
    input: GetObjectInput
}

structure GetObjectInput { }
