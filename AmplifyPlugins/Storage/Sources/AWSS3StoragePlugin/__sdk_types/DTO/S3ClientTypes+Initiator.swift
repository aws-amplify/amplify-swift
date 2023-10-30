//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    /// Container element that identifies who initiated the multipart upload.
    struct Initiator: Equatable {
        /// Name of the Principal.
        var displayName: String?
        /// If the principal is an Amazon Web Services account, it provides the Canonical User ID. If the principal is an IAM User, it provides a user ARN value.
        var id: String?

        enum CodingKeys: String, CodingKey {
            case displayName = "DisplayName"
            case id = "ID"
        }
    }
}
