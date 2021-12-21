//
//  Row.swift
//  AmplifyTestCommon
//
//  Created by Costantino, Diego on 2021-11-30.
//

import Foundation
import Amplify

public struct Row: Model {
    public let id: String
    public var group: Group

    public init(id: String = UUID().uuidString,
                group: Group) {
        self.id = id
        self.group = group
    }
}
