// swiftlint:disable all
import Amplify
import Foundation

extension Post_HasMany_1toM_Case1_v1 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case postID
    case title
    case comments
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let post_HasMany_1toM_Case1_v1 = Post_HasMany_1toM_Case1_v1.keys
    
    model.pluralName = "Post_HasMany_1toM_Case1_v1s"
    
    model.attributes(
      .index(fields: ["postID"], name: nil)
    )
    
    model.fields(
      .id(),
      .field(post_HasMany_1toM_Case1_v1.postID, is: .required, ofType: .string),
      .field(post_HasMany_1toM_Case1_v1.title, is: .required, ofType: .string),
      .hasMany(post_HasMany_1toM_Case1_v1.comments, is: .optional, ofType: Comment_HasMany_1toM_Case1_v1.self, associatedWith: Comment_HasMany_1toM_Case1_v1.keys.postID),
      .field(post_HasMany_1toM_Case1_v1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post_HasMany_1toM_Case1_v1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post_HasMany_1toM_Case2_v1 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case comments
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let post_HasMany_1toM_Case2_v1 = Post_HasMany_1toM_Case2_v1.keys
    
    model.pluralName = "Post_HasMany_1toM_Case2_v1s"
    
    model.fields(
      .id(),
      .field(post_HasMany_1toM_Case2_v1.title, is: .required, ofType: .string),
      .hasMany(post_HasMany_1toM_Case2_v1.comments, is: .optional, ofType: Comment_HasMany_1toM_Case2_v1.self, associatedWith: Comment_HasMany_1toM_Case2_v1.keys.postID),
      .field(post_HasMany_1toM_Case2_v1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post_HasMany_1toM_Case2_v1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post_HasMany_1toM_Case3_v1 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case postID
    case title
    case comments
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let post_HasMany_1toM_Case3_v1 = Post_HasMany_1toM_Case3_v1.keys
    
    model.pluralName = "Post_HasMany_1toM_Case3_v1s"
    
    model.attributes(
      .index(fields: ["postID"], name: nil)
    )
    
    model.fields(
      .id(),
      .field(post_HasMany_1toM_Case3_v1.postID, is: .required, ofType: .string),
      .field(post_HasMany_1toM_Case3_v1.title, is: .required, ofType: .string),
      .hasMany(post_HasMany_1toM_Case3_v1.comments, is: .optional, ofType: Comment_HasMany_1toM_Case3_v1.self, associatedWith: Comment_HasMany_1toM_Case3_v1.keys.postID),
      .field(post_HasMany_1toM_Case3_v1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post_HasMany_1toM_Case3_v1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

