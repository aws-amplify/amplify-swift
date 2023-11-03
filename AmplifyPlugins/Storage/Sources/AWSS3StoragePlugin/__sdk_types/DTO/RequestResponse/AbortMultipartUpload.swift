//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

struct AbortMultipartUploadInput: Equatable, Encodable {
    /// This member is required.
    var bucket: String
    /// This member is required.
    var uploadId: String
    /// This member is required.
    var key: String

    var expectedBucketOwner: String?
    var requestPayer: S3ClientTypes.RequestPayer?

    var headers: [String: String] {
        [
            "x-amz-expected-bucket-owner": expectedBucketOwner,
            "x-amz-request-payer": requestPayer?.rawValue
        ].compactMapValues { $0 }
    }

    var queryItems: [URLQueryItem] {
        [
            .init(name: "x-id", value: "AbortMultipartUpload"),
            .init(name: "uploadId", value: uploadId.urlQueryEncoded())
        ]
            .compactMap { $0.value == nil ? nil : $0 }
    }

    var urlPath: String {
        key.urlPathEncoded()
    }
}

struct AbortMultipartUploadOutputResponse: Equatable, Decodable {
    // pulled from "x-amz-request-charged" header
    var requestCharged: S3ClientTypes.RequestCharged?

    init() {}
    init(from decoder: Decoder) throws {}
}

extension AbortMultipartUploadOutputResponse: HeadersApplying {
    func applying(headers: [String: String]) -> AbortMultipartUploadOutputResponse {
        var copy = self
        copy.requestCharged = headers["x-amz-request-charged"]
            .flatMap(S3ClientTypes.RequestCharged.init(rawValue:))
        return self
    }
}
