//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct CredentialStoreAttributes {

    var itemClass: String = CredentialStoreConstant.ClassGenericPassword
    var service: String
    var accessGroup: String?

    var label: String?
    var comment: String?

}

extension CredentialStoreAttributes {

    func query() -> [String: Any] {
        var query: [String: Any] = [
            CredentialStoreConstant.Class: itemClass,
            CredentialStoreConstant.AttributeService: service
        ]
        if let accessGroup = accessGroup {
            query[CredentialStoreConstant.AttributeAccessGroup] = accessGroup             
        }
        return query
    }

    func fetchAll(for key: String?, and value: Data) -> [String: Any] {

        var attributes: [String: Any]

        if key != nil {
            attributes = query()
            attributes[CredentialStoreConstant.AttributeAccount] = key
        } else {
            attributes = [String: Any]()
        }

        attributes[CredentialStoreConstant.ValueData] = value

        if label != nil {
            attributes[CredentialStoreConstant.AttributeLabel] = label
        }
        if comment != nil {
            attributes[CredentialStoreConstant.AttributeComment] = comment
        }

        return attributes

    }
}
