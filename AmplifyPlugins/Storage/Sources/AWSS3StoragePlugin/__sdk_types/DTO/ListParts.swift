//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

struct ListPartsInput: Equatable {
    /// The name of the bucket to which the parts are being uploaded. When using this action with an access point, you must direct requests to the access point hostname. The access point hostname takes the form AccessPointName-AccountId.s3-accesspoint.Region.amazonaws.com. When using this action with an access point through the Amazon Web Services SDKs, you provide the access point ARN in place of the bucket name. For more information about access point ARNs, see [Using access points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html) in the Amazon S3 User Guide. When you use this action with Amazon S3 on Outposts, you must direct requests to the S3 on Outposts hostname. The S3 on Outposts hostname takes the form  AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com. When you use this action with S3 on Outposts through the Amazon Web Services SDKs, you provide the Outposts access point ARN in place of the bucket name. For more information about S3 on Outposts ARNs, see [What is S3 on Outposts?](https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide.
    /// This member is required.
    var bucket: String?
    /// The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code 403 Forbidden (access denied).
    var expectedBucketOwner: String?
    /// Object key for which the multipart upload was initiated.
    /// This member is required.
    var key: String?
    /// Sets the maximum number of parts to return.
    var maxParts: Int?
    /// Specifies the part after which listing should begin. Only parts with higher part numbers will be listed.
    var partNumberMarker: String?
    /// Confirms that the requester knows that they will be charged for the request. Bucket owners need not specify this parameter in their requests. If either the source or destination Amazon S3 bucket has Requester Pays enabled, the requester will pay for corresponding charges to copy the object. For information about downloading objects from Requester Pays buckets, see [Downloading Objects in Requester Pays Buckets](https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html) in the Amazon S3 User Guide.
    var requestPayer: S3ClientTypes.RequestPayer?
    /// The server-side encryption (SSE) algorithm used to encrypt the object. This parameter is needed only when the object was created using a checksum algorithm. For more information, see [Protecting data using SSE-C keys](https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html) in the Amazon S3 User Guide.
    var sseCustomerAlgorithm: String?
    /// The server-side encryption (SSE) customer managed key. This parameter is needed only when the object was created using a checksum algorithm. For more information, see [Protecting data using SSE-C keys](https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html) in the Amazon S3 User Guide.
    var sseCustomerKey: String?
    /// The MD5 server-side encryption (SSE) customer managed key. This parameter is needed only when the object was created using a checksum algorithm. For more information, see [Protecting data using SSE-C keys](https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html) in the Amazon S3 User Guide.
    var sseCustomerKeyMD5: String?
    /// Upload ID identifying the multipart upload whose parts are being listed.
    /// This member is required.
    var uploadId: String?

    init(
        bucket: String? = nil,
        expectedBucketOwner: String? = nil,
        key: String? = nil,
        maxParts: Int? = nil,
        partNumberMarker: String? = nil,
        requestPayer: S3ClientTypes.RequestPayer? = nil,
        sseCustomerAlgorithm: String? = nil,
        sseCustomerKey: String? = nil,
        sseCustomerKeyMD5: String? = nil,
        uploadId: String? = nil
    )
    {
        self.bucket = bucket
        self.expectedBucketOwner = expectedBucketOwner
        self.key = key
        self.maxParts = maxParts
        self.partNumberMarker = partNumberMarker
        self.requestPayer = requestPayer
        self.sseCustomerAlgorithm = sseCustomerAlgorithm
        self.sseCustomerKey = sseCustomerKey
        self.sseCustomerKeyMD5 = sseCustomerKeyMD5
        self.uploadId = uploadId
    }
}


struct ListPartsOutputResponse: Equatable {
    /// If the bucket has a lifecycle rule configured with an action to abort incomplete multipart uploads and the prefix in the lifecycle rule matches the object name in the request, then the response includes this header indicating when the initiated multipart upload will become eligible for abort operation. For more information, see [Aborting Incomplete Multipart Uploads Using a Bucket Lifecycle Configuration](https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config). The response will also include the x-amz-abort-rule-id header that will provide the ID of the lifecycle configuration rule that defines this action.
    var abortDate: Date?
    /// This header is returned along with the x-amz-abort-date header. It identifies applicable lifecycle configuration rule that defines the action to abort incomplete multipart uploads.
    var abortRuleId: String?
    /// The name of the bucket to which the multipart upload was initiated. Does not return the access point ARN or access point alias if used.
    var bucket: String?
    /// The algorithm that was used to create a checksum of the object.
    var checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm?
    /// Container element that identifies who initiated the multipart upload. If the initiator is an Amazon Web Services account, this element provides the same information as the Owner element. If the initiator is an IAM User, this element provides the user ARN and display name.
    var initiator: S3ClientTypes.Initiator?
    /// Indicates whether the returned list of parts is truncated. A true value indicates that the list was truncated. A list can be truncated if the number of parts exceeds the limit returned in the MaxParts element.
    var isTruncated: Bool
    /// Object key for which the multipart upload was initiated.
    var key: String?
    /// Maximum number of parts that were allowed in the response.
    var maxParts: Int
    /// When a list is truncated, this element specifies the last part in the list, as well as the value to use for the part-number-marker request parameter in a subsequent request.
    var nextPartNumberMarker: String?
    /// Container element that identifies the object owner, after the object is created. If multipart upload is initiated by an IAM user, this element provides the parent account ID and display name.
    var owner: S3ClientTypes.Owner?
    /// When a list is truncated, this element specifies the last part in the list, as well as the value to use for the part-number-marker request parameter in a subsequent request.
    var partNumberMarker: String?
    /// Container for elements related to a particular part. A response can contain zero or more Part elements.
    var parts: [S3ClientTypes.Part]?
    /// If present, indicates that the requester was successfully charged for the request.
    var requestCharged: S3ClientTypes.RequestCharged?
    /// Class of storage (STANDARD or REDUCED_REDUNDANCY) used to store the uploaded object.
    var storageClass: S3ClientTypes.StorageClass?
    /// Upload ID identifying the multipart upload whose parts are being listed.
    var uploadId: String?

    init(
        abortDate: Date? = nil,
        abortRuleId: String? = nil,
        bucket: String? = nil,
        checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm? = nil,
        initiator: S3ClientTypes.Initiator? = nil,
        isTruncated: Bool = false,
        key: String? = nil,
        maxParts: Int = 0,
        nextPartNumberMarker: String? = nil,
        owner: S3ClientTypes.Owner? = nil,
        partNumberMarker: String? = nil,
        parts: [S3ClientTypes.Part]? = nil,
        requestCharged: S3ClientTypes.RequestCharged? = nil,
        storageClass: S3ClientTypes.StorageClass? = nil,
        uploadId: String? = nil
    )
    {
        self.abortDate = abortDate
        self.abortRuleId = abortRuleId
        self.bucket = bucket
        self.checksumAlgorithm = checksumAlgorithm
        self.initiator = initiator
        self.isTruncated = isTruncated
        self.key = key
        self.maxParts = maxParts
        self.nextPartNumberMarker = nextPartNumberMarker
        self.owner = owner
        self.partNumberMarker = partNumberMarker
        self.parts = parts
        self.requestCharged = requestCharged
        self.storageClass = storageClass
        self.uploadId = uploadId
    }

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
}
