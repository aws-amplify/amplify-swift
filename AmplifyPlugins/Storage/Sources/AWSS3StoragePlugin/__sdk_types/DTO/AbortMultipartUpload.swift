//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

struct AbortMultipartUploadInput: Equatable {
    /// This member is required.
    var bucket: String
    /// The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code 403 Forbidden (access denied).
    var expectedBucketOwner: String?
    /// Key of the object for which the multipart upload was initiated.
    /// This member is required.
    var key: String
    /// Confirms that the requester knows that they will be charged for the request. Bucket owners need not specify this parameter in their requests. If either the source or destination Amazon S3 bucket has Requester Pays enabled, the requester will pay for corresponding charges to copy the object. For information about downloading objects from Requester Pays buckets, see [Downloading Objects in Requester Pays Buckets](https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html) in the Amazon S3 User Guide.
    var requestPayer: S3ClientTypes.RequestPayer?
    /// Upload ID that identifies the multipart upload.
    /// This member is required.
    var uploadId: String

    var headers: [String: String?] {
        [
            "x-amz-expected-bucket-owner": expectedBucketOwner,
            "x-amz-request-payer": requestPayer?.rawValue
        ]
    }

    var queryItems: [URLQueryItem] {
        [
            .init(name: "x-id", value: "AbortMultipartUpload"),
            .init(name: "uploadId", value: uploadId) // urlPercentEncoding
        ]
    }

    var urlPath: String {
        "/\(key)" // urlPercentEncoding
    }
}

struct AbortMultipartUploadOutputResponse: Equatable {
    // pulled from "x-amz-request-charged" header
    var requestCharged: S3ClientTypes.RequestCharged?
}
