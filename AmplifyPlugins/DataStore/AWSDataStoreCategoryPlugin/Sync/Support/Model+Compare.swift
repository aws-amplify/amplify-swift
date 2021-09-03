//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable syntactic_sugar
extension ModelSchema {

    /// Compare two `Model` based on a given `ModelSchema`
    /// Returns true if equal, false otherwise
    public func isEqual(_ model1: Model, _ model2: Model) -> Bool {
        for (fieldName, modelField) in fields {
            // read only fields are skipped for eqaulity check as they are created by the service
            if modelField.isReadOnly {
                continue
            }

            let value1 = model1[fieldName] ?? nil
            let value2 = model2[fieldName] ?? nil

            // check equality for different `ModelFieldType`
            switch modelField.type {
            case .string:
                guard let value1Optional = value1 as? String?, let value2Optional = value2 as? String? else {
                    return false
                }
                if let value1 = value1Optional, let value2 = value2Optional, value1 != value2 {
                    return false
                } else {
                    continue
                }
            case .int:
                guard let value1Optional = value1 as? Int?, let value2Optional = value2 as? Int? else {
                    return false
                }
                if let value1 = value1Optional, let value2 = value2Optional, value1 != value2 {
                    return false
                } else {
                    continue
                }
            case .double:
                guard let value1Optional = value1 as? Double?, let value2Optional = value2 as? Double? else {
                    return false
                }
                if let value1 = value1Optional, let value2 = value2Optional, value1 != value2 {
                    return false
                } else {
                    continue
                }
            case .date:
                guard let value1Optional = value1 as? Temporal.Date?,
                      let value2Optional = value2 as? Temporal.Date? else {
                    return false
                }
                if let value1 = value1Optional, let value2 = value2Optional, value1 != value2 {
                    return false
                } else {
                    continue
                }
            case .dateTime:
                guard let value1Optional = value1 as? Temporal.DateTime?,
                      let value2Optional = value2 as? Temporal.DateTime? else {
                    return false
                }
                if let value1 = value1Optional, let value2 = value2Optional, value1 != value2 {
                    return false
                } else {
                    continue
                }
            case .time:
                guard let value1Optional = value1 as? Temporal.Time?,
                      let value2Optional = value2 as? Temporal.Time? else {
                    return false
                }
                if let value1 = value1Optional, let value2 = value2Optional, value1 != value2 {
                    return false
                } else {
                    continue
                }
            case .timestamp:
                guard let value1Optional = value1 as? String?, let value2Optional = value2 as? String? else {
                    return false
                }
                if let value1 = value1Optional, let value2 = value2Optional, value1 != value2 {
                    return false
                } else {
                    continue
                }
            case .bool:
                guard let value1Optional = value1 as? Bool?, let value2Optional = value2 as? Bool? else {
                    return false
                }
                if let value1 = value1Optional, let value2 = value2Optional, value1 != value2 {
                    return false
                } else {
                    continue
                }
            case .enum:
                guard case .some(Optional<Any>.some(let value1Optional)) = value1,
                      case .some(Optional<Any>.some(let value2Optional)) = value2 else {
                    if value1 == nil && value2 == nil {
                        continue
                    }
                    return false
                }
                let enumValue1Optional = (value1Optional as? EnumPersistable)?.rawValue
                let enumValue2Optional = (value2Optional as? EnumPersistable)?.rawValue
                if enumValue1Optional != enumValue2Optional {
                    return false
                } else {
                    continue
                }
            case .embedded, .embeddedCollection:
                do {
                    if let encodable1 = value1 as? Encodable,
                       let encodable2 = value2 as? Encodable {
                        let json1 = try SQLiteModelValueConverter.toJSON(encodable1)
                        let json2 = try SQLiteModelValueConverter.toJSON(encodable2)
                        if let value1 = json1, let value2 = json2, value1 != value2 {
                            return false
                        } else {
                            continue
                        }
                    }
                } catch {
                    continue
                }
            case .model:
                continue
            case .collection:
                continue
            }
        }
        return true
    }
}
