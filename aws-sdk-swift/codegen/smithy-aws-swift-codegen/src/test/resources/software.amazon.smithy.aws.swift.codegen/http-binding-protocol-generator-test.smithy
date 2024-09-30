$version: "1.0"
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
        SmokeTest,
        DuplicateInputTest,
        ExplicitString,
        ExplicitBlob,
        ExplicitBlobStream,
        ExplicitStruct,
        ListInput,
        MapInput,
        EnumInput,
        TimestampInput,
        BlobInput
    ]
}

@http(method: "POST", uri: "/smoketest/{label1}/foo")
operation SmokeTest {
    input: SmokeTestRequest,
    output: SmokeTestResponse,
    errors: [SmokeTestError]
}

@http(method: "POST", uri: "/smoketest-duplicate/{label1}/foo")
operation DuplicateInputTest {
    // uses the same input type as another operation. Ensure that we only generate one instance of the serializer
    input: SmokeTestRequest
}

structure SmokeTestRequest {
    @httpHeader("X-Header1")
    header1: String,

    @httpHeader("X-Header2")
    header2: String,

    @httpQuery("Query1")
    query1: String,

    @required
    @httpLabel
    label1: String,

    payload1: String,
    payload2: Integer,
    payload3: Nested
}

structure Nested {
    member1: String,
    member2: String
}

structure SmokeTestResponse {

}

@error("client")
structure SmokeTestError {}


@http(method: "POST", uri: "/explicit/string")
operation ExplicitString {
    input: ExplicitStringRequest
}

structure ExplicitStringRequest {
    @httpPayload
    payload1: String
}

@http(method: "POST", uri: "/explicit/blob")
operation ExplicitBlob {
    input: ExplicitBlobRequest
}

structure ExplicitBlobRequest {
    @httpPayload
    payload1: Blob
}

@streaming
blob BodyStream

@http(method: "POST", uri: "/explicit/blobstream")
operation ExplicitBlobStream {
    input: ExplicitBlobStreamRequest
}

structure ExplicitBlobStreamRequest {
    @httpPayload
    payload1: BodyStream
}

@http(method: "POST", uri: "/explicit/struct")
operation ExplicitStruct {
    input: ExplicitStructRequest
}

structure Nested4 {
    member1: Integer,
    // sanity check, member serialization for non top-level (bound to the operation input) aggregate shapes
    intList: IntList,
    intMap: IntMap
}

structure Nested3 {
    member1: String,
    member2: String,
    member3: Nested4
}

structure Nested2 {
    moreNesting: Nested3
}

structure ExplicitStructRequest {
    @httpPayload
    payload1: Nested2
}

list IntList {
    member: Integer
}

list StructList {
    member: Nested
}

// A list of lists of integers
list NestedIntList {
    member: IntList
}

// A list of enums
list EnumList {
    member: MyEnum
}

list BlobList {
    member: Blob
}

@http(method: "POST", uri: "/input/list")
operation ListInput {
    input: ListInputRequest
}

structure ListInputRequest {
    enumList: EnumList,
    intList: IntList,
    structList: StructList,
    nestedIntList: NestedIntList,
    blobList: BlobList
}

map IntMap {
    key: String,
    value: Integer
}

// only exists as value of a map through MapInputRequest::structMap
structure ReachableOnlyThroughMap {
    prop1: Integer
}

map StructMap {
    key: String,
    value: ReachableOnlyThroughMap
}

map EnumMap {
    key: String,
    value: MyEnum
}

map BlobMap {
    key: String,
    value: Blob
}

@http(method: "POST", uri: "/input/map")
operation MapInput {
    input: MapInputRequest
}

structure MapInputRequest {
    intMap: IntMap,
    structMap: StructMap,
    enumMap: EnumMap,
    blobMap: BlobMap
}


@http(method: "POST", uri: "/input/enum")
operation EnumInput {
    input: EnumInputRequest
}

@enum([
    {
        value: "rawValue1",
        name: "VARIANT1"
    },
    {
        value: "rawValue2",
        name: "VARIANT2"
    }
])
string MyEnum

structure NestedEnum {
    myEnum: MyEnum
}

structure EnumInputRequest {
    nestedWithEnum: NestedEnum,

    @httpHeader("X-EnumHeader")
    enumHeader: MyEnum
}

@http(method: "POST", uri: "/input/timestamp/{tsLabel}")
operation TimestampInput {
    input: TimestampInputRequest
}

list TimestampList {
    member: Timestamp
}

structure TimestampInputRequest {
    // (protocol default)
    normal: Timestamp,

    @timestampFormat("date-time")
    dateTime: Timestamp,

    @timestampFormat("epoch-seconds")
    epochSeconds: Timestamp,

    @timestampFormat("http-date")
    httpDate: Timestamp,

    timestampList: TimestampList,

    @httpHeader("X-Date")
    @timestampFormat("http-date")
    headerHttpDate: Timestamp,

    @httpHeader("X-Epoch")
    @timestampFormat("epoch-seconds")
    headerEpoch: Timestamp,

    @httpQuery("qtime")
    @timestampFormat("date-time")
    queryTimestamp: Timestamp,

    @httpQuery("qtimeList")
    queryTimestampList: TimestampList,

    @required
    @httpLabel
    tsLabel: Timestamp
}

@http(method: "POST", uri: "/input/blob")
operation BlobInput {
    input: BlobInputRequest
}

@mediaType("video/quicktime")
string MyMediaHeader

structure BlobInputRequest {
    // smithy spec doesn't allow blobs for headers but strings with media type are also base64 encoded
    @httpHeader("X-Blob")
    headerMediaType: MyMediaHeader,

    payloadBlob: Blob
}
