//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

/// The class confirming to AWSS3TransferUtilityBehavior which uses an instance of the AWSS3TransferUtility to
/// perform its methods. This class acts as a wrapper to expose AWSS3TransferUtility functionality through an
/// instance over a singleton, and allows for mocking in unit tests. The methods contain no other logic other than
/// calling the same method using the AWSS3TransferUtility instance.
class AWSS3TransferUtilityAdapter: AWSS3TransferUtilityBehavior {

    let transferUtility: AWSS3TransferUtility

    public init(_ transferUtility: AWSS3TransferUtility) {
        self.transferUtility = transferUtility
    }

    public func downloadData(fromBucket: String,
                             key: String,
                             expression: AWSS3TransferUtilityDownloadExpression,
                             completionHandler: (AWSS3TransferUtilityDownloadCompletionHandlerBlock)?)
        -> AWSTask<AWSS3TransferUtilityDownloadTask> {

            return transferUtility.downloadData(fromBucket: fromBucket,
                                                key: key,
                                                expression: expression,
                                                completionHandler: completionHandler)
    }

    public func download(to fileURL: URL,
                         bucket: String,
                         key: String,
                         expression: AWSS3TransferUtilityDownloadExpression,
                         completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityDownloadTask> {

            return transferUtility.download(to: fileURL,
                                            bucket: bucket,
                                            key: key,
                                            expression: expression,
                                            completionHandler: completionHandler)
    }

    // swiftlint:disable function_parameter_count
    public func uploadData(data: Data,
                           bucket: String,
                           key: String,
                           contentType: String,
                           expression: AWSS3TransferUtilityUploadExpression,
                           completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityUploadTask> {

            return transferUtility.uploadData(data,
                                              bucket: bucket,
                                              key: key,
                                              contentType: contentType,
                                              expression: expression,
                                              completionHandler: completionHandler)
    }

    public func uploadFile(fileURL: URL,
                           bucket: String,
                           key: String,
                           contentType: String,
                           expression: AWSS3TransferUtilityUploadExpression,
                           completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityUploadTask> {

        return transferUtility.uploadFile(fileURL,
                                          bucket: bucket,
                                          key: key,
                                          contentType: contentType,
                                          expression: expression,
                                          completionHandler: completionHandler)
    }

    public func uploadUsingMultiPart(fileURL: URL,
                                     bucket: String,
                                     key: String,
                                     contentType: String,
                                     expression: AWSS3TransferUtilityMultiPartUploadExpression,
                                     completionHandler: AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityMultiPartUploadTask> {

        return transferUtility.uploadUsingMultiPart(fileURL: fileURL,
                                                    bucket: bucket,
                                                    key: key,
                                                    contentType: contentType,
                                                    expression: expression,
                                                    completionHandler: completionHandler)
    }

    public func uploadUsingMultiPart(data: Data,
                                     bucket: String,
                                     key: String,
                                     contentType: String,
                                     expression: AWSS3TransferUtilityMultiPartUploadExpression,
                                     completionHandler: AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityMultiPartUploadTask> {

        return transferUtility.uploadUsingMultiPart(data: data,
                                                    bucket: bucket,
                                                    key: key,
                                                    contentType: contentType,
                                                    expression: expression,
                                                    completionHandler: completionHandler)
    }
}
