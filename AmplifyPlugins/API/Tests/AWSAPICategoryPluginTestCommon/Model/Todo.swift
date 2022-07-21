//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// TODO: Replace with AmplifyTestCommon's DataStore's geneated model
/// This model corresponds to the resources created for the Todo graphQL endpoint. As a developer, this is
/// hand-written from the codegen that created the API.swift that depends on AppSync sdk.
struct Todo: Decodable {
   let typename: String
   let id: String
   let name: String
   let description: String

   enum CodingKeys: String, CodingKey {
       case typename = "__typename"
       case id
       case name
       case description
   }
}

struct ListTodo: Decodable {
    let typename: String
    let items: [Todo]
    let nextToken: String?

    enum CodingKeys: String, CodingKey {
        case typename = "__typename"
        case items
        case nextToken
    }
}

class CreateTodoMutation {
    static let document = """
        mutation CreateTodo($input: CreateTodoInput!) {\n
            createTodo(input: $input) {\n
                __typename\n
                id\n
                name\n
                description\n
            }\n}
        """

    static func variables(id: String? = nil, name: String, description: String? = nil) -> [String: Any] {
        var input: [String: Any] = [:]

        if let id = id {
            input.updateValue(id, forKey: "id")
        }

        input.updateValue(name, forKey: "name")

        if let description = description {
            input.updateValue(description, forKey: "description")
        }

        return ["input": input]
    }

    static let decodePath = "createTodo"

    class Data: Decodable {
        var createTodo: Todo?
    }
}

class MalformedCreateTodoData: Decodable {
    var createTodo: MalformedTodo?

    class MalformedTodo: Decodable {
        let id: String
        let name2: String
    }
}
class UpdateTodoMutation {
    static let document = """
        mutation UpdateTodo($input: UpdateTodoInput!) {\n
            updateTodo(input: $input) {\n
                __typename\n
                id\n
                name\n
                description\n
        }\n}
        """

    static func variables(id: String, name: String? = nil, description: String? = nil) -> [String: Any] {
        var input: [String: Any] = [:]
        input.updateValue(id, forKey: "id")
        if let name = name {
            input.updateValue(name, forKey: "name")
        }
        if let description = description {
            input.updateValue(description, forKey: "description")
        }
        return ["input": input]
    }

    class Data: Decodable {
        var updateTodo: Todo?
    }
}

class DeleteTodoMutation {
    static let document = """
        mutation DeleteTodo($input: DeleteTodoInput!) {\n
            deleteTodo(input: $input) {\n
            __typename\n
            id\n
            name\n
            description\n
        }\n}
        """

    static func variables(id: String?) -> [String: Any] {
        var input: [String: Any] = [:]
        if let id = id {
            input.updateValue(id, forKey: "id")
        }

        return ["input": input]
    }

    class Data: Decodable {
        var deleteTodo: Todo?
    }
}

class GetTodoQuery {
    static let document = """
        query GetTodo($id: ID!) {\n
            getTodo(id: $id) {\n
            __typename\n
            id\n
            name\n
            description\n
        }\n}
        """

    static func variables(id: String) -> [String: Any] {
       return ["id": id]
    }

    class Data: Decodable {
        var getTodo: Todo?
    }
}

class ListTodosQuery {
    static let document = """
        query ListTodos($filter: ModelTodoFilterInput, $limit: Int, $nextToken: String) {\n
            listTodos(filter: $filter, limit: $limit, nextToken: $nextToken) {\n
                __typename\n
                items {\n
                    __typename\n
                    id\n
                    name\n
                    description\n
                }\n
                nextToken\n
            }\n}
        """

    static func variables(filter: [String: Any]? = nil,
                          limit: Int? = nil,
                          nextToken: String? = nil) -> [String: Any] {
        var input: [String: Any] = [:]

        if let filter = filter {
            input.updateValue(filter, forKey: "filter")
        }

        if let limit = limit {
            input.updateValue(limit, forKey: "limit")
        }

        if let nextToken = nextToken {
            input.updateValue(nextToken, forKey: "nextToken")
        }

        return input
    }

    class Data: Decodable {
        var listTodos: ListTodo?
    }
}

class OnCreateTodoSubscription {
    static let document = """
        subscription OnCreateTodo {\n
            onCreateTodo {\n
                __typename\n
                id\n
                name\n
                description\n
            }\n
        }
        """

    class Data: Decodable {
        var onCreateTodo: Todo?
    }
}

class OnUpdateTodoSubscription {
    static let document = """
        subscription OnUpdateTodo {\n
            onUpdateTodo {\n
                __typename\n
                id\n
                name\n
                description\n
            }\n
        }
        """

    class Data: Decodable {
        var onUpdateTodo: Todo?
    }
}

class OnDeleteTodoSubscription {
    static let document = """
        subscription OnDeleteTodo {\n
            onDeleteTodo {\n
                __typename\n
                id\n
                name\n
                description\n
            }\n
        }
    """

    class Data: Decodable {
        var onDeleteTodo: Todo?
    }
}
