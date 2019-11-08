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
    let posts: PostConnection?
}

struct Post: Decodable {
    let id: String
    let title: String
    let blog: Blog?
    let comments: CommentConnection?
}

struct Comment: Decodable {
    let id: String
    let content: String?
    let post: Post?
}

struct PostConnection: Decodable {
    let items: [Post]?
    let nextToken: String?
}

struct CommentConnection: Decodable {
    let items: [Comment]?
    let nextToken: String?
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

    class Data: Decodable {
        var createBlog: Blog?
    }
}

class CreatePostMutation {
    static let document = """
        mutation CreatePost($input: CreatePostInput!) {\n
            createPost(input: $input) {\n
                __typename\n
                id\n
                title\n
                blog {\n
                    __typename\n
                    id\n
                    name\n
                    posts {\n
                        __typename\n
                        nextToken\n
                    }\n
                }\n
                comments {\n
                    __typename\n
                    items {\n
                        __typename\n
                        id\n
                        content\n
                    }\n
                    nextToken\n
                }\n
            }\n
        }
        """

    static func variables(postBlogId: String, title: String) -> [String: Any] {
        var input: [String: Any] = [:]
        input.updateValue(postBlogId, forKey: "postBlogId")
        input.updateValue(title, forKey: "title")
        return ["input": input]
    }

    class Data: Decodable {
        var createPost: Post?
    }
}

class CreateCommentMutation {
    static let document = """
        mutation CreateComment($input: CreateCommentInput!) {\n
            createComment(input: $input) {\n
                __typename\n
                id\n
                content\n
                post {\n
                    __typename\n
                    id\n
                    title\n
                    blog {\n
                        __typename\n
                        id\n
                        name\n
                    }\n
                    comments {\n
                        __typename\n
                        nextToken\n
                    }\n
                }\n
            }\n
        }
        """

    static func variables(commentPostId: String, content: String) -> [String: Any] {
        var input: [String: Any] = [:]
        input.updateValue(commentPostId, forKey: "commentPostId")
        input.updateValue(content, forKey: "content")
        return ["input": input]
    }

    class Data: Decodable {
        var createComment: Comment?
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
                        comments {\n
                            __typename\n
                            items {\n
                                __typename\n
                                id\n
                                content\n
                            }\n
                            nextToken\n
                        }\n
                    }\n
                    nextToken\n
                }\n
            }\n
        }
        """

    static func variables(id: String) -> [String: Any] {
        return ["id": id]
    }

    class Data: Decodable {
        var getBlog: Blog?
    }
}
