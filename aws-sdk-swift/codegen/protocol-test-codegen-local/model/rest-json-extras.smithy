$version: "1.0"

namespace aws.protocoltests.restjson

use aws.protocols#restJson1
use aws.api#service
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

apply QueryPrecedence @httpRequestTests([
    {
        id: "UrlParamsKeyEncoding",
        documentation: "Keys and values must be url encoded",
        protocol: restJson1,
        method: "POST",
        uri: "/Precedence",
        body: "",
        queryParams: ["bar=%26%F0%9F%90%B1", "hello%20there=how%27s%20your%20encoding%3F", "a%20%26%20b%20%26%20c=better%20encode%20%3D%20this"],
        params: {
            foo: "&🐱",
            baz: {
                "hello there": "how's your encoding?",
                "a & b & c": "better encode = this"
            }
        },
        appliesTo: "client",
    },
    {
        id: "RestJsonQueryPrecedenceForbid",
        documentation: "Prefer named query parameters when serializing",
        protocol: restJson1,
        method: "POST",
        uri: "/Precedence",
        body: "",
        queryParams: [
            "bar=named",
            "qux=alsoFromMap"
        ],
        forbidQueryParams: ["bar=fromMap"],
        params: {
            foo: "named",
            baz: {
                bar: "fromMap",
                qux: "alsoFromMap"
            }
        },
        appliesTo: "client",
    }]
)

/// A REST JSON service that sends JSON requests and responses.
@service(sdkId: "Rest Json Protocol")
@restJson1
service RestJsonExtras {
    version: "2019-12-16",
    operations: [EnumPayload, StringPayload, PrimitiveIntHeader, EnumQuery, CreateNestedMap, CreateNestedSparseMap]
}

@http(uri: "/EnumPayload", method: "POST")
@httpRequestTests([
    {
        id: "EnumPayload",
        uri: "/EnumPayload",
        body: "enumvalue",
        params: { payload: "enumvalue" },
        method: "POST",
        protocol: "aws.protocols#restJson1"
    }
])
operation EnumPayload {
    input: EnumPayloadInput,
    output: EnumPayloadInput
}

structure EnumPayloadInput {
    @httpPayload
    payload: StringEnum
}

@http(uri: "/StringPayload", method: "POST")
@httpRequestTests([
    {
        id: "StringPayload",
        uri: "/StringPayload",
        body: "rawstring",
        params: { payload: "rawstring" },
        method: "POST",
        protocol: "aws.protocols#restJson1"
    }
])
operation StringPayload {
    input: StringPayloadInput,
    output: StringPayloadInput
}

structure StringPayloadInput {
    @httpPayload
    payload: String
}

@httpResponseTests([
    {
        id: "DeserPrimitiveHeader",
        protocol: "aws.protocols#restJson1",
        code: 200,
        headers: { "x-field": "123" },
        params: { field: 123 }
    }
])
@http(uri: "/primitive", method: "POST")
operation PrimitiveIntHeader {
    output: PrimitiveIntHeaderInput
}

integer PrimitiveInt

structure PrimitiveIntHeaderInput {
    @httpHeader("x-field")
    @required
    field: PrimitiveInt
}

@http(uri: "/foo/{enum}", method: "GET")
@httpRequestTests([
    {
        id: "EnumQueryRequest",
        uri: "/foo/enumvalue",
        params: { enum: "enumvalue" },
        method: "GET",
        protocol: "aws.protocols#restJson1"
    }
])
operation EnumQuery {
    input: EnumQueryInput
}

structure EnumQueryInput {
    @httpLabel
    @required
    enum: StringEnum
}

// Request & response tests for nested maps & lists.
@http(uri: "/create_nested_map", method: "POST")
@httpRequestTests([
    {
        id: "request_nested_map"
        protocol: restJson1
        method: "POST"
        host: "example.com"
        uri: "/create_nested_map"
        body: "{\"nestedMaps\":{\"a\":{\"b\":[\"x\",\"y\",\"z\"]}}}"
        bodyMediaType: "application/json"
        params: {
            "nestedMaps": {
                "a": {
                    "b": ["x", "y", "z"]
                }
            }
        }
    }
])
@httpResponseTests([
    {
        id: "response_nested_map"
        protocol: restJson1
        code: 201
        body: "{\"nestedMaps\":{\"a\":{\"b\":[\"x\",\"y\",\"z\"]}}}"
        params: {
            "nestedMaps": {
                "a": {
                    "b": ["x", "y", "z"]
                }
            }
        }
    }
])
operation CreateNestedMap {
    input: HasNestedMap,
    output: HasNestedMap
}

structure HasNestedMap {
    nestedMaps: OuterMap
}

map OuterMap {
    key: String
    value: InnerMap
}

map InnerMap {
    key: String
    value: StringList
}

list StringList {
    member: String
}

// Request & response tests for nested sparse maps & lists.
@http(uri: "/create_nested_sparse_map", method: "POST")
@httpRequestTests([
    {
        id: "request_nested_sparse_map"
        protocol: restJson1
        method: "POST"
        host: "example.com"
        uri: "/create_nested_sparse_map"
        body: "{\"nestedSparseMaps\":{\"a\":{\"b\":[\"x\",null,\"y\",null,\"z\",null],\"c\":null},\"d\":null},\"sparseStructureMap\":{\"m\":{\"string\":\"rst\"},\"n\":null}}"
        bodyMediaType: "application/json"
        params: {
            "nestedSparseMaps": {
                "a": {
                    "b": ["x", null, "y", null, "z", null]
                    "c": null
                },
                "d": null
            }
            "sparseStructureMap": {
                "m": {
                    "string": "rst"
                }
                "n": null
            }
        }
    }
])
@httpResponseTests([
    {
        id: "response_nested_sparse_map"
        protocol: restJson1
        code: 201
        body: "{\"nestedSparseMaps\":{\"a\":{\"b\":[\"x\",null,\"y\",null,\"z\",null],\"c\":null},\"d\":null},\"sparseStructureMap\":{\"m\":{\"string\":\"rst\"},\"n\":null}}"
        params: {
            "nestedSparseMaps": {
                "a": {
                    "b": ["x", null, "y", null, "z", null]
                    "c": null
                }
                "d": null
            }
            "sparseStructureMap": {
                "m": {
                    "string": "rst"
                }
                "n": null
            }
        }
    }
])
operation CreateNestedSparseMap {
    input: HasNestedSparseMap,
    output: HasNestedSparseMap
}

structure HasNestedSparseMap {
    nestedSparseMaps: OuterSparseMap
    sparseStructureMap: SparseStructureMap
}

@sparse
map OuterSparseMap {
    key: String
    value: InnerSparseMap
}

@sparse
map InnerSparseMap {
    key: String
    value: SparseStringList
}

@sparse
list SparseStringList {
    member: String
}

@sparse
map SparseStructureMap {
    key: String
    value: InnerStructure
}

structure InnerStructure {
    string: String
}