//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    /// Specifies whether the attribute is standard or custom.
    struct AttributeType: Equatable {
        /// The name of the attribute.
        /// This member is required.
        var name: String?
        /// The value of the attribute.
        var value: String?

        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case value = "Value"
        }
    }
}
