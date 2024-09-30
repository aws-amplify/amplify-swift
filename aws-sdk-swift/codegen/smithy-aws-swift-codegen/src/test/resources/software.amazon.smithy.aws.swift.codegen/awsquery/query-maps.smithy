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
        QueryMaps
    ]
}

operation QueryMaps {
    input: QueryMapsInput
}

structure QueryMapsInput {
    MapArg: StringMap,

    @xmlName("Foo")
    RenamedMapArg: StringMap,

    ComplexMapArg: ComplexMap,

    MapWithXmlMemberName: MapWithXmlName,

    @xmlFlattened
    FlattenedMap: StringMap,

    @xmlFlattened
    @xmlName("Hi")
    FlattenedMapWithXmlName: MapWithXmlName,

    MapOfLists: MapOfLists,
}

map StringMap {
    key: String,
    value: String,
}

map ComplexMap {
    key: String,
    value: GreetingStruct,
}
structure GreetingStruct {
    hi: String,
}

map MapWithXmlName {
    @xmlName("K")
    key: String,

    @xmlName("V")
    value: String
}

map MapOfLists {
    key: String,
    value: StringList,
}

list StringList {
    member: String,
}