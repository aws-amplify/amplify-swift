//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTextract

public protocol TextractClientProtocol {
    
    func detectDocumentText(input: DetectDocumentTextInput) async throws -> DetectDocumentTextOutput

    func analyzeDocument(input: AnalyzeDocumentInput) async throws -> AnalyzeDocumentOutput
}

extension TextractClient: TextractClientProtocol { }
