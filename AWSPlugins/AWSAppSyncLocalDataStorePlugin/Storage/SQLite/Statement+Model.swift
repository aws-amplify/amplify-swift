//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

extension Statement {

    public func toModel<M: PersistentModel>() throws -> [M] {
        var models: [M] = []
        for row in self {
            let modelDictionary = try convertRowToDictionary(M.self, row: row, columns: columnNames)
            let model: M = try M.from(dictionary: modelDictionary)
            models.append(model)
        }
        return models
    }

    private func convertRowToDictionary(_ modelType: PersistentModel.Type,
                                        row: Element,
                                        columns: [String],
                                        property: String? = nil) throws -> [String: Any] {
        var values: [String: Any] = [:]
        let propertyPrefix = property != nil ? "\(property!)." : nil
        for (index, column) in columns.enumerated()
            where propertyPrefix == nil || column.starts(with: propertyPrefix!) {

            let name: String = propertyPrefix != nil
                ? column.replacingOccurrences(of: propertyPrefix!, with: "")
                : column
            if name.firstIndex(of: ".") != nil {
                let propertyName = String(name.split(separator: ".").first!)
                guard let connectedProperty = modelType.properties.by(name: propertyName) else {
                    preconditionFailure("Property \(propertyName) not found on \(modelType.name)")
                }
                guard let connectedModelType = connectedProperty.metadata.connectedModel else {
                    preconditionFailure("yyy")
                }
                let connectedModel = try convertRowToDictionary(connectedModelType,
                                                                row: row,
                                                                columns: columns,
                                                                property: propertyName)
                values[propertyName] = connectedModel
            } else if modelType.properties.by(name: name) != nil {
                values[name] = row[index]
            }
        }
//        print("==============")
//        print(values)
//        print("==============")
//        let model = try modelType.from(dictionary: values)
        return values
    }

}
