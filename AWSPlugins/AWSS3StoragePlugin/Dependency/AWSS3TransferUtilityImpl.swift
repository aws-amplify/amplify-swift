//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

class AWSS3TransferUtilityImpl: AWSS3TransferUtilityBehavior {

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
    public func uploadData(_ data: Data,
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

    public func uploadFile(_ fileURL: URL,
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
}
