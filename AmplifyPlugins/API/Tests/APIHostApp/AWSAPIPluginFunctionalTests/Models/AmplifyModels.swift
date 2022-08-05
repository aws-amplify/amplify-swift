// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "5ee542e5c6ab0424a858288c724b1322"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Post.self)
    ModelRegistry.register(modelType: Comment.self)
    ModelRegistry.register(modelType: Project1.self)
    ModelRegistry.register(modelType: Team1.self)
    ModelRegistry.register(modelType: Project2.self)
    ModelRegistry.register(modelType: Team2.self)
    ModelRegistry.register(modelType: Post3.self)
    ModelRegistry.register(modelType: Comment3.self)
    ModelRegistry.register(modelType: Post4.self)
    ModelRegistry.register(modelType: Comment4.self)
    ModelRegistry.register(modelType: Post5.self)
    ModelRegistry.register(modelType: PostEditor5.self)
    ModelRegistry.register(modelType: User5.self)
    ModelRegistry.register(modelType: Blog6.self)
    ModelRegistry.register(modelType: Post6.self)
    ModelRegistry.register(modelType: Comment6.self)
    ModelRegistry.register(modelType: ScalarContainer.self)
    ModelRegistry.register(modelType: ListIntContainer.self)
    ModelRegistry.register(modelType: ListStringContainer.self)
    ModelRegistry.register(modelType: EnumTestModel.self)
    ModelRegistry.register(modelType: NestedTypeTestModel.self)
  }
}