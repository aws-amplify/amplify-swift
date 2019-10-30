//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

extension String {
    func quoted() -> String {
        return "\"\(self)\""
    }
}

enum SQLDataType: String {
    case text
    case integer
    case real
}

protocol SQLColumn {

    var sqlName: String { get }

    var sqlType: SQLDataType { get }

    var isForeignKey: Bool { get }
}

extension ModelField: SQLColumn {

    var sqlName: String {
        return isForeignKey ? name + "Id" : name
    }

    var sqlType: SQLDataType {
        switch typeDefinition {
        case .string, .enum, .date, .model:
            return .text
        case .int, .bool:
            return .integer
        case .decimal:
            return .real
        default:
            return .text
        }
    }

    var isForeignKey: Bool {
        switch typeDefinition {
        case .model:
            return true
        default:
            return false
        }
    }

    var connectedModel: Model.Type? {
        switch typeDefinition {
        case .model(let type), .collection(let type):
            return type
        default:
            return nil
        }
    }

    func columnName(forNamespace namespace: String? = nil) -> String {
        var column = sqlName.quoted()
        if let namespace = namespace {
            column = namespace.quoted() + "." + column
        }
        return column
    }

    func columnAlias(forNamespace namespace: String? = nil) -> String {
        var column = sqlName
        if let namespace = namespace {
            column = "\(namespace).\(column)"
        }
        return "as \(column.quoted())"
    }

    func value(from binding: Binding?) -> Any? {
        // TODO improve this with better Model <-> DB Result serialization solution
        switch typeDefinition {
        case .bool:
            if let value = binding as? Int64 {
                return Bool.fromDatatypeValue(value)
            }
        case .date, .dateTime:
            if let value = binding as? String {
                // The decoder translates Double to Date
                return Date.fromDatatypeValue(value).timeIntervalSince1970
            }
        case .collection:
            return binding ?? []
        default:
            return binding
        }
        return binding
    }
}

extension Array where Element == ModelField {

    func columns() -> [ModelField] {
        return filter { !$0.isConnected || $0.isForeignKey }
    }

    func foreignKeys() -> [ModelField] {
        return filter { $0.isForeignKey }
    }

}
