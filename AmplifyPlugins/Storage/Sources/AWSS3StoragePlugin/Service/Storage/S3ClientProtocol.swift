//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import ClientRuntime

protocol S3ClientProtocol {

    /// Performs the `DeleteObject` operation on the `AmazonS3` service.
    ///
    /// Removes an object from a bucket. The behavior depends on the bucket's versioning state:
    ///
    /// * If versioning is enabled, the operation removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects but will still respond that the command was successful.
    ///
    /// * If versioning is suspended or not enabled, the operation permanently deletes the object.
    ///
    ///
    ///
    ///
    /// * Directory buckets - S3 Versioning isn't enabled and supported for directory buckets. For this API operation, only the null value of the version ID is supported by directory buckets. You can only specify null to the versionId query parameter in the request.
    ///
    /// * Directory buckets - For directory buckets, you must make requests for this API operation to the Zonal endpoint. These endpoints support virtual-hosted-style requests in the format https://bucket_name.s3express-az_id.region.amazonaws.com/key-name . Path-style requests are not supported. For more information, see [Regional and Zonal endpoints](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-Regions-and-Zones.html) in the Amazon S3 User Guide.
    ///
    ///
    /// To remove a specific version, you must use the versionId query parameter. Using this query parameter permanently deletes the version. If the object deleted is a delete marker, Amazon S3 sets the response header x-amz-delete-marker to true. If the object you want to delete is in a bucket where the bucket versioning configuration is MFA Delete enabled, you must include the x-amz-mfa request header in the DELETE versionId request. Requests that include x-amz-mfa must use HTTPS. For more information about MFA Delete, see [Using MFA Delete](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMFADelete.html) in the Amazon S3 User Guide. To see sample requests that use versioning, see [Sample Request](https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectDELETE.html#ExampleVersionObjectDelete). Directory buckets - MFA delete is not supported by directory buckets. You can delete objects by explicitly calling DELETE Object or calling ([PutBucketLifecycle](https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycle.html)) to enable Amazon S3 to remove them for you. If you want to block users or accounts from removing or deleting objects from your bucket, you must deny them the s3:DeleteObject, s3:DeleteObjectVersion, and s3:PutLifeCycleConfiguration actions. Directory buckets - S3 Lifecycle is not supported by directory buckets. Permissions
    ///
    /// * General purpose bucket permissions - The following permissions are required in your policies when your DeleteObjects request includes specific headers.
    ///
    /// * s3:DeleteObject - To delete an object from a bucket, you must always have the s3:DeleteObject permission.
    ///
    /// * s3:DeleteObjectVersion - To delete a specific version of an object from a versiong-enabled bucket, you must have the s3:DeleteObjectVersion permission.
    ///
    ///
    ///
    ///
    /// * Directory bucket permissions - To grant access to this API operation on a directory bucket, we recommend that you use the [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html) API operation for session-based authorization. Specifically, you grant the s3express:CreateSession permission to the directory bucket in a bucket policy or an IAM identity-based policy. Then, you make the CreateSession API call on the bucket to obtain a session token. With the session token in your request header, you can make API requests to this operation. After the session token expires, you make another CreateSession API call to generate a new session token for use. Amazon Web Services CLI or SDKs create session and refresh the session token automatically to avoid service interruptions when a session expires. For more information about authorization, see [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html).
    ///
    ///
    /// HTTP Host header syntax Directory buckets - The HTTP Host header syntax is  Bucket_name.s3express-az_id.region.amazonaws.com. The following action is related to DeleteObject:
    ///
    /// * [PutObject](https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html)
    ///
    /// - Parameter DeleteObjectInput : [no documentation found]
    ///
    /// - Returns: `DeleteObjectOutput` : [no documentation found]
    func deleteObject(input: DeleteObjectInput) async throws -> DeleteObjectOutput

    /// Performs the `ListObjectsV2` operation on the `AmazonS3` service.
    ///
    /// Returns some or all (up to 1,000) of the objects in a bucket with each request. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. A 200 OK response can contain valid or invalid XML. Make sure to design your application to parse the contents of the response and handle it appropriately. For more information about listing objects, see [Listing object keys programmatically](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ListingKeysUsingAPIs.html) in the Amazon S3 User Guide. To get a list of your buckets, see [ListBuckets](https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBuckets.html). Directory buckets - For directory buckets, you must make requests for this API operation to the Zonal endpoint. These endpoints support virtual-hosted-style requests in the format https://bucket_name.s3express-az_id.region.amazonaws.com/key-name . Path-style requests are not supported. For more information, see [Regional and Zonal endpoints](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-Regions-and-Zones.html) in the Amazon S3 User Guide. Permissions
    ///
    /// * General purpose bucket permissions - To use this operation, you must have READ access to the bucket. You must have permission to perform the s3:ListBucket action. The bucket owner has this permission by default and can grant this permission to others. For more information about permissions, see [Permissions Related to Bucket Subresource Operations](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources) and [Managing Access Permissions to Your Amazon S3 Resources](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html) in the Amazon S3 User Guide.
    ///
    /// * Directory bucket permissions - To grant access to this API operation on a directory bucket, we recommend that you use the [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html) API operation for session-based authorization. Specifically, you grant the s3express:CreateSession permission to the directory bucket in a bucket policy or an IAM identity-based policy. Then, you make the CreateSession API call on the bucket to obtain a session token. With the session token in your request header, you can make API requests to this operation. After the session token expires, you make another CreateSession API call to generate a new session token for use. Amazon Web Services CLI or SDKs create session and refresh the session token automatically to avoid service interruptions when a session expires. For more information about authorization, see [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html).
    ///
    ///
    /// Sorting order of returned objects
    ///
    /// * General purpose bucket - For general purpose buckets, ListObjectsV2 returns objects in lexicographical order based on their key names.
    ///
    /// * Directory bucket - For directory buckets, ListObjectsV2 does not return objects in lexicographical order.
    ///
    ///
    /// HTTP Host header syntax Directory buckets - The HTTP Host header syntax is  Bucket_name.s3express-az_id.region.amazonaws.com. This section describes the latest revision of this action. We recommend that you use this revised API operation for application development. For backward compatibility, Amazon S3 continues to support the prior version of this API operation, [ListObjects](https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjects.html). The following operations are related to ListObjectsV2:
    ///
    /// * [GetObject](https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html)
    ///
    /// * [PutObject](https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html)
    ///
    /// * [CreateBucket](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html)
    ///
    /// - Parameter ListObjectsV2Input : [no documentation found]
    ///
    /// - Returns: `ListObjectsV2Output` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `NoSuchBucket` : The specified bucket does not exist.
    func listObjectsV2(input: ListObjectsV2Input) async throws -> ListObjectsV2Output

    /// Performs the `CreateMultipartUpload` operation on the `AmazonS3` service.
    ///
    /// This action initiates a multipart upload and returns an upload ID. This upload ID is used to associate all of the parts in the specific multipart upload. You specify this upload ID in each of your subsequent upload part requests (see [UploadPart](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html)). You also include this upload ID in the final request to either complete or abort the multipart upload request. For more information about multipart uploads, see [Multipart Upload Overview](https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html) in the Amazon S3 User Guide. After you initiate a multipart upload and upload one or more parts, to stop being charged for storing the uploaded parts, you must either complete or abort the multipart upload. Amazon S3 frees up the space used to store the parts and stops charging you for storing them only after you either complete or abort a multipart upload. If you have configured a lifecycle rule to abort incomplete multipart uploads, the created multipart upload must be completed within the number of days specified in the bucket lifecycle configuration. Otherwise, the incomplete multipart upload becomes eligible for an abort action and Amazon S3 aborts the multipart upload. For more information, see [Aborting Incomplete Multipart Uploads Using a Bucket Lifecycle Configuration](https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config).
    ///
    /// * Directory buckets - S3 Lifecycle is not supported by directory buckets.
    ///
    /// * Directory buckets - For directory buckets, you must make requests for this API operation to the Zonal endpoint. These endpoints support virtual-hosted-style requests in the format https://bucket_name.s3express-az_id.region.amazonaws.com/key-name . Path-style requests are not supported. For more information, see [Regional and Zonal endpoints](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-Regions-and-Zones.html) in the Amazon S3 User Guide.
    ///
    ///
    /// Request signing For request signing, multipart upload is just a series of regular requests. You initiate a multipart upload, send one or more requests to upload parts, and then complete the multipart upload process. You sign each request individually. There is nothing special about signing multipart upload requests. For more information about signing, see [Authenticating Requests (Amazon Web Services Signature Version 4)](https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html) in the Amazon S3 User Guide. Permissions
    ///
    /// * General purpose bucket permissions - For information about the permissions required to use the multipart upload API, see [Multipart upload and permissions](https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html) in the Amazon S3 User Guide. To perform a multipart upload with encryption by using an Amazon Web Services KMS key, the requester must have permission to the kms:Decrypt and kms:GenerateDataKey* actions on the key. These permissions are required because Amazon S3 must decrypt and read data from the encrypted file parts before it completes the multipart upload. For more information, see [Multipart upload API and permissions](https://docs.aws.amazon.com/AmazonS3/latest/userguide/mpuoverview.html#mpuAndPermissions) and [Protecting data using server-side encryption with Amazon Web Services KMS](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html) in the Amazon S3 User Guide.
    ///
    /// * Directory bucket permissions - To grant access to this API operation on a directory bucket, we recommend that you use the [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html) API operation for session-based authorization. Specifically, you grant the s3express:CreateSession permission to the directory bucket in a bucket policy or an IAM identity-based policy. Then, you make the CreateSession API call on the bucket to obtain a session token. With the session token in your request header, you can make API requests to this operation. After the session token expires, you make another CreateSession API call to generate a new session token for use. Amazon Web Services CLI or SDKs create session and refresh the session token automatically to avoid service interruptions when a session expires. For more information about authorization, see [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html).
    ///
    ///
    /// Encryption
    ///
    /// * General purpose buckets - Server-side encryption is for data encryption at rest. Amazon S3 encrypts your data as it writes it to disks in its data centers and decrypts it when you access it. Amazon S3 automatically encrypts all new objects that are uploaded to an S3 bucket. When doing a multipart upload, if you don't specify encryption information in your request, the encryption setting of the uploaded parts is set to the default encryption configuration of the destination bucket. By default, all buckets have a base level of encryption configuration that uses server-side encryption with Amazon S3 managed keys (SSE-S3). If the destination bucket has a default encryption configuration that uses server-side encryption with an Key Management Service (KMS) key (SSE-KMS), or a customer-provided encryption key (SSE-C), Amazon S3 uses the corresponding KMS key, or a customer-provided key to encrypt the uploaded parts. When you perform a CreateMultipartUpload operation, if you want to use a different type of encryption setting for the uploaded parts, you can request that Amazon S3 encrypts the object with a different encryption key (such as an Amazon S3 managed key, a KMS key, or a customer-provided key). When the encryption setting in your request is different from the default encryption configuration of the destination bucket, the encryption setting in your request takes precedence. If you choose to provide your own encryption key, the request headers you provide in [UploadPart](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html) and [UploadPartCopy](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html) requests must match the headers you used in the CreateMultipartUpload request.
    ///
    /// * Use KMS keys (SSE-KMS) that include the Amazon Web Services managed key (aws/s3) and KMS customer managed keys stored in Key Management Service (KMS) – If you want Amazon Web Services to manage the keys used to encrypt data, specify the following headers in the request.
    ///
    /// * x-amz-server-side-encryption
    ///
    /// * x-amz-server-side-encryption-aws-kms-key-id
    ///
    /// * x-amz-server-side-encryption-context
    ///
    ///
    ///
    ///
    /// * If you specify x-amz-server-side-encryption:aws:kms, but don't provide x-amz-server-side-encryption-aws-kms-key-id, Amazon S3 uses the Amazon Web Services managed key (aws/s3 key) in KMS to protect the data.
    ///
    /// * To perform a multipart upload with encryption by using an Amazon Web Services KMS key, the requester must have permission to the kms:Decrypt and kms:GenerateDataKey* actions on the key. These permissions are required because Amazon S3 must decrypt and read data from the encrypted file parts before it completes the multipart upload. For more information, see [Multipart upload API and permissions](https://docs.aws.amazon.com/AmazonS3/latest/userguide/mpuoverview.html#mpuAndPermissions) and [Protecting data using server-side encryption with Amazon Web Services KMS](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html) in the Amazon S3 User Guide.
    ///
    /// * If your Identity and Access Management (IAM) user or role is in the same Amazon Web Services account as the KMS key, then you must have these permissions on the key policy. If your IAM user or role is in a different account from the key, then you must have the permissions on both the key policy and your IAM user or role.
    ///
    /// * All GET and PUT requests for an object protected by KMS fail if you don't make them by using Secure Sockets Layer (SSL), Transport Layer Security (TLS), or Signature Version 4. For information about configuring any of the officially supported Amazon Web Services SDKs and Amazon Web Services CLI, see [Specifying the Signature Version in Request Authentication](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version) in the Amazon S3 User Guide.
    ///
    ///
    /// For more information about server-side encryption with KMS keys (SSE-KMS), see [Protecting Data Using Server-Side Encryption with KMS keys](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html) in the Amazon S3 User Guide.
    ///
    /// * Use customer-provided encryption keys (SSE-C) – If you want to manage your own encryption keys, provide all the following headers in the request.
    ///
    /// * x-amz-server-side-encryption-customer-algorithm
    ///
    /// * x-amz-server-side-encryption-customer-key
    ///
    /// * x-amz-server-side-encryption-customer-key-MD5
    ///
    ///
    /// For more information about server-side encryption with customer-provided encryption keys (SSE-C), see [ Protecting data using server-side encryption with customer-provided encryption keys (SSE-C)](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerSideEncryptionCustomerKeys.html) in the Amazon S3 User Guide.
    ///
    ///
    ///
    ///
    /// * Directory buckets -For directory buckets, only server-side encryption with Amazon S3 managed keys (SSE-S3) (AES256) is supported.
    ///
    ///
    /// HTTP Host header syntax Directory buckets - The HTTP Host header syntax is  Bucket_name.s3express-az_id.region.amazonaws.com. The following operations are related to CreateMultipartUpload:
    ///
    /// * [UploadPart](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html)
    ///
    /// * [CompleteMultipartUpload](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html)
    ///
    /// * [AbortMultipartUpload](https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html)
    ///
    /// * [ListParts](https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html)
    ///
    /// * [ListMultipartUploads](https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html)
    ///
    /// - Parameter CreateMultipartUploadInput : [no documentation found]
    ///
    /// - Returns: `CreateMultipartUploadOutput` : [no documentation found]
    func createMultipartUpload(input: CreateMultipartUploadInput) async throws -> CreateMultipartUploadOutput

    /// Performs the `ListParts` operation on the `AmazonS3` service.
    ///
    /// Lists the parts that have been uploaded for a specific multipart upload. To use this operation, you must provide the upload ID in the request. You obtain this uploadID by sending the initiate multipart upload request through [CreateMultipartUpload](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html). The ListParts request returns a maximum of 1,000 uploaded parts. The limit of 1,000 parts is also the default value. You can restrict the number of parts in a response by specifying the max-parts request parameter. If your multipart upload consists of more than 1,000 parts, the response returns an IsTruncated field with the value of true, and a NextPartNumberMarker element. To list remaining uploaded parts, in subsequent ListParts requests, include the part-number-marker query string parameter and set its value to the NextPartNumberMarker field value from the previous response. For more information on multipart uploads, see [Uploading Objects Using Multipart Upload](https://docs.aws.amazon.com/AmazonS3/latest/dev/uploadobjusingmpu.html) in the Amazon S3 User Guide. Directory buckets - For directory buckets, you must make requests for this API operation to the Zonal endpoint. These endpoints support virtual-hosted-style requests in the format https://bucket_name.s3express-az_id.region.amazonaws.com/key-name . Path-style requests are not supported. For more information, see [Regional and Zonal endpoints](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-Regions-and-Zones.html) in the Amazon S3 User Guide. Permissions
    ///
    /// * General purpose bucket permissions - For information about permissions required to use the multipart upload API, see [Multipart Upload and Permissions](https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html) in the Amazon S3 User Guide. If the upload was created using server-side encryption with Key Management Service (KMS) keys (SSE-KMS) or dual-layer server-side encryption with Amazon Web Services KMS keys (DSSE-KMS), you must have permission to the kms:Decrypt action for the ListParts request to succeed.
    ///
    /// * Directory bucket permissions - To grant access to this API operation on a directory bucket, we recommend that you use the [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html) API operation for session-based authorization. Specifically, you grant the s3express:CreateSession permission to the directory bucket in a bucket policy or an IAM identity-based policy. Then, you make the CreateSession API call on the bucket to obtain a session token. With the session token in your request header, you can make API requests to this operation. After the session token expires, you make another CreateSession API call to generate a new session token for use. Amazon Web Services CLI or SDKs create session and refresh the session token automatically to avoid service interruptions when a session expires. For more information about authorization, see [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html).
    ///
    ///
    /// HTTP Host header syntax Directory buckets - The HTTP Host header syntax is  Bucket_name.s3express-az_id.region.amazonaws.com. The following operations are related to ListParts:
    ///
    /// * [CreateMultipartUpload](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html)
    ///
    /// * [UploadPart](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html)
    ///
    /// * [CompleteMultipartUpload](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html)
    ///
    /// * [AbortMultipartUpload](https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html)
    ///
    /// * [GetObjectAttributes](https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html)
    ///
    /// * [ListMultipartUploads](https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html)
    ///
    /// - Parameter ListPartsInput : [no documentation found]
    ///
    /// - Returns: `ListPartsOutput` : [no documentation found]
    func listParts(input: ListPartsInput) async throws -> ListPartsOutput

    /// Performs the `CompleteMultipartUpload` operation on the `AmazonS3` service.
    ///
    /// Completes a multipart upload by assembling previously uploaded parts. You first initiate the multipart upload and then upload all parts using the [UploadPart](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html) operation or the [UploadPartCopy](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html) operation. After successfully uploading all relevant parts of an upload, you call this CompleteMultipartUpload operation to complete the upload. Upon receiving this request, Amazon S3 concatenates all the parts in ascending order by part number to create a new object. In the CompleteMultipartUpload request, you must provide the parts list and ensure that the parts list is complete. The CompleteMultipartUpload API operation concatenates the parts that you provide in the list. For each part in the list, you must provide the PartNumber value and the ETag value that are returned after that part was uploaded. The processing of a CompleteMultipartUpload request could take several minutes to finalize. After Amazon S3 begins processing the request, it sends an HTTP response header that specifies a 200 OK response. While processing is in progress, Amazon S3 periodically sends white space characters to keep the connection from timing out. A request could fail after the initial 200 OK response has been sent. This means that a 200 OK response can contain either a success or an error. The error response might be embedded in the 200 OK response. If you call this API operation directly, make sure to design your application to parse the contents of the response and handle it appropriately. If you use Amazon Web Services SDKs, SDKs handle this condition. The SDKs detect the embedded error and apply error handling per your configuration settings (including automatically retrying the request as appropriate). If the condition persists, the SDKs throw an exception (or, for the SDKs that don't use exceptions, they return an error). Note that if CompleteMultipartUpload fails, applications should be prepared to retry the failed requests. For more information, see [Amazon S3 Error Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/dev/ErrorBestPractices.html). You can't use Content-Type: application/x-www-form-urlencoded for the CompleteMultipartUpload requests. Also, if you don't provide a Content-Type header, CompleteMultipartUpload can still return a 200 OK response. For more information about multipart uploads, see [Uploading Objects Using Multipart Upload](https://docs.aws.amazon.com/AmazonS3/latest/dev/uploadobjusingmpu.html) in the Amazon S3 User Guide. Directory buckets - For directory buckets, you must make requests for this API operation to the Zonal endpoint. These endpoints support virtual-hosted-style requests in the format https://bucket_name.s3express-az_id.region.amazonaws.com/key-name . Path-style requests are not supported. For more information, see [Regional and Zonal endpoints](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-Regions-and-Zones.html) in the Amazon S3 User Guide. Permissions
    ///
    /// * General purpose bucket permissions - For information about permissions required to use the multipart upload API, see [Multipart Upload and Permissions](https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html) in the Amazon S3 User Guide.
    ///
    /// * Directory bucket permissions - To grant access to this API operation on a directory bucket, we recommend that you use the [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html) API operation for session-based authorization. Specifically, you grant the s3express:CreateSession permission to the directory bucket in a bucket policy or an IAM identity-based policy. Then, you make the CreateSession API call on the bucket to obtain a session token. With the session token in your request header, you can make API requests to this operation. After the session token expires, you make another CreateSession API call to generate a new session token for use. Amazon Web Services CLI or SDKs create session and refresh the session token automatically to avoid service interruptions when a session expires. For more information about authorization, see [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html).
    ///
    ///
    /// Special errors
    ///
    /// * Error Code: EntityTooSmall
    ///
    /// * Description: Your proposed upload is smaller than the minimum allowed object size. Each part must be at least 5 MB in size, except the last part.
    ///
    /// * HTTP Status Code: 400 Bad Request
    ///
    ///
    ///
    ///
    /// * Error Code: InvalidPart
    ///
    /// * Description: One or more of the specified parts could not be found. The part might not have been uploaded, or the specified ETag might not have matched the uploaded part's ETag.
    ///
    /// * HTTP Status Code: 400 Bad Request
    ///
    ///
    ///
    ///
    /// * Error Code: InvalidPartOrder
    ///
    /// * Description: The list of parts was not in ascending order. The parts list must be specified in order by part number.
    ///
    /// * HTTP Status Code: 400 Bad Request
    ///
    ///
    ///
    ///
    /// * Error Code: NoSuchUpload
    ///
    /// * Description: The specified multipart upload does not exist. The upload ID might be invalid, or the multipart upload might have been aborted or completed.
    ///
    /// * HTTP Status Code: 404 Not Found
    ///
    ///
    ///
    ///
    ///
    /// HTTP Host header syntax Directory buckets - The HTTP Host header syntax is  Bucket_name.s3express-az_id.region.amazonaws.com. The following operations are related to CompleteMultipartUpload:
    ///
    /// * [CreateMultipartUpload](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html)
    ///
    /// * [UploadPart](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html)
    ///
    /// * [AbortMultipartUpload](https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html)
    ///
    /// * [ListParts](https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html)
    ///
    /// * [ListMultipartUploads](https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html)
    ///
    /// - Parameter CompleteMultipartUploadInput : [no documentation found]
    ///
    /// - Returns: `CompleteMultipartUploadOutput` : [no documentation found]
    func completeMultipartUpload(input: CompleteMultipartUploadInput) async throws -> CompleteMultipartUploadOutput

    /// Performs the `AbortMultipartUpload` operation on the `AmazonS3` service.
    ///
    /// This operation aborts a multipart upload. After a multipart upload is aborted, no additional parts can be uploaded using that upload ID. The storage consumed by any previously uploaded parts will be freed. However, if any part uploads are currently in progress, those part uploads might or might not succeed. As a result, it might be necessary to abort a given multipart upload multiple times in order to completely free all storage consumed by all parts. To verify that all parts have been removed and prevent getting charged for the part storage, you should call the [ListParts](https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html) API operation and ensure that the parts list is empty. Directory buckets - For directory buckets, you must make requests for this API operation to the Zonal endpoint. These endpoints support virtual-hosted-style requests in the format https://bucket_name.s3express-az_id.region.amazonaws.com/key-name . Path-style requests are not supported. For more information, see [Regional and Zonal endpoints](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-Regions-and-Zones.html) in the Amazon S3 User Guide. Permissions
    ///
    /// * General purpose bucket permissions - For information about permissions required to use the multipart upload, see [Multipart Upload and Permissions](https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html) in the Amazon S3 User Guide.
    ///
    /// * Directory bucket permissions - To grant access to this API operation on a directory bucket, we recommend that you use the [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html) API operation for session-based authorization. Specifically, you grant the s3express:CreateSession permission to the directory bucket in a bucket policy or an IAM identity-based policy. Then, you make the CreateSession API call on the bucket to obtain a session token. With the session token in your request header, you can make API requests to this operation. After the session token expires, you make another CreateSession API call to generate a new session token for use. Amazon Web Services CLI or SDKs create session and refresh the session token automatically to avoid service interruptions when a session expires. For more information about authorization, see [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html).
    ///
    ///
    /// HTTP Host header syntax Directory buckets - The HTTP Host header syntax is  Bucket_name.s3express-az_id.region.amazonaws.com. The following operations are related to AbortMultipartUpload:
    ///
    /// * [CreateMultipartUpload](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html)
    ///
    /// * [UploadPart](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html)
    ///
    /// * [CompleteMultipartUpload](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html)
    ///
    /// * [ListParts](https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html)
    ///
    /// * [ListMultipartUploads](https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html)
    ///
    /// - Parameter AbortMultipartUploadInput : [no documentation found]
    ///
    /// - Returns: `AbortMultipartUploadOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `NoSuchUpload` : The specified multipart upload does not exist.
    func abortMultipartUpload(input: AbortMultipartUploadInput) async throws -> AbortMultipartUploadOutput

    /// Performs the `HeadObject` operation on the `AmazonS3` service.
    ///
    /// The HEAD operation retrieves metadata from an object without returning the object itself. This operation is useful if you're interested only in an object's metadata. A HEAD request has the same options as a GET operation on an object. The response is identical to the GET response except that there is no response body. Because of this, if the HEAD request generates an error, it returns a generic code, such as 400 Bad Request, 403 Forbidden, 404 Not Found, 405 Method Not Allowed, 412 Precondition Failed, or 304 Not Modified. It's not possible to retrieve the exact exception of these error codes. Request headers are limited to 8 KB in size. For more information, see [Common Request Headers](https://docs.aws.amazon.com/AmazonS3/latest/API/RESTCommonRequestHeaders.html). Directory buckets - For directory buckets, you must make requests for this API operation to the Zonal endpoint. These endpoints support virtual-hosted-style requests in the format https://bucket_name.s3express-az_id.region.amazonaws.com/key-name . Path-style requests are not supported. For more information, see [Regional and Zonal endpoints](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-express-Regions-and-Zones.html) in the Amazon S3 User Guide. Permissions
    ///
    /// * General purpose bucket permissions - To use HEAD, you must have the s3:GetObject permission. You need the relevant read object (or version) permission for this operation. For more information, see [Actions, resources, and condition keys for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/list_amazons3.html) in the Amazon S3 User Guide. If the object you request doesn't exist, the error that Amazon S3 returns depends on whether you also have the s3:ListBucket permission.
    ///
    /// * If you have the s3:ListBucket permission on the bucket, Amazon S3 returns an HTTP status code 404 Not Found error.
    ///
    /// * If you don’t have the s3:ListBucket permission, Amazon S3 returns an HTTP status code 403 Forbidden error.
    ///
    ///
    ///
    ///
    /// * Directory bucket permissions - To grant access to this API operation on a directory bucket, we recommend that you use the [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html) API operation for session-based authorization. Specifically, you grant the s3express:CreateSession permission to the directory bucket in a bucket policy or an IAM identity-based policy. Then, you make the CreateSession API call on the bucket to obtain a session token. With the session token in your request header, you can make API requests to this operation. After the session token expires, you make another CreateSession API call to generate a new session token for use. Amazon Web Services CLI or SDKs create session and refresh the session token automatically to avoid service interruptions when a session expires. For more information about authorization, see [CreateSession](https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateSession.html).
    ///
    ///
    /// Encryption Encryption request headers, like x-amz-server-side-encryption, should not be sent for HEAD requests if your object uses server-side encryption with Key Management Service (KMS) keys (SSE-KMS), dual-layer server-side encryption with Amazon Web Services KMS keys (DSSE-KMS), or server-side encryption with Amazon S3 managed encryption keys (SSE-S3). The x-amz-server-side-encryption header is used when you PUT an object to S3 and want to specify the encryption method. If you include this header in a HEAD request for an object that uses these types of keys, you’ll get an HTTP 400 Bad Request error. It's because the encryption method can't be changed when you retrieve the object. If you encrypt an object by using server-side encryption with customer-provided encryption keys (SSE-C) when you store the object in Amazon S3, then when you retrieve the metadata from the object, you must use the following headers to provide the encryption key for the server to be able to retrieve the object's metadata. The headers are:
    ///
    /// * x-amz-server-side-encryption-customer-algorithm
    ///
    /// * x-amz-server-side-encryption-customer-key
    ///
    /// * x-amz-server-side-encryption-customer-key-MD5
    ///
    ///
    /// For more information about SSE-C, see [Server-Side Encryption (Using Customer-Provided Encryption Keys)](https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html) in the Amazon S3 User Guide. Directory bucket permissions - For directory buckets, only server-side encryption with Amazon S3 managed keys (SSE-S3) (AES256) is supported. Versioning
    ///
    /// * If the current version of the object is a delete marker, Amazon S3 behaves as if the object was deleted and includes x-amz-delete-marker: true in the response.
    ///
    /// * If the specified version is a delete marker, the response returns a 405 Method Not Allowed error and the Last-Modified: timestamp response header.
    ///
    ///
    ///
    ///
    /// * Directory buckets - Delete marker is not supported by directory buckets.
    ///
    /// * Directory buckets - S3 Versioning isn't enabled and supported for directory buckets. For this API operation, only the null value of the version ID is supported by directory buckets. You can only specify null to the versionId query parameter in the request.
    ///
    ///
    /// HTTP Host header syntax Directory buckets - The HTTP Host header syntax is  Bucket_name.s3express-az_id.region.amazonaws.com. The following actions are related to HeadObject:
    ///
    /// * [GetObject](https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html)
    ///
    /// * [GetObjectAttributes](https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html)
    ///
    /// - Parameter HeadObjectInput : [no documentation found]
    ///
    /// - Returns: `HeadObjectOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `NotFound` : The specified content does not exist.
    func headObject(input: HeadObjectInput) async throws -> HeadObjectOutput

}

extension S3Client: S3ClientProtocol { }
