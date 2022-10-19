// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol.

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "248b0ffa3d44f144554beab3bf489b20"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Post4V2.self)
    ModelRegistry.register(modelType: Comment4V2.self)
    ModelRegistry.register(modelType: Blog8V2.self)
    ModelRegistry.register(modelType: Post8V2.self)
    ModelRegistry.register(modelType: Comment8V2.self)
    ModelRegistry.register(modelType: PostWithCompositeKey.self)
    ModelRegistry.register(modelType: CommentWithCompositeKey.self)
    ModelRegistry.register(modelType: PostWithTagsCompositeKey.self)
    ModelRegistry.register(modelType: TagWithCompositeKey.self)
    ModelRegistry.register(modelType: Project1.self)
    ModelRegistry.register(modelType: Team1.self)
    ModelRegistry.register(modelType: Project2.self)
    ModelRegistry.register(modelType: Team2.self)
    ModelRegistry.register(modelType: Post4.self)
    ModelRegistry.register(modelType: Comment4.self)
    ModelRegistry.register(modelType: Project5.self)
    ModelRegistry.register(modelType: Team5.self)
    ModelRegistry.register(modelType: Project6.self)
    ModelRegistry.register(modelType: Team6.self)
    ModelRegistry.register(modelType: Post7.self)
    ModelRegistry.register(modelType: Comment7.self)
    ModelRegistry.register(modelType: Post8.self)
    ModelRegistry.register(modelType: Comment8.self)
    ModelRegistry.register(modelType: PostTagsWithCompositeKey.self)
  }
}
