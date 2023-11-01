//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    /// An object consists of data and its descriptive metadata.
    struct Object: Equatable {
        /// The algorithm that was used to create a checksum of the object.
        var checksumAlgorithm: [S3ClientTypes.ChecksumAlgorithm]?
        /// The entity tag is a hash of the object. The ETag reflects changes only to the contents of an object, not its metadata. The ETag may or may not be an MD5 digest of the object data. Whether or not it is depends on how the object was created and how it is encrypted as described below:
        ///
        /// * Objects created by the PUT Object, POST Object, or Copy operation, or through the Amazon Web Services Management Console, and are encrypted by SSE-S3 or plaintext, have ETags that are an MD5 digest of their object data.
        ///
        /// * Objects created by the PUT Object, POST Object, or Copy operation, or through the Amazon Web Services Management Console, and are encrypted by SSE-C or SSE-KMS, have ETags that are not an MD5 digest of their object data.
        ///
        /// * If an object is created by either the Multipart Upload or Part Copy operation, the ETag is not an MD5 digest, regardless of the method of encryption. If an object is larger than 16 MB, the Amazon Web Services Management Console will upload or copy that object as a Multipart Upload, and therefore the ETag will not be an MD5 digest.
        var eTag: String?
        /// The name that you assign to an object. You use the object key to retrieve the object.
        var key: String?
        /// Creation date of the object.
        var lastModified: Date?
        /// The owner of the object
        var owner: S3ClientTypes.Owner?
        /// Specifies the restoration status of an object. Objects in certain storage classes must be restored before they can be retrieved. For more information about these storage classes and how to work with archived objects, see [ Working with archived objects](https://docs.aws.amazon.com/AmazonS3/latest/userguide/archived-objects.html) in the Amazon S3 User Guide.
        var restoreStatus: S3ClientTypes.RestoreStatus?
        /// Size in bytes of the object
        var size: Int
        /// The class of storage used to store the object.
        var storageClass: S3ClientTypes.ObjectStorageClass?

        init(
            checksumAlgorithm: [S3ClientTypes.ChecksumAlgorithm]? = nil,
            eTag: String? = nil,
            key: String? = nil,
            lastModified: Date? = nil,
            owner: S3ClientTypes.Owner? = nil,
            restoreStatus: S3ClientTypes.RestoreStatus? = nil,
            size: Int = 0,
            storageClass: S3ClientTypes.ObjectStorageClass? = nil
        )
        {
            self.checksumAlgorithm = checksumAlgorithm
            self.eTag = eTag
            self.key = key
            self.lastModified = lastModified
            self.owner = owner
            self.restoreStatus = restoreStatus
            self.size = size
            self.storageClass = storageClass
        }

        enum CodingKeys: String, CodingKey {
            case checksumAlgorithm = "ChecksumAlgorithm"
            case eTag = "ETag"
            case key = "Key"
            case lastModified = "LastModified"
            case owner = "Owner"
            case restoreStatus = "RestoreStatus"
            case size = "Size"
            case storageClass = "StorageClass"
        }
    }

}
