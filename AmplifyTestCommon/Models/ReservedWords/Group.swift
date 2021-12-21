//
//  Group.swift
//  AmplifyTestCommon
//
//  Created by Costantino, Diego on 2021-11-30.
//

import Foundation
import Amplify

public struct Group: Model {
    public let id: String

    public init(id: String = UUID().uuidString) {
        self.id = id
    }
}
