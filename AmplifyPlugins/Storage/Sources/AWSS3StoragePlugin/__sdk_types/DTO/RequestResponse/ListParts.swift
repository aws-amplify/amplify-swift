//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

struct ListPartsInput: Equatable, Encodable {
    /// This member is required.
    var bucket: String
    /// This member is required.
    var key: String
    /// This member is required.
    var uploadId: String

    var expectedBucketOwner: String?
    var maxParts: Int?
    var partNumberMarker: String?
    var requestPayer: S3ClientTypes.RequestPayer?
    var sseCustomerAlgorithm: String?
    var sseCustomerKey: String?
    var sseCustomerKeyMD5: String?

    var _headers: [String: String?] {
        [
            "x-amz-expected-bucket-owner": expectedBucketOwner,
            "x-amz-request-payer": requestPayer?.rawValue,
            "x-amz-server-side-encryption-customer-algorithm": sseCustomerAlgorithm,
            "x-amz-server-side-encryption-customer-key": sseCustomerKey,
            "x-amz-server-side-encryption-customer-key-MD5": sseCustomerKeyMD5
        ]
    }

    var headers: [String: String] {
        _headers.compactMapValues { $0 }
    }

    var queryItems: [URLQueryItem] {
        [
            .init(name: "x-id", value: "ListParts"),
            .init(
                name: "part-number-makers".urlQueryEncoded(),
                value: partNumberMarker?.urlQueryEncoded()
            ),
            .init(
                name: "max-parts".urlQueryEncoded(),
                value: maxParts.map(String.init)?.urlQueryEncoded()
            ),
            .init(
                name: "uploadId".urlQueryEncoded(),
                value: uploadId.urlQueryEncoded()
            ),
        ]
            .compactMap { $0.value == nil ? nil : $0 }
    }

    var urlPath: String {
        key.urlPathEncoded()
    }
}


struct ListPartsOutputResponse: Equatable, Decodable {
    var abortDate: Date?
    var abortRuleId: String?
    var bucket: String?
    var checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm?
    var initiator: S3ClientTypes.Initiator?
    var isTruncated: Bool?
    var key: String?
    var maxParts: Int?
    var nextPartNumberMarker: String?
    var owner: S3ClientTypes.Owner?
    var partNumberMarker: String?
    var parts: [S3ClientTypes.Part]?
    var requestCharged: S3ClientTypes.RequestCharged?
    var storageClass: S3ClientTypes.StorageClass?
    var uploadId: String?

    enum CodingKeys: String, CodingKey {
        case bucket = "Bucket"
        case checksumAlgorithm = "ChecksumAlgorithm"
        case initiator = "Initiator"
        case isTruncated = "IsTruncated"
        case key = "Key"
        case maxParts = "MaxParts"
        case nextPartNumberMarker = "NextPartNumberMarker"
        case owner = "Owner"
        case partNumberMarker = "PartNumberMarker"
        case parts = "Part"
        case storageClass = "StorageClass"
        case uploadId = "UploadId"
    }

    func applying(headers: [String: String]?) -> Self {
        guard let headers else { return self }
        var copy = self
        copy.abortDate = headers["x-amz-abort-date"].flatMap {
            DateFormatting().date(from: $0, formatter: .rfc5322WithFractionalSeconds)
        }
        copy.abortRuleId = headers["x-amz-abort-rule-id"]
        copy.requestCharged = headers["x-amz-request-charged"]
            .flatMap(S3ClientTypes.RequestCharged.init(rawValue:))
        return copy
    }

}
