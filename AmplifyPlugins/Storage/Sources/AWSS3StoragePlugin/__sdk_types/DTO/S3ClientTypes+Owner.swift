//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    /// Container for the owner's display name and ID.
    struct Owner: Equatable {
        /// Container for the display name of the owner. This value is only supported in the following Amazon Web Services Regions:
        ///
        /// * US East (N. Virginia)
        ///
        /// * US West (N. California)
        ///
        /// * US West (Oregon)
        ///
        /// * Asia Pacific (Singapore)
        ///
        /// * Asia Pacific (Sydney)
        ///
        /// * Asia Pacific (Tokyo)
        ///
        /// * Europe (Ireland)
        ///
        /// * South America (São Paulo)
        var displayName: String?
        /// Container for the ID of the owner.
        var id: String?

        enum CodingKeys: String, CodingKey {
            case displayName = "DisplayName"
            case id = "ID"
        }
    }

}
