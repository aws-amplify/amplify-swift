// swiftlint:disable all
import Amplify
import Foundation

public enum PostStatus: String, EnumPersistable {
  case active = "ACTIVE"
  case inactive = "INACTIVE"
}