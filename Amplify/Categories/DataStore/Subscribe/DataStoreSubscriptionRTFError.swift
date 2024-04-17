//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum RTFError: CaseIterable {
    case unknownField
    case maxAttributes
    case maxCombinations
    case repeatedFieldname
    case notGroup
    case fieldNotInType
    
    private var uniqueMessagePart: String {
        switch self {
        case .unknownField:
            return "UnknownArgument: Unknown field argument filter"
        case .maxAttributes:
            return "Filters exceed maximum attributes limit"
        case .maxCombinations:
            return "Filters combination exceed maximum limit"
        case .repeatedFieldname:
            return "filter uses same fieldName multiple time"
        case .notGroup:
            return "The variables input contains a field name 'not'"
        case .fieldNotInType:
            return "The variables input contains a field that is not defined for input object type"
        }
    }
    
    /// Init RTF error based on error's debugDescription value
    public init?(description: String) {
        guard 
            let rtfError = RTFError.allCases.first(where: { description.contains($0.uniqueMessagePart) })
        else {
            return nil
        }
        
        self = rtfError
    }
}
