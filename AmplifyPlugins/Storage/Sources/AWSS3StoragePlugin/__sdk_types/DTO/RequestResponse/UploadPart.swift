//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation


extension UploadPartInput {
    func presignURL(config: S3ClientConfiguration, expiration: Double) throws -> URL {
        fatalError()
    }
}

struct UploadPartInput: Equatable {
    /// This member is required.
    var bucket: String
    /// This member is required.
    var key: String
    /// This member is required.
    var partNumber: Int
    /// This member is required.
    var uploadId: String

    var body: Data?
    var checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm?
    var checksumCRC32: String?
    var checksumCRC32C: String?
    var checksumSHA1: String?
    var checksumSHA256: String?
    var contentLength: Int?
    var contentMD5: String?
    var expectedBucketOwner: String?
    var requestPayer: S3ClientTypes.RequestPayer?
    var sseCustomerAlgorithm: String?
    var sseCustomerKey: String?
    var sseCustomerKeyMD5: String?

    enum CodingKeys: String, CodingKey {
        case body = "Body"
    }

    var _headers: [String: String?] {
        [
            "x-amz-sdk-checksum-algorithm": checksumAlgorithm?.rawValue,
            "x-amz-checksum-crc32": checksumCRC32,
            "x-amz-checksum-crc32c": checksumCRC32C,
            "x-amz-checksum-sha1": checksumSHA1,
            "x-amz-checksum-sha256": checksumSHA256,
            "Content-Length": contentLength.map(String.init),
            "Content-MD5": contentMD5,
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
            .init(name: "x-id", value: "UploadPart"),
            .init(
                name: "partNumber".urlQueryEncoded(),
                value: String(partNumber).urlQueryEncoded()
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

struct UploadPartOutputResponse: Equatable {
    var bucketKeyEnabled: Bool?
    var checksumCRC32: String?
    var checksumCRC32C: String?
    var checksumSHA1: String?
    var checksumSHA256: String?
    var eTag: String?
    var requestCharged: S3ClientTypes.RequestCharged?
    var serverSideEncryption: S3ClientTypes.ServerSideEncryption?
    var sseCustomerAlgorithm: String?
    var sseCustomerKeyMD5: String?
    var ssekmsKeyId: String?
}

extension UploadPartOutputResponse: HeadersApplying {
    func applying(headers: [String: String]) -> Self {
        var copy = self
        copy.bucketKeyEnabled = headers["x-amz-server-side-encryption-bucket-key-enabled"].flatMap(Bool.init)
        copy.checksumCRC32 = headers["x-amz-checksum-crc32"]
        copy.checksumCRC32C = headers["x-amz-checksum-crc32c"]
        copy.checksumSHA1 = headers["x-amz-checksum-sha1"]
        copy.checksumSHA256 = headers["x-amz-checksum-sha256"]
        copy.eTag = headers["ETag"]
        copy.requestCharged = headers["x-amz-request-charged"]
            .flatMap(S3ClientTypes.RequestCharged.init(rawValue:))
        copy.sseCustomerAlgorithm = headers["x-amz-server-side-encryption-customer-algorithm"]
        copy.sseCustomerKeyMD5 = headers["x-amz-server-side-encryption-customer-key-MD5"]
        copy.ssekmsKeyId = headers["x-amz-server-side-encryption-aws-kms-key-id"]
        copy.serverSideEncryption = headers["x-amz-server-side-encryption"]
            .flatMap(S3ClientTypes.ServerSideEncryption.init(rawValue:))
        return copy
    }
}
