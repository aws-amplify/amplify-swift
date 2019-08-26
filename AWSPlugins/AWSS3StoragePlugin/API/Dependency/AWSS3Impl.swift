//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

public class AWSS3Impl : AWSS3Behavior {
    let s3: AWSS3
    
    init(_ s3: AWSS3) {
        self.s3 = s3
    }
    
    public func listObjectsV2(_ request: AWSS3ListObjectsV2Request) -> AWSTask<AWSS3ListObjectsV2Output> {
        return s3.listObjectsV2(request)
    }
    
    public func deleteObject(_ request: AWSS3DeleteObjectRequest) -> AWSTask<AWSS3DeleteObjectOutput> {
        return s3.deleteObject(request)
    }
}


