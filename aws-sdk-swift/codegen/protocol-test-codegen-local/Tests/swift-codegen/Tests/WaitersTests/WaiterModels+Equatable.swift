//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Waiters

extension GetWidgetInput: Equatable {

    public static func ==(lhs: GetWidgetInput, rhs: GetWidgetInput) -> Bool {
        return lhs.stringProperty == rhs.stringProperty
    }
}

extension GetWidgetOutput: Equatable {

    public static func ==(lhs: GetWidgetOutput, rhs: GetWidgetOutput) -> Bool {
        return lhs.booleanArrayProperty == rhs.booleanArrayProperty &&
        lhs.booleanProperty == rhs.booleanProperty &&
        lhs.children == rhs.children &&
        lhs.dataMap == rhs.dataMap &&
        lhs.stringArrayProperty == rhs.stringArrayProperty &&
        lhs.stringProperty == rhs.stringProperty
    }
}

extension WaitersClientTypes.Child: Equatable {

    public static func ==(lhs: WaitersClientTypes.Child, rhs: WaitersClientTypes.Child) -> Bool {
        return lhs.grandchildren == rhs.grandchildren
    }
}

extension WaitersClientTypes.Grandchild: Equatable {

    public static func ==(lhs: WaitersClientTypes.Grandchild, rhs: WaitersClientTypes.Grandchild) -> Bool {
        return lhs.name == rhs.name && lhs.number == rhs.number
    }
}
