// swiftlint:disable all
import Amplify
import Foundation

public enum PostStatus: String, EnumPersistable {
  case `private` = "PRIVATE"
  case draft = "DRAFT"
  case published = "PUBLISHED"
}