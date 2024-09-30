$version: "2.0"

namespace aws.flex.checks

use aws.api#service
use aws.protocols#httpChecksum
use aws.protocols#restJson1

@restJson1
@service(sdkId: "ChecksumTests")
service ChecksumTests {
    version: "1.0.0",
    operations: [SomeOperation]
}

// Define the operation
@httpChecksum(
    requestChecksumRequired: true,
    requestAlgorithmMember: "checksumAlgorithm",
    requestValidationModeMember: "validationMode",
    responseAlgorithms: ["CRC32C", "CRC32", "SHA1", "SHA256"]
)
@http(method: "POST", uri: "/foo")
operation SomeOperation {
    input: PutSomethingInput
    output: PutSomethingOutput
}

structure PutSomethingInput {
    @httpHeader("x-amz-request-algorithm")
    checksumAlgorithm: ChecksumAlgorithm

    @httpHeader("x-amz-response-validation-mode")
    validationMode: ValidationMode

    @httpPayload
    content: Blob
}

structure PutSomethingOutput {
    foo: String
}

enum ChecksumAlgorithm {
    CRC32C
    CRC32
    SHA1
    SHA256
}

enum ValidationMode {
    ENABLED
}
