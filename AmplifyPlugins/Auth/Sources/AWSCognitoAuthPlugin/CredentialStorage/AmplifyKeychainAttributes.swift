//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct KeychainAttributes {

    var itemClass: String = AmplifyKeychainConstant.ClassGenericPassword
    var service: String
    var accessGroup: String? = nil

    var label: String?
    var comment: String?

}

extension KeychainAttributes {

    func query() -> [String: Any] {
        let query: [String: Any] = [
            AmplifyKeychainConstant.Class: itemClass,
            AmplifyKeychainConstant.AttributeService: service,
            AmplifyKeychainConstant.AttributeAccessGroup: accessGroup as Any
        ]

        return query
    }

    func fetchAll(for key: String?, and value: Data) -> [String: Any] {

        var attributes: [String: Any]

        if key != nil {
            attributes = query()
            attributes[AmplifyKeychainConstant.AttributeAccount] = key
        } else {
            attributes = [String: Any]()
        }

        attributes[AmplifyKeychainConstant.ValueData] = value

        if label != nil {
            attributes[AmplifyKeychainConstant.AttributeLabel] = label
        }
        if comment != nil {
            attributes[AmplifyKeychainConstant.AttributeComment] = comment
        }

        return attributes

    }
}
