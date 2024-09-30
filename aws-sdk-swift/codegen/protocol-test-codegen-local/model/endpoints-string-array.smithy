$version: "2.0"

namespace aws.endpointtests.stringarray

use smithy.rules#endpointRuleSet
use smithy.rules#endpointTests
use smithy.rules#staticContextParams
use smithy.rules#operationContextParams
use aws.api#service
use aws.protocols#restJson1

@endpointRuleSet({
    version: "1.0",
    parameters: {
        stringArrayParam: {
            type: "stringArray",
            required: true,
            default: ["defaultValue1", "defaultValue2"],
            documentation: "docs"
        }
    },
    rules: [
        {
            "documentation": "Template first array value into URI if set",
            "conditions": [
                {
                    "fn": "getAttr",
                    "argv": [
                        {
                            "ref": "stringArrayParam"
                        },
                        "[0]"
                    ],
                    "assign": "arrayValue"
                }
            ],
            "endpoint": {
                "url": "https://example.com/{arrayValue}"
            },
            "type": "endpoint"
        },
        {
            "conditions": [],
            "documentation": "error fallthrough",
            "error": "no array values set",
            "type": "error"
        }
    ]
})
@endpointTests({
    "version": "1.0",
    "testCases": [
        {
            "documentation": "Default array values used"
            "params": {}
            "expect": {
                "endpoint": {
                    "url": "https://example.com/defaultValue1"
                }
            },
            "operationInputs": [
                {
                    "operationName": "NoBindingsOperation",
                }
            ]
        },
        {
            "documentation": "Empty array",
            "params": {
                "stringArrayParam": []
            }
            "expect": {
                "error": "no array values set"
            },
            "operationInputs": [
                {
                    "operationName": "EmptyStaticContextOperation",
                }
            ]
        },
        {
            "documentation": "Static value",
            "params": {
                "stringArrayParam": ["staticValue1"]
            }
            "expect": {
                "endpoint": {
                    "url": "https://example.com/staticValue1"
                }
            },
            "operationInputs": [
                {
                    "operationName": "StaticContextOperation",
                }
            ]
        },
        {
            "documentation": "bound value from input",
            "params": {
                "stringArrayParam": ["key1"]
            }
            "expect": {
                "endpoint": {
                    "url": "https://example.com/key1"
                }
            },
            "operationInputs": [
                {
                    "operationName": "ListOfObjectsOperation",
                    "operationParams": {
                        "nested": {
                            "listOfObjects": [{"key": "key1"}]
                        }
                    },
                },
                {
                    "operationName": "MapOperation",
                    "operationParams": {
                        "map": {
                            "key1": "value1"
                        }
                    }
                }
            ]
        }
    ]
})
@service(sdkId: "EndpointStringArray")
@restJson1
service EndpointStringArray {
    version: "2022-01-01",
    operations: [
        NoBindingsOperation,
        EmptyStaticContextOperation,
        StaticContextOperation,
        ListOfObjectsOperation,
        MapOperation
    ]
}

@http(uri: "/1", method: "POST")
operation NoBindingsOperation {
    input:= {}
}

@staticContextParams(
    "stringArrayParam": {value: []}
)
@http(uri: "/2", method: "POST")
operation EmptyStaticContextOperation {
    input := {}
}

@staticContextParams(
    "stringArrayParam": {value: ["staticValue1"]}
)
@http(uri: "/3", method: "POST")
operation StaticContextOperation {
    input := {}
}

@operationContextParams(
    "stringArrayParam": {path: "nested.listOfObjects[*].key"}
)
@http(uri: "/4", method: "POST")
operation ListOfObjectsOperation {
    input:= {
        nested: Nested
    }
}

@operationContextParams(
    "stringArrayParam": {path: "keys(map)"}
)
@http(uri: "/5", method: "POST")
operation MapOperation {
    input:= {
        map: Map
    }
}

structure Nested {
    listOfObjects: ListOfObjects
}

list ListOfObjects {
    member: ObjectMember
}

structure ObjectMember {
    key: String,
}

map Map {
    key: String,
    value: String
}