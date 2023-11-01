//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation
import AWSPluginsCore

struct S3ClientConfiguration {
    let region: String
    let credentialsProvider: CredentialsProvider
    let accelerate: Bool
    let encoder: JSONEncoder
    let decoder: JSONDecoder
    let signingName = "s3"
}

