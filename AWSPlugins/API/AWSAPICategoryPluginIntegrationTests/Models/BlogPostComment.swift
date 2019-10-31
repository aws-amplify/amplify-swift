//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct Blog: Decodable {
    let id: String
    let name: String
    let posts: PostConnection
}

struct PostConnection: Decodable {
    let items: [Post]
    let nextToken: String
}

struct Posts: Decodable {
    let posts: [Post]
}

struct Post: Decodable {
    let id: String
    let title: String
}

struct Comment: Decodable {
    let id: String
    let content: String?
    let post: Post
}


class CreateBlogMutation {
    static let document = """
        mutation CreateBlog($input: CreateBlogInput!) {\n
            createBlog(input: $input) {\n
                __typename\n
                id\n
                name\n
                posts {\n
                    __typename\n
                    items {\n
                        __typename\n
                        id\n
                        title\n
                    }\n
                    nextToken\n
                }\n
        }\n}
        """

    static func variables(id: String?, name: String) -> [String: Any] {
        var input: [String: Any] = [:]
        if let id = id {
            input.updateValue(id, forKey: "id")
        }

        input.updateValue(name, forKey: "name")

        return ["input": input]
    }

    static let responseType = CreateBlogMutationResponse()

    class CreateBlogMutationResponse: ResponseType {
        typealias SerializedObject = Blog
    }
}


class GetBlogQuery {
    static let document = """
        query GetBlog($id: ID!) {\n
            getBlog(id: $id) {\n
                __typename\n
                id\n
                name\n
                posts {\n
                    __typename\n
                    items {\n
                        __typename\n
                        id\n
                        title\n
                    }\n
                nextToken\n
                }\n
        }\n}
        """

    static func variables(id: String) -> [String: Any] {
        return ["id": id]
    }


    static let responseType = GetBlogQueryResponse()

    class GetBlogQueryResponse: ResponseType {
        typealias SerializedObject = Blog
    }
}
