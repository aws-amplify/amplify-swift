//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation


struct DeleteObjectInput: Equatable {
    /// The bucket name of the bucket containing the object. When using this action with an access point, you must direct requests to the access point hostname. The access point hostname takes the form AccessPointName-AccountId.s3-accesspoint.Region.amazonaws.com. When using this action with an access point through the Amazon Web Services SDKs, you provide the access point ARN in place of the bucket name. For more information about access point ARNs, see [Using access points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html) in the Amazon S3 User Guide. When you use this action with Amazon S3 on Outposts, you must direct requests to the S3 on Outposts hostname. The S3 on Outposts hostname takes the form  AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com. When you use this action with S3 on Outposts through the Amazon Web Services SDKs, you provide the Outposts access point ARN in place of the bucket name. For more information about S3 on Outposts ARNs, see [What is S3 on Outposts?](https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide.
    /// This member is required.
    var bucket: String?
    /// Indicates whether S3 Object Lock should bypass Governance-mode restrictions to process this operation. To use this header, you must have the s3:BypassGovernanceRetention permission.
    var bypassGovernanceRetention: Bool?
    /// The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code 403 Forbidden (access denied).
    var expectedBucketOwner: String?
    /// Key name of the object to delete.
    /// This member is required.
    var key: String?
    /// The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device. Required to permanently delete a versioned object if versioning is configured with MFA delete enabled.
    var mfa: String?
    /// Confirms that the requester knows that they will be charged for the request. Bucket owners need not specify this parameter in their requests. If either the source or destination Amazon S3 bucket has Requester Pays enabled, the requester will pay for corresponding charges to copy the object. For information about downloading objects from Requester Pays buckets, see [Downloading Objects in Requester Pays Buckets](https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html) in the Amazon S3 User Guide.
    var requestPayer: S3ClientTypes.RequestPayer?
    /// VersionId used to reference a specific version of the object.
    var versionId: String?

    init(
        bucket: String? = nil,
        bypassGovernanceRetention: Bool? = nil,
        expectedBucketOwner: String? = nil,
        key: String? = nil,
        mfa: String? = nil,
        requestPayer: S3ClientTypes.RequestPayer? = nil,
        versionId: String? = nil
    )
    {
        self.bucket = bucket
        self.bypassGovernanceRetention = bypassGovernanceRetention
        self.expectedBucketOwner = expectedBucketOwner
        self.key = key
        self.mfa = mfa
        self.requestPayer = requestPayer
        self.versionId = versionId
    }
}

struct DeleteObjectOutputResponse: Equatable {
    /// Indicates whether the specified object version that was permanently deleted was (true) or was not (false) a delete marker before deletion. In a simple DELETE, this header indicates whether (true) or not (false) the current version of the object is a delete marker.
    var deleteMarker: Bool
    /// If present, indicates that the requester was successfully charged for the request.
    var requestCharged: S3ClientTypes.RequestCharged?
    /// Returns the version ID of the delete marker created as a result of the DELETE operation.
    var versionId: String?

    init(
        deleteMarker: Bool = false,
        requestCharged: S3ClientTypes.RequestCharged? = nil,
        versionId: String? = nil
    )
    {
        self.deleteMarker = deleteMarker
        self.requestCharged = requestCharged
        self.versionId = versionId
    }
}

/*
 extension DeleteObjectOutputResponse: ClientRuntime.HttpResponseBinding {
     init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder? = nil) async throws {
         if let deleteMarkerHeaderValue = httpResponse.headers.value(for: "x-amz-delete-marker") {
             self.deleteMarker = Swift.Bool(deleteMarkerHeaderValue) ?? false
         } else {
             self.deleteMarker = false
         }
         if let requestChargedHeaderValue = httpResponse.headers.value(for: "x-amz-request-charged") {
             self.requestCharged = S3ClientTypes.RequestCharged(rawValue: requestChargedHeaderValue)
         } else {
             self.requestCharged = nil
         }
         if let versionIdHeaderValue = httpResponse.headers.value(for: "x-amz-version-id") {
             self.versionId = versionIdHeaderValue
         } else {
             self.versionId = nil
         }
     }
 }
 */
