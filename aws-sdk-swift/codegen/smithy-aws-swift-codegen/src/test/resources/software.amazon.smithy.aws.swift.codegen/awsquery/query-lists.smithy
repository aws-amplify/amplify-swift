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
        QueryLists
    ]
}

operation QueryLists {
    input: QueryListsInput
}

structure QueryListsInput {
    ListArg: StringList,
    ComplexListArg: GreetingList,

    @xmlFlattened
    FlattenedListArg: StringList,

    tsList: TimestampList,

    @xmlFlattened
    flatTsList: TimestampList,

    ListArgWithXmlNameMember: ListWithXmlName,

    // Notice that the xmlName on the targeted list member is ignored.
    @xmlFlattened
    @xmlName("Hi")
    FlattenedListArgWithXmlName: ListWithXmlName,
}

list StringList {
    member: String,
}

structure GreetingStruct {
    hi: String,
}
list GreetingList {
    member: GreetingStruct
}

list ListWithXmlName {
    @xmlName("item")
    member: String
}


list TimestampList {
    @timestampFormat("epoch-seconds")
    member: Timestamp
}