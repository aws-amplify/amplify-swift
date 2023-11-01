//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension S3ClientTypes {
    /// Container for elements related to a part.
    struct Part: Equatable, Decodable {
        /// This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 32-bit CRC32 checksum of the object. For more information, see [Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html) in the Amazon S3 User Guide.
        var checksumCRC32: String?
        /// The base64-encoded, 32-bit CRC32C checksum of the object. This will only be present if it was uploaded with the object. With multipart uploads, this may not be a checksum value of the object. For more information about how checksums are calculated with multipart uploads, see [ Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums) in the Amazon S3 User Guide.
        var checksumCRC32C: String?
        /// The base64-encoded, 160-bit SHA-1 digest of the object. This will only be present if it was uploaded with the object. With multipart uploads, this may not be a checksum value of the object. For more information about how checksums are calculated with multipart uploads, see [ Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums) in the Amazon S3 User Guide.
        var checksumSHA1: String?
        /// This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 256-bit SHA-256 digest of the object. For more information, see [Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html) in the Amazon S3 User Guide.
        var checksumSHA256: String?
        /// Entity tag returned when the part was uploaded.
        var eTag: String?
        /// Date and time at which the part was uploaded.
        var lastModified: Date?
        /// Part number identifying the part. This is a positive integer between 1 and 10,000.
        var partNumber: Int
        /// Size in bytes of the uploaded part data.
        var size: Int?

        enum CodingKeys: String, CodingKey {
            case checksumCRC32 = "ChecksumCRC32"
            case checksumCRC32C = "ChecksumCRC32C"
            case checksumSHA1 = "ChecksumSHA1"
            case checksumSHA256 = "ChecksumSHA256"
            case eTag = "ETag"
            case lastModified = "LastModified"
            case partNumber = "PartNumber"
            case size = "Size"
        }
    }
}
