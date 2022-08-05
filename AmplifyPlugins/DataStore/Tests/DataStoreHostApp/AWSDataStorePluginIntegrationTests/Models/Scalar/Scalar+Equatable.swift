//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension ScalarContainer: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.id == rhs.id
                    && lhs.myInt == rhs.myInt
                    && lhs.myDouble == rhs.myDouble
                    && lhs.myBool == rhs.myBool
                    && lhs.myDate == rhs.myDate
                    && lhs.myTime == rhs.myTime
                    && lhs.myDateTime == rhs.myDateTime
                    && lhs.myTimeStamp == rhs.myTimeStamp
                    && lhs.myEmail == rhs.myEmail
                    && lhs.myJSON == rhs.myJSON
                    && lhs.myPhone == rhs.myPhone
                    && lhs.myURL == rhs.myURL
                    && lhs.myIPAddress == rhs.myIPAddress)
    }
}

extension ListIntContainer: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.id == rhs.id
                    && lhs.test == rhs.test
                    && lhs.nullableInt == rhs.nullableInt
                    && lhs.intList == rhs.intList
                    && lhs.intNullableList == rhs.intNullableList
                    && lhs.nullableIntList == rhs.nullableIntList
                    && lhs.nullableIntNullableList == rhs.nullableIntNullableList)
    }
}

extension ListStringContainer: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.id == rhs.id
                    && lhs.test == rhs.test
                    && lhs.nullableString == rhs.nullableString
                    && lhs.stringList == rhs.stringList
                    && lhs.stringNullableList == rhs.stringNullableList
                    && lhs.nullableStringList == rhs.nullableStringList
                    && lhs.nullableStringNullableList == rhs.nullableStringNullableList)
    }
}

extension EnumTestModel: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.id == rhs.id
                    && lhs.enumVal == rhs.enumVal
                    && lhs.nullableEnumVal == rhs.nullableEnumVal
                    && lhs.enumList == rhs.enumList
                    && lhs.enumNullableList == rhs.enumNullableList
                    && lhs.nullableEnumList == rhs.nullableEnumList
                    && lhs.nullableEnumNullableList == rhs.nullableEnumNullableList)
    }
}
extension NestedTypeTestModel: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.id == rhs.id
                    && lhs.nestedVal == rhs.nestedVal
                    && lhs.nullableNestedVal == rhs.nullableNestedVal
                    && lhs.nestedList == rhs.nestedList
                    && lhs.nestedNullableList == rhs.nestedNullableList
                    && lhs.nullableNestedList == rhs.nullableNestedList
                    && lhs.nullableNestedNullableList == rhs.nullableNestedNullableList)
    }
}

extension Nested: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.valueOne == rhs.valueOne
                    && lhs.valueTwo == rhs.valueTwo)
    }
}
