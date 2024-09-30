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
        BlobInputParams
    ]
}

operation BlobInputParams {
    input: BlobInputParamsInput
}

structure BlobInputParamsInput {
    BlobMember: Blob,
    BlobMap: BlobMap,
    BlobList: BlobList,
    @xmlFlattened
    BlobListFlattened: BlobList,

    @xmlFlattened
    BlobMapFlattened: BlobMap,
}

list BlobList {
    member: Blob,
}

map BlobMap {
    key: String,
    value: Blob,
}
