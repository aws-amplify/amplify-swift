//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public class StorageListResult {
    public init(list: [String]) {
        self.list = list
    }
    
    // TODO: Lots more data to be returned. this means lots more configuration to be done.
    /*
     results: <AWSS3ListObjectsV2Output: 0x600002c04b60> {
     contents =     (
     "<AWSS3Object: 0x6000012a4fc0> {\n    ETag = \"\\\"f3278a9347007e7221035a01abbde3fd\\\"\";\n    key = \"public/test-image.png\";\n    lastModified = \"2019-08-14 22:09:01 +0000\";\n    size = 24888381;\n    storageClass = 1;\n}",
     "<AWSS3Object: 0x6000012a50c0> {\n    ETag = \"\\\"d41d8cd98f00b204e9800998ecf8427e\\\"\";\n    key = \"test123/\";\n    lastModified = \"2019-08-12 20:09:22 +0000\";\n    size = 0;\n    storageClass = 1;\n}",
     "<AWSS3Object: 0x6000012a5100> {\n    ETag = \"\\\"cf1878fdfc491e1ac2aa39048f728f32\\\"\";\n    key = testingKey;\n    lastModified = \"2019-08-14 20:53:57 +0000\";\n    size = 320;\n    storageClass = 1;\n}",
     "<AWSS3Object: 0x6000012a5140> {\n    ETag = \"\\\"cf1878fdfc491e1ac2aa39048f728f32\\\"\";\n    key = testingKey2;\n    lastModified = \"2019-08-12 23:27:01 +0000\";\n    size = 320;\n    storageClass = 1;\n}",
     "<AWSS3Object: 0x6000012a5180> {\n    ETag = \"\\\"cf1878fdfc491e1ac2aa39048f728f32\\\"\";\n    key = testingKey3;\n    lastModified = \"2019-08-12 23:32:38 +0000\";\n    size = 320;\n    storageClass = 1;\n}"
     );
     encodingType = 0;
     isTruncated = 0;
     keyCount = 5;
     maxKeys = 1000;
     name = "swiftstoragesample1fd7e03cf4804cdaac1f0d548fbe3aa0-devo";
     prefix = "";
     }
     */
    
    var list: [String]
}



