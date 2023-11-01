//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

/*
 "DeleteObject":{
   "name":"DeleteObject",
   "http":{
     "method":"DELETE",
     "requestUri":"/{Bucket}/{Key+}",
     "responseCode":204
   },
   "input":{"shape":"DeleteObjectRequest"},
   "output":{"shape":"DeleteObjectOutput"},
   "documentationUrl":"http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html"
 },
 */


/*
 "DeleteObjectRequest":{
   "type":"structure",
   "required":[
     "Bucket",
     "Key"
   ],
   "members":{
     "Bucket":{
       "shape":"BucketName",
       "contextParam":{"name":"Bucket"},
       "location":"uri",
       "locationName":"Bucket"
     },
     "Key":{
       "shape":"ObjectKey",
       "location":"uri",
       "locationName":"Key"
     },
     "MFA":{
       "shape":"MFA",
       "location":"header",
       "locationName":"x-amz-mfa"
     },
     "VersionId":{
       "shape":"ObjectVersionId",
       "location":"querystring",
       "locationName":"versionId"
     },
     "RequestPayer":{
       "shape":"RequestPayer",
       "location":"header",
       "locationName":"x-amz-request-payer"
     },
     "BypassGovernanceRetention":{
       "shape":"BypassGovernanceRetention",
       "location":"header",
       "locationName":"x-amz-bypass-governance-retention"
     },
     "ExpectedBucketOwner":{
       "shape":"AccountId",
       "location":"header",
       "locationName":"x-amz-expected-bucket-owner"
     }
   }
 },
 */

struct DeleteObjectInput: Equatable {
    /// This member is required.
    var bucket: String
    /// This member is required.
    var key: String

    var bypassGovernanceRetention: Bool?
    var expectedBucketOwner: String?
    var mfa: String?
    var requestPayer: S3ClientTypes.RequestPayer?
    var versionId: String?

    var _headers: [String: String?] {
        [
            "x-amz-bypass-governance-retention": bypassGovernanceRetention.map(String.init),
            "x-amz-expected-bucket-owner": expectedBucketOwner,
            "x-amz-mfa": mfa,
            "x-amz-request-payer": requestPayer?.rawValue
        ]
    }

    var headers: [String: String] {
        _headers.compactMapValues { $0 }
    }

    var queryItems: [URLQueryItem] {
        [
            .init(name: "x-id", value: "DeleteObject")
            // versionId...
        ]
    }

    var urlPath: String {
        "/\(key)" //urlPercentEncoding(encodeForwardSlash: false))
    }
}


/*
 "DeleteObjectOutput":{
   "type":"structure",
   "members":{
     "DeleteMarker":{
       "shape":"DeleteMarker",
       "location":"header",
       "locationName":"x-amz-delete-marker"
     },
     "VersionId":{
       "shape":"ObjectVersionId",
       "location":"header",
       "locationName":"x-amz-version-id"
     },
     "RequestCharged":{
       "shape":"RequestCharged",
       "location":"header",
       "locationName":"x-amz-request-charged"
     }
   }
 },
 */
struct DeleteObjectOutputResponse: Equatable {
    var deleteMarker: Bool?
    var requestCharged: S3ClientTypes.RequestCharged?
    var versionId: String?

    /*
     deleteMarker = headers["x-amz-delete-marker"].flatMap(Bool.init)
     requestCharged = headers["x-amz-request-charged"]
        .flatMap(S3ClientTypes.RequestCharged.init(rawValue:))

     versionIdHeaderValue = headers["x-amz-version-id"]
     */
}
