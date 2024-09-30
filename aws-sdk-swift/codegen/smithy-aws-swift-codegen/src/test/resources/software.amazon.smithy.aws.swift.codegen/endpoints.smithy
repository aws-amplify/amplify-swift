$version: "1.0"

namespace smithy.example

use aws.api#service
use aws.protocols#restJson1
use smithy.rules#clientContextParams
use smithy.rules#staticContextParams
use smithy.rules#contextParam
use smithy.rules#operationContextParams
use smithy.rules#endpointRuleSet

@restJson1
@clientContextParams(
    stringFoo: {type: "string", documentation: "a client string parameter"},
    boolFoo: {type: "boolean", documentation: "a client boolean parameter"},
)
@service(
    sdkId: "Json Protocol",
    arnNamespace: "jsonprotocol",
    cloudFormationName: "JsonProtocol",
    cloudTrailEventSource: "jsonprotocol.amazonaws.com",
)
service ExampleService {
    version: "2022-01-01",
    operations: [GetThing]
}

apply ExampleService @endpointRuleSet({
    version: "1.0",
    parameters: {
        stringFoo: {type: "string"},
        stringBar: {type: "string"},
        stringBaz: {type: "string"},
        endpoint: {type: "string", builtIn: "SDK::Endpoint"},
        boolFoo: {type: "boolean", required: true},
        boolBar: {type: "boolean"},
        boolBaz: {type: "string"},
        stringArrayBar: {type: "stringArray"},
        region: {type: "string", builtIn: "AWS::Region", required: true},
        subfield: {type: "string"},
        wildcardProjectionArray: {type: "stringArray"},
        keysFunctionArray: {type: "stringArray"},
        flattenedArray: {type: "stringArray"}
    },
    rules: []
})

@readonly
@staticContextParams(
    stringBar: {value: "some value"},
    boolBar: {value: true}
    stringArrayBar: {value: ["five", "six", "seven"]}
)
@operationContextParams(
    subfield: {
        path: "bar.subfield.subfield2"
    }
    wildcardProjectionArray: {
        path: "bar.objects[*].id"
    }
    keysFunctionArray: {
        path: "keys(bar.mapping)"
    }
    flattenedArray: {
        path: "bar.objects[].content"
    }
)
@http(method: "POST", uri: "/endpointtest/getthing")
operation GetThing {
    input: GetThingInput
}

@input
structure GetThingInput {
    fizz: String,

    @contextParam(name: "stringBaz")
    buzz: String

    @contextParam(name: "boolBaz")
    fuzz: String

    bar: NestedContainer
}

structure NestedContainer {
    subfield: NestedSubfield
    objects: ObjectIdentifierList
    mapping: ObjectIdentifierMap
}

structure NestedSubfield {
    subfield2: String
}

list ObjectIdentifierList {
    member: ObjectIdentifier
}

structure ObjectIdentifier {
    id: String
    content: String
}

map ObjectIdentifierMap {
    key: String
    value: Integer
}