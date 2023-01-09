//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import AWSAPIPlugin
import AWSPluginsCore
import Amplify

public extension AsyncSequence {
    func forEach(_ block: (Element) async throws -> Void) async rethrows {
        for try await element in self {
            try await block(element)
        }
    }
}

class SubscriptionViewModel: ObservableObject {
    
    @Published var todos = [Todo]()
    let apiPlugin = AWSAPIPlugin()

    func subscribe() async {
        do {
            let subscription = apiPlugin.subscribe(request: .subscription(of: Todo.self, type: .onCreate))
            try await subscription.forEach { subscriptionEvent in
                await self.processSubscription(subscriptionEvent)
            }
                    
        } catch {
            print("Failed to subscribe error: \(error)")
        }
    }
    
    func processSubscription(_ subscriptionEvent: GraphQLSubscriptionEvent<Todo>) async {
        switch subscriptionEvent {
        case .connection(let subscriptionConnectionState):
            print("Subscription connect state is \(subscriptionConnectionState)")
        case .data(let result):
            switch result {
            case .success(let createdTodo):
                print("Successfully got todo from subscription: \(createdTodo)")
                await storeTodo(createdTodo)
            case .failure(let error):
                print("Got failed result with \(error.errorDescription)")
            }
        }
    }
    
    @MainActor
    func storeTodo(_ todo: Todo) async {
        self.todos.append(todo)
    }
}
struct SubscriptionView: View {
    @StateObject var vm = SubscriptionViewModel()
    
    var body: some View {
        if #available(iOS 15.0, *) {
            VStack {
                
            }.task { await vm.subscribe() }
            
        } else {
            // Fallback on earlier versions
            Text("task is on iOS 15.0")
        }
        
    }
    
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
    }
}

public struct Todo: Model {
    public let id: String
    public var name: String
    public var description: String?

    public init(id: String = UUID().uuidString,
                name: String,
                description: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
    }
}

extension Todo {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case description
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let todo = Todo.keys

    model.listPluralName = "Todos"
    model.syncPluralName = "Todos"

    model.fields(
      .id(),
      .field(todo.name, is: .required, ofType: .string),
      .field(todo.description, is: .optional, ofType: .string))
    }
}
