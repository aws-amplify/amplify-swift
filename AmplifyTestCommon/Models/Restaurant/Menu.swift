// swiftlint:disable all
import Amplify
import Foundation

public struct Menu: Model {
  public let id: String
  public var name: String
  public var menuType: MenuType?
  public var restaurant: Restaurant?
  public var dishes: List<Dish>?
  
  public init(id: String = UUID().uuidString,
      name: String,
      menuType: MenuType? = nil,
      restaurant: Restaurant? = nil,
      dishes: List<Dish>? = []) {
      self.id = id
      self.name = name
      self.menuType = menuType
      self.restaurant = restaurant
      self.dishes = dishes
  }
}