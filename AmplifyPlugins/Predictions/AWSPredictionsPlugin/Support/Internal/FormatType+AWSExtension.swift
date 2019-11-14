//
//  FormatType+AWSExtension.swift
//  AWSPredictionsPlugin
//
//  Created by Stone, Nicki on 11/13/19.
//  Copyright © 2019 Amazon Web Services. All rights reserved.
//

import Foundation
import Amplify

extension TextFormatType {
    var textractServiceFormatType: [String] {
        switch self {
        case .form:
            return ["FORMS"]
        case .table:
            return ["TABLES"]
        case .all:
            return ["TABLES, FORMS"]
        default:
            return ["TABLES, FORMS"]
        }
    }
}
