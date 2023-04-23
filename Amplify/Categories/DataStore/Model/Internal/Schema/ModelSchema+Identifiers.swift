//
//  ModelSchema+Identifiers.swift
//  
//
//  Created by Sapir Muallem on 23/04/2023.
//

import Foundation

extension ModelSchema {
    func getModelIdentifiers(from modelObject: [String: JSONValue]) -> [LazyReferenceIdentifier] {
        var identifiers = [LazyReferenceIdentifier]()

        for identifierField in primaryKey.fields {
            if case .string(let identifierValue) = modelObject[identifierField.name] {
                identifiers.append(.init(name: identifierField.name, value: identifierValue))
            }
        }
        
        return identifiers
    }
}
