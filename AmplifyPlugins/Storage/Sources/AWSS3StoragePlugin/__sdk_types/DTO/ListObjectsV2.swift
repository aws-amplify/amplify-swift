//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

struct ListObjectsV2Input: Equatable {
    /// Bucket name to list. When using this action with an access point, you must direct requests to the access point hostname. The access point hostname takes the form AccessPointName-AccountId.s3-accesspoint.Region.amazonaws.com. When using this action with an access point through the Amazon Web Services SDKs, you provide the access point ARN in place of the bucket name. For more information about access point ARNs, see [Using access points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html) in the Amazon S3 User Guide. When you use this action with Amazon S3 on Outposts, you must direct requests to the S3 on Outposts hostname. The S3 on Outposts hostname takes the form  AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com. When you use this action with S3 on Outposts through the Amazon Web Services SDKs, you provide the Outposts access point ARN in place of the bucket name. For more information about S3 on Outposts ARNs, see [What is S3 on Outposts?](https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide.
    /// This member is required.
    var bucket: String?
    /// ContinuationToken indicates to Amazon S3 that the list is being continued on this bucket with a token. ContinuationToken is obfuscated and is not a real key.
    var continuationToken: String?
    /// A delimiter is a character that you use to group keys.
    var delimiter: String?
    /// Encoding type used by Amazon S3 to encode object keys in the response.
    var encodingType: S3ClientTypes.EncodingType?
    /// The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code 403 Forbidden (access denied).
    var expectedBucketOwner: String?
    /// The owner field is not present in ListObjectsV2 by default. If you want to return the owner field with each key in the result, then set the FetchOwner field to true.
    var fetchOwner: Bool?
    /// Sets the maximum number of keys returned in the response. By default, the action returns up to 1,000 key names. The response might contain fewer keys but will never contain more.
    var maxKeys: Int?
    /// Specifies the optional fields that you want returned in the response. Fields that you do not specify are not returned.
    var optionalObjectAttributes: [S3ClientTypes.OptionalObjectAttributes]?
    /// Limits the response to keys that begin with the specified prefix.
    var `prefix`: String?
    /// Confirms that the requester knows that she or he will be charged for the list objects request in V2 style. Bucket owners need not specify this parameter in their requests.
    var requestPayer: S3ClientTypes.RequestPayer?
    /// StartAfter is where you want Amazon S3 to start listing from. Amazon S3 starts listing after this specified key. StartAfter can be any key in the bucket.
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
    /// All of the keys (up to 1,000) rolled up into a common prefix count as a single return when calculating the number of returns. A response can contain CommonPrefixes only if you specify a delimiter. CommonPrefixes contains all (if there are any) keys between Prefix and the next occurrence of the string specified by a delimiter. CommonPrefixes lists keys that act like subdirectories in the directory specified by Prefix. For example, if the prefix is notes/ and the delimiter is a slash (/) as in notes/summer/july, the common prefix is notes/summer/. All of the keys that roll up into a common prefix count as a single return when calculating the number of returns.
    var commonPrefixes: [S3ClientTypes.CommonPrefix]?
    /// Metadata about each object returned.
    var contents: [S3ClientTypes.Object]?
    /// If ContinuationToken was sent with the request, it is included in the response.
    var continuationToken: String?
    /// Causes keys that contain the same string between the prefix and the first occurrence of the delimiter to be rolled up into a single result element in the CommonPrefixes collection. These rolled-up keys are not returned elsewhere in the response. Each rolled-up result counts as only one return against the MaxKeys value.
    var delimiter: String?
    /// Encoding type used by Amazon S3 to encode object key names in the XML response. If you specify the encoding-type request parameter, Amazon S3 includes this element in the response, and returns encoded key name values in the following response elements: Delimiter, Prefix, Key, and StartAfter.
    var encodingType: S3ClientTypes.EncodingType?
    /// Set to false if all of the results were returned. Set to true if more keys are available to return. If the number of results exceeds that specified by MaxKeys, all of the results might not be returned.
    var isTruncated: Bool
    /// KeyCount is the number of keys returned with this request. KeyCount will always be less than or equal to the MaxKeys field. For example, if you ask for 50 keys, your result will include 50 keys or fewer.
    var keyCount: Int
    /// Sets the maximum number of keys returned in the response. By default, the action returns up to 1,000 key names. The response might contain fewer keys but will never contain more.
    var maxKeys: Int
    /// The bucket name. When using this action with an access point, you must direct requests to the access point hostname. The access point hostname takes the form AccessPointName-AccountId.s3-accesspoint.Region.amazonaws.com. When using this action with an access point through the Amazon Web Services SDKs, you provide the access point ARN in place of the bucket name. For more information about access point ARNs, see [Using access points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html) in the Amazon S3 User Guide. When you use this action with Amazon S3 on Outposts, you must direct requests to the S3 on Outposts hostname. The S3 on Outposts hostname takes the form  AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com. When you use this action with S3 on Outposts through the Amazon Web Services SDKs, you provide the Outposts access point ARN in place of the bucket name. For more information about S3 on Outposts ARNs, see [What is S3 on Outposts?](https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide.
    var name: String?
    /// NextContinuationToken is sent when isTruncated is true, which means there are more keys in the bucket that can be listed. The next list requests to Amazon S3 can be continued with this NextContinuationToken. NextContinuationToken is obfuscated and is not a real key
    var nextContinuationToken: String?
    /// Keys that begin with the indicated prefix.
    var `prefix`: String?
    /// If present, indicates that the requester was successfully charged for the request.
    var requestCharged: S3ClientTypes.RequestCharged?
    /// If StartAfter was sent with the request, it is included in the response.
    var startAfter: String?

    init(
        commonPrefixes: [S3ClientTypes.CommonPrefix]? = nil,
        contents: [S3ClientTypes.Object]? = nil,
        continuationToken: String? = nil,
        delimiter: String? = nil,
        encodingType: S3ClientTypes.EncodingType? = nil,
        isTruncated: Bool = false,
        keyCount: Int = 0,
        maxKeys: Int = 0,
        name: String? = nil,
        nextContinuationToken: String? = nil,
        `prefix`: String? = nil,
        requestCharged: S3ClientTypes.RequestCharged? = nil,
        startAfter: String? = nil
    )
    {
        self.commonPrefixes = commonPrefixes
        self.contents = contents
        self.continuationToken = continuationToken
        self.delimiter = delimiter
        self.encodingType = encodingType
        self.isTruncated = isTruncated
        self.keyCount = keyCount
        self.maxKeys = maxKeys
        self.name = name
        self.nextContinuationToken = nextContinuationToken
        self.`prefix` = `prefix`
        self.requestCharged = requestCharged
        self.startAfter = startAfter
    }
}
