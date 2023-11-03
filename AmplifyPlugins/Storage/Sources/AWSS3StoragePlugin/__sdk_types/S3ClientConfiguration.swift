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

    init(
        region: String,
        credentialsProvider: CredentialsProvider,
        accelerate: Bool,
        encoder: () -> JSONEncoder = epochDateEncoder,
        decoder: () -> JSONDecoder = epochDateDecoder
    ) {
        self.region = region
        self.credentialsProvider = credentialsProvider
        self.accelerate = accelerate
        self.encoder = encoder()
        self.decoder = decoder()
    }
}

public func epochDateDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    return decoder
}

public func epochDateEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970
    return encoder
}
