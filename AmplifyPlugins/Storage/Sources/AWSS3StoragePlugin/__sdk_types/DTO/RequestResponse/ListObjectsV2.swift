//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

struct ListObjectsV2Input: Equatable {
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

    enum CodingKeys: String, CodingKey {
        case commonPrefixes = "CommonPrefixes"
        case contents = "Contents"
        case delimiter = "Delimiter"
        case encodingType = "EncodingType"
        case isTruncated = "IsTruncated"
        case marker = "Marker"
        case maxKeys = "MaxKeys"
        case name = "Name"
        case nextMarker = "NextMarker"
        case `prefix` = "Prefix"
    }
}

struct ListObjectsV2OutputResponse: Equatable {
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

    // "x-amz-request-charged" - requestCharged
}
