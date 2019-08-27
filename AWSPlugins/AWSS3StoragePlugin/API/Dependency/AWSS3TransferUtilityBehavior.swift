//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

public protocol AWSS3TransferUtilityBehavior {
    func downloadData(fromBucket: String,
                      key: String,
                      expression: AWSS3TransferUtilityDownloadExpression,
                      completionHandler: (AWSS3TransferUtilityDownloadCompletionHandlerBlock)?)
        -> AWSTask<AWSS3TransferUtilityDownloadTask>

    func download(to fileURL: URL,
                  bucket: String,
                  key: String,
                  expression: AWSS3TransferUtilityDownloadExpression,
                  completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityDownloadTask>

    // swiftlint:disable function_parameter_count
    func uploadData(_ data: Data,
                    bucket: String,
                    key: String,
                    contentType: String,
                    expression: AWSS3TransferUtilityUploadExpression,
                    completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityUploadTask>

}
