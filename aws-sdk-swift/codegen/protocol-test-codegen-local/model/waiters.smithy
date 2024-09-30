$version: "2.0"

namespace aws.protocoltests.waiters

use smithy.waiters#waitable
use aws.protocols#restJson1
use aws.api#service

// A service which has a GET operation with waiters defined upon it.
// The acceptor in each waiter serves as subject for unit testing,
// to ensure that the logic in code-generated acceptors works as
// expected.
@service(sdkId: "Waiters")
@restJson1
service Waiters {
    version: "2022-11-30",
    operations: [GetWidget]
}

@http(uri: "/widget", method: "POST")
@waitable(
    SuccessTrueMatcher: {
        documentation: "Acceptor matches on successful request"
        acceptors: [
            {
                state: "success"
                matcher: {
                    success: true
                }
            }
        ]
    }
    SuccessFalseMatcher: {
        documentation: "Acceptor matches on unsuccessful request"
        acceptors: [
            {
                state: "success"
                matcher: {
                    success: false
                }
            }
        ]
    }
    ErrorTypeMatcher: {
        documentation: "Acceptor matches on receipt of specified error"
        acceptors: [
            {
                state: "success"
                matcher: {
                    errorType: "MyError"
                }
            }
        ]
    }
    OutputStringPropertyMatcher: {
        documentation: "Acceptor matches on output payload property"
        acceptors: [
            {
                state: "success"
                matcher: {
                    output: {
                        path: "stringProperty"
                        expected: "payload property contents"
                        comparator: "stringEquals"
                    }
                }
            }
        ]
    }
    OutputStringArrayAllPropertyMatcher: {
        documentation: "Acceptor matches on output payload property"
        acceptors: [
            {
                state: "success"
                matcher: {
                    output: {
                        path: "stringArrayProperty"
                        expected: "payload property contents"
                        comparator: "allStringEquals"
                    }
                }
            }
        ]
    }
    OutputStringArrayAnyPropertyMatcher: {
        documentation: "Acceptor matches on output payload property"
        acceptors: [
            {
                state: "success"
                matcher: {
                    output: {
                        path: "stringArrayProperty"
                        expected: "payload property contents"
                        comparator: "anyStringEquals"
                    }
                }
            }
        ]
    }
    OutputBooleanPropertyMatcher: {
        documentation: "Acceptor matches on output payload property"
        acceptors: [
            {
                state: "success"
                matcher: {
                    output: {
                        path: "booleanProperty"
                        expected: "false"
                        comparator: "booleanEquals"
                    }
                }
            }
        ]
    }
    InputOutputPropertyMatcher: {
        documentation: "Acceptor matches on input property equaling output property"
        acceptors: [
            {
                state: "success"
                matcher: {
                    inputOutput: {
                        path: "input.stringProperty == output.stringProperty"
                        expected: "true"
                        comparator: "booleanEquals"
                    }
                }
            }
        ]
    }
    FlattenMatcher: {
        documentation: "Matches when any grandchild has name 'expected name'"
        acceptors: [
            {
                state: "success"
                matcher: {
                    output: {
                        path: "children[].grandchildren[].name"
                        expected: "expected name"
                        comparator: "anyStringEquals"
                    }
                }
            }
        ]
    }
    FlattenLengthMatcher: {
        documentation: "Matches when there are 6 grandchildren total"
        acceptors: [
            {
                state: "success"
                matcher: {
                    output: {
                        path: "length(children[].grandchildren[]) == `6`"
                        expected: "true"
                        comparator: "booleanEquals"
                    }
                }
            }
        ]
    }
    FlattenFilterMatcher: {
        documentation: "Matches when exactly one child has 3 grandchildren"
        acceptors: [
            {
                state: "success"
                matcher: {
                    output: {
                        path: "length(children[?length(grandchildren) == `3`]) == `1`"
                        expected: "true"
                        comparator: "booleanEquals"
                    }
                }
            }
        ]
    }
    LengthFlattenFilterMatcher: {
        documentation: "Matches when exactly 3 grandchildren have numbers above 4"
        acceptors: [
            {
                state: "success"
                matcher: {
                    output: {
                        path: "length((children[].grandchildren[])[?number > `4`]) == `3`"
                        expected: "true"
                        comparator: "booleanEquals"
                    }
                }
            }
        ]
    }
    ProjectionMatcher: {
        documentation: "Matches when dataMap values are all `abc`"
        acceptors: [
            {
                state: "success"
                matcher: {
                    output: {
                        path: "dataMap.*"
                        expected: "abc"
                        comparator: "allStringEquals"
                    }
                }
            }
        ]
    }
    ContainsFieldMatcher: {
        documentation: "Matches when any value of dataMap is the same as stringProperty"
        acceptors: [
            {
                state: "success"
                matcher: {
                    output: {
                        path: "contains(dataMap.*, stringProperty)"
                        expected: "true"
                        comparator: "booleanEquals"
                    }
                }
            }
        ]
    }
    AndInequalityMatcher: {
        documentation: "Matches when there are three elements in dataMap but not three in stringArrayProperty"
        acceptors: [
            {
                state: "success"
                matcher: {
                    output: {
                        path: "length(dataMap) == `3` && length(stringArrayProperty) != `3`"
                        expected: "true"
                        comparator: "booleanEquals"
                    }
                }
            }
        ]
    }
)
operation GetWidget {
    input: WidgetInput,
    output: WidgetOutput
    errors: [MyError]
}

structure WidgetInput {
    stringProperty: String
}

structure WidgetOutput {
    stringProperty: String
    stringArrayProperty: StringArray
    booleanProperty: Boolean
    booleanArrayProperty: BooleanArray
    children: ChildArray
    dataMap: DataMap
}

structure Child {
    grandchildren: GrandchildArray
}

structure Grandchild {
    name: String
    number: Integer
}

list StringArray{
    member: String
}

list BooleanArray{
    member: Boolean
}

list ChildArray {
    member: Child
}

list GrandchildArray {
    member: Grandchild
}

map DataMap {
    key: String
    value: String
}

@error("client")
structure MyError {
    message: String
}
