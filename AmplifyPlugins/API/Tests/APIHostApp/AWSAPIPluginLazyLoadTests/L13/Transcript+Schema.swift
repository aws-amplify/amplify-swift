// swiftlint:disable all
import Amplify
import Foundation

extension Transcript {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case text
    case language
    case phoneCall
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let transcript = Transcript.keys
    
    model.pluralName = "Transcripts"
    
    model.attributes(
      .primaryKey(fields: [transcript.id])
    )
    
    model.fields(
      .field(transcript.id, is: .required, ofType: .string),
      .field(transcript.text, is: .required, ofType: .string),
      .field(transcript.language, is: .optional, ofType: .string),
      .belongsTo(transcript.phoneCall, is: .optional, ofType: PhoneCall.self, targetNames: ["transcriptPhoneCallId"]),
      .field(transcript.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(transcript.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Transcript> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Transcript: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Transcript {
  public var id: FieldPath<String>   {
      string("id")
    }
  public var text: FieldPath<String>   {
      string("text")
    }
  public var language: FieldPath<String>   {
      string("language")
    }
  public var phoneCall: ModelPath<PhoneCall>   {
      PhoneCall.Path(name: "phoneCall", parent: self)
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
