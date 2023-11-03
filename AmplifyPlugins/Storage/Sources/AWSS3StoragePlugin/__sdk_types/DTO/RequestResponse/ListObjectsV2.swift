//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

struct ListObjectsV2Input: Equatable, Encodable {
    /// This member is required.
    var bucket: String
    var continuationToken: String?
    var delimiter: String?
    var encodingType: S3ClientTypes.EncodingType?
    var expectedBucketOwner: String?
    var fetchOwner: Bool?
    var maxKeys: Int?
    var optionalObjectAttributes: [S3ClientTypes.OptionalObjectAttributes]?
    var `prefix`: String?
    var requestPayer: S3ClientTypes.RequestPayer?
    var startAfter: String?

    var queryItems: [URLQueryItem] {
        [
            .init(name: "continuation-token".urlQueryEncoded(), value: continuationToken?.urlQueryEncoded()),
            .init(name: "delimiter".urlQueryEncoded(), value: delimiter?.urlQueryEncoded()),
            .init(name: "fetch-owner".urlQueryEncoded(), value: fetchOwner.map(String.init)?.urlQueryEncoded()),
            .init(name: "encoding-type".urlQueryEncoded(), value: encodingType?.rawValue.urlQueryEncoded()),
            .init(name: "start-after".urlQueryEncoded(), value: startAfter?.urlQueryEncoded()),
            .init(name: "prefix".urlQueryEncoded(), value: `prefix`?.urlQueryEncoded()),
            .init(name: "max-keys".urlQueryEncoded(), value: maxKeys.map(String.init)?.urlQueryEncoded())
        ]
            .compactMap { $0.value == nil ? nil : $0 }
    }

    var _headers: [String: String?] {
        [
            "x-amz-expected-bucket-owner": expectedBucketOwner,
            "x-amz-request-payer": requestPayer?.rawValue
        ].merging(
            optionalObjectAttributes?.reduce(into: [String: String]()) { dict, attribute in
                if let existing = dict["x-amz-optional-object-attributes"] {
                    dict["x-amz-optional-object-attributes"] = "\(existing), \(attribute.rawValue)"
                } else {
                    dict["x-amz-optional-object-attributes"] = attribute.rawValue
                }
            } ?? [:],
            uniquingKeysWith: { current, _ in current }
        )
    }

    var headers: [String: String] {
        _headers.compactMapValues { $0 }
    }

//    var urlPath: String {
//        key.urlPathEncoded()
//    }
}

struct ListObjectsV2OutputResponse: Equatable, Decodable {
    var commonPrefixes: [S3ClientTypes.CommonPrefix]?
    var contents: [S3ClientTypes.Object]?
    var continuationToken: String?
    var delimiter: String?
    var encodingType: S3ClientTypes.EncodingType?
    var isTruncated: Bool?
    var keyCount: Int?
    var maxKeys: Int?
    var name: String?
    var nextContinuationToken: String?
    var `prefix`: String?
    var requestCharged: S3ClientTypes.RequestCharged?
    var startAfter: String?

    enum CodingKeys: String, CodingKey {
        case commonPrefixes = "CommonPrefixes"
        case contents = "Contents"
        case continuationToken = "ContinuationToken"
        case delimiter = "Delimiter"
        case encodingType = "EncodingType"
        case isTruncated = "IsTruncated"
        case keyCount = "KeyCount"
        case maxKeys = "MaxKeys"
        case name = "Name"
        case nextContinuationToken = "NextContinuationToken"
        case `prefix` = "Prefix"
        case startAfter = "StartAfter"
    }
}

extension ListObjectsV2OutputResponse: HeadersApplying {
    func applying(headers: [String: String]) -> Self {
        var copy = self
        copy.requestCharged = headers["x-amz-request-charged"]
            .flatMap(S3ClientTypes.RequestCharged.init(rawValue:))
        return copy
    }
}
