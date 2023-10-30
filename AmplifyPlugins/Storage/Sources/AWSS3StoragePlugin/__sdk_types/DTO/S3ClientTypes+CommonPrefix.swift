//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    /// Container for all (if there are any) keys between Prefix and the next occurrence of the string specified by a delimiter. CommonPrefixes lists keys that act like subdirectories in the directory specified by Prefix. For example, if the prefix is notes/ and the delimiter is a slash (/) as in notes/summer/july, the common prefix is notes/summer/.
    struct CommonPrefix: Equatable {
        /// Container for the specified common prefix.
        var `prefix`: String?

        enum CodingKeys: String, CodingKey {
            case `prefix` = "Prefix"
        }
    }
}
