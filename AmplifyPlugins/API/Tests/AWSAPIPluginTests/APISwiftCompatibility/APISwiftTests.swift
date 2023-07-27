//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

final class APISwiftTests: XCTestCase {

    func testCreateBlogMutation() {
        let file = S3ObjectInput(bucket: "bucket", key: "let", region: "region")
        let input = CreateBlogInput(name: "name", file: file)
        let condition = ModelBlogConditionInput(name: .init(eq: "name"))
        let mutation = CreateBlogMutation(input: input)
        
        let request = GraphQLRequest<CreateBlogMutation.Data>(
            document: CreateBlogMutation.requestString,
            variables: mutation.variables?.jsonObject,
            responseType: CreateBlogMutation.Data.self)
        
        var expectedDocument = """
        mutation CreateBlog($input: CreateBlogInput!, $condition: ModelBlogConditionInput) {
          createBlog(input: $input, condition: $condition) {
            __typename
            id
            name
            posts {
              __typename
              nextToken
              startedAt
            }
            file {
              __typename
              ...S3Object
            }
            createdAt
            updatedAt
            _version
            _deleted
            _lastChangedAt
          }
        }fragment S3Object on S3Object {
          __typename
          bucket
          key
          region
        }
        """
        XCTAssertEqual(expectedDocument, request.document)
    }

}
