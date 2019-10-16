//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite

protocol SQLProperty {
    func value(from value: Binding?) -> Any?
}

protocol SQLPropertyMetadata {
    var sqlName: String { get }
    var sqlType: SQLDataType { get }
    var isForeignKey: Bool { get }
}

enum SQLDataType: String {
    case text
    case integer
    case real
}

extension PropertyMetadata: SQLPropertyMetadata {
    var sqlName: String {
        let columnName = isForeignKey ? name + "Id" : name
        return "\"\(columnName)\""
    }

    var sqlType: SQLDataType {
        switch type {
        case .string, .enum, .date, .model:
            return .text
        case .int, .boolean:
            return .integer
        case .decimal:
            return .real
        default:
            return .text
        }
    }

    var isForeignKey: Bool {
        guard isConnected else {
            return false
        }
        switch type {
        case .model:
            return true
        default:
            return false
        }
    }

}

extension ModelProperty {
    func value(from value: Binding?) -> Any? {
        // TODO improve this with better Model <-> DB Result serialization solution
        switch metadata.type {
        case .boolean:
            if let value = value as? Int64 {
                return Bool.fromDatatypeValue(value)
            }
        case .date:
            if let value = value as? String {
                // The decoder translates Double to Date
                return Date.fromDatatypeValue(value).timeIntervalSince1970
            }
        case .collection:
            return value ?? []
        default:
            return value
        }
        return value
    }
}

extension Array where Element == ModelProperty {

    func foreignKeys() -> [ModelProperty] {
        return filter { $0.metadata.isForeignKey }
    }

    func columns() -> [ModelProperty] {
        return filter { !$0.metadata.isConnected || $0.metadata.isForeignKey }
    }

    func by(name: String) -> ModelProperty? {
        return first { $0.metadata.name == name }
    }

}

extension Model where Self: ModelMetadata {

    internal func sqlValues(for properties: ModelProperties?) -> [Binding?] {
        let model = type(of: self)
        let modelProperties = properties != nil ? properties! : model.properties
        let propertiesValues: [Binding?] = modelProperties.map { prop in
            let value = self[prop.metadata.key]

            if value == nil {
                return nil
            }

            if let value = value as? Date {
                return value.datatypeValue
            }

            if let value = value as? Bool {
                return value.datatypeValue
            }

            // if value is a connected model, get its primary key
            if value != nil && value is Model && prop.metadata.isForeignKey {
                // swiftlint:disable force_cast
                let connectedValue = value as! Model
                // swiftlint:enable force_cast
                let connectedModel: Model.Type = type(of: connectedValue)

                // TODO improve this
                return connectedValue[connectedModel.primaryKey.metadata.name] as? String
            }

            // if value conforms to binding, resolve it
            if let value = value as? Binding {
                return value
            }

            // TODO fallback, should revisit this strategy
            return nil
        }
        return propertiesValues
    }
}
