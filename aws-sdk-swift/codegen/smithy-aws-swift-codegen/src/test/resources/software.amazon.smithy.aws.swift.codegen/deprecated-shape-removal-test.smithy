$version: "2.0"
namespace com.test

use aws.api#service
use aws.protocols#restJson1
use aws.auth#sigv4

@service(sdkId: "Example")
@restJson1
@sigv4(name: "Example")
service Example {
    version: "1.0.0",
    operations: [
        OperationWithDeprecatedInputMembers
    ]
}

@http(method: "POST", uri: "/foo")
operation OperationWithDeprecatedInputMembers {
    input: InputWithDeprecatedMembers
}

structure InputWithDeprecatedMembers {
    @deprecated(since: "2024-09-01")
    deprecatedMemberWithCorrectlyFormedSinceField: String

    @deprecated(since: "2024-10-01")
    deprecatedMemberWithCorrectlyFormedSinceFieldButDeprecatedAfterCutoff: String

    @deprecated(since: "4.2.0")
    deprecatedMemberWithMalformedSinceField: String

    @deprecated
    deprecatedMemberWithoutSinceField: String
}
