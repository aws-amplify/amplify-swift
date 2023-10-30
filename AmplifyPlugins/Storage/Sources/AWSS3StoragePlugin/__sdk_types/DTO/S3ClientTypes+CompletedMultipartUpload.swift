//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    /// The container for the completed multipart upload details.
    struct CompletedMultipartUpload: Equatable {
        /// Array of CompletedPart data types. If you do not supply a valid Part with your request, the service sends back an HTTP 400 response.
        var parts: [S3ClientTypes.CompletedPart]?

        init(
            parts: [S3ClientTypes.CompletedPart]? = nil
        )
        {
            self.parts = parts
        }
    }

}
