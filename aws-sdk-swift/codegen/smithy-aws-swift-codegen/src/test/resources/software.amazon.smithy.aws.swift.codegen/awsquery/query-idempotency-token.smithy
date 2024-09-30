$version: "1.0"

namespace aws.protocoltests.query

use aws.api#service
use aws.protocols#awsQuery
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Query Protocol")
@awsQuery
@xmlNamespace(uri: "https://example.com/")
service AwsQuery {
    version: "2020-01-08",
    operations: [
        QueryIdempotencyTokenAutoFill
    ]
}

@tags(["client-only"])
operation QueryIdempotencyTokenAutoFill {
    input: QueryIdempotencyTokenAutoFillInput
}

structure QueryIdempotencyTokenAutoFillInput {
    @idempotencyToken
    token: String,
}
