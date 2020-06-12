//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// MARK: - CustomCodable

/// All persistent custom types should conform to the CustomCodable protocol.
public protocol Embedded: Codable {

    /// A reference to the `ModelSchema` associated with this embedded type.
    static var schema: ModelSchema { get }
}

extension Embedded {
    public static func defineSchema(name: String? = nil,
                                    attributes: ModelAttribute...,
                                    define: (inout ModelSchemaDefinition) -> Void) -> ModelSchema {
        var definition = ModelSchemaDefinition(name: name ?? "",
                                               attributes: attributes)
        define(&definition)
        return definition.build()
    }
}
