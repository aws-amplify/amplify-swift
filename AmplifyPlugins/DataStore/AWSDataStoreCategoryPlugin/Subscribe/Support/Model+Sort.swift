//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import CoreGraphics

extension Array where Element: Model {
    mutating func sortModels(by sortBy: QuerySortBy, modelSchema: ModelSchema) {
        sort { modelSchema.comparator(model1: $0, model2: $1, sortBy: sortBy) }
    }
}

enum ModelValueCompare<T: Comparable> {
    case bothNil
    case leftNil(value2: T)
    case rightNil(value1: T)
    case values(value1: T, value2: T)
    case unknown

    init(value1Optional: T?, value2Optional: T?) {
        if value1Optional == nil && value2Optional == nil {
            self = .bothNil
        } else if value1Optional == nil, let value2 = value2Optional {
            self = .leftNil(value2: value2)
        } else if value2Optional == nil, let value1 = value1Optional {
            self = .rightNil(value1: value1)
        } else if let value1 = value1Optional, let value2 = value2Optional {
            self = .values(value1: value1, value2: value2)
        } else {
            self = .unknown
        }
    }

    /// Treat `nil` as less than non `nil`values, so return asecnding when left side is `nil` and descending when right
    /// is nil.
    func sortComparator(sortOrder: QuerySortOrder) -> Bool {
        switch self {
        case .bothNil, .leftNil:
            return sortOrder == .ascending
        case .rightNil:
            return sortOrder == .descending
        case .values(let value1, let value2):
            return sortOrder == .ascending ? value1 < value2 : value1 > value2
        case .unknown:
            return false
        }
    }
}

extension ModelSchema {
    // swiftlint:disable:next cyclomatic_complexity
    func comparator(model1: Model,
                    model2: Model,
                    sortBy: QuerySortBy) -> Bool {
        let fieldName = sortBy.fieldName
        let sortOrder = sortBy.fieldOrder
        guard let modelField = field(withName: fieldName) else {
            return false
        }
        let value1 = model1[fieldName] ?? nil
        let value2 = model2[fieldName] ?? nil
        switch modelField.type {
        case .string:
            guard let value1Optional = value1 as? String?, let value2Optional = value2 as? String? else {
                return false
            }
            return ModelValueCompare(value1Optional: value1Optional,
                                     value2Optional: value2Optional)
                .sortComparator(sortOrder: sortOrder)
        case .int, .timestamp:
            guard let value1Optional = value1 as? Int?, let value2Optional = value2 as? Int? else {
                return false
            }
            return ModelValueCompare(value1Optional: value1Optional,
                                     value2Optional: value2Optional)
                .sortComparator(sortOrder: sortOrder)

        case .double:
            guard let value1Optional = value1 as? Double?, let value2Optional = value2 as? Double? else {
                return false
            }
            return ModelValueCompare(value1Optional: value1Optional,
                                     value2Optional: value2Optional)
                .sortComparator(sortOrder: sortOrder)

        case .date:
            guard let value1Optional = value1 as? Temporal.Date?, let value2Optional = value2 as? Temporal.Date? else {
                return false
            }
            return ModelValueCompare(value1Optional: value1Optional,
                                     value2Optional: value2Optional)
                .sortComparator(sortOrder: sortOrder)
        case .dateTime:
            guard let value1Optional = value1 as? Temporal.DateTime?,
                  let value2Optional = value2 as? Temporal.DateTime? else {
                return false
            }
            return ModelValueCompare(value1Optional: value1Optional,
                                     value2Optional: value2Optional)
                .sortComparator(sortOrder: sortOrder)

        case .time:
            guard let value1Optional = value1 as? Temporal.Time?, let value2Optional = value2 as? Temporal.Time? else {
                return false
            }
            return ModelValueCompare(value1Optional: value1Optional,
                                     value2Optional: value2Optional)
                .sortComparator(sortOrder: sortOrder)
        case .bool:
            guard let value1Optional = value1 as? Bool?, let value2Optional = value2 as? Bool? else {
                return false
            }
            if value1Optional == nil && value2Optional == nil {
                return sortOrder == .ascending
            } else if value1Optional == nil, value2Optional != nil {
                return sortOrder == .ascending
            } else if value1Optional != nil, value2Optional == nil {
                return sortOrder == .descending
            } else if let value1 = value1Optional, let value2 = value2Optional {
                return sortOrder == .ascending ?
                    value1.intValue < value2.intValue : value1.intValue > value2.intValue
            }
        case .enum:
            guard case .some(Optional<Any>.some(let value1Optional)) = value1,
                  case .some(Optional<Any>.some(let value2Optional)) = value2 else {
                  if value1 == nil && value2 != nil {
                      return sortOrder == .ascending
                  } else if value1 != nil && value2 == nil {
                      return sortOrder == .descending
                  }
                  return false
            }
            let enumValue1Optional = (value1Optional as? EnumPersistable)?.rawValue
            let enumValue2Optional = (value2Optional as? EnumPersistable)?.rawValue
            if enumValue1Optional == nil && enumValue2Optional == nil {
                return sortOrder == .ascending
            } else if enumValue1Optional == nil, enumValue2Optional != nil {
                return sortOrder == .ascending
            } else if enumValue1Optional != nil, enumValue2Optional == nil {
                return sortOrder == .descending
            } else if let enumValue1 = enumValue1Optional, let enumValue2 = enumValue2Optional {
                return sortOrder == .ascending ?
                enumValue1 < enumValue2 : enumValue1 > enumValue2
            }
        case .embedded, .embeddedCollection, .model, .collection:
            // Behavior is undetermined
            return false
        }
        return false
    }

}
