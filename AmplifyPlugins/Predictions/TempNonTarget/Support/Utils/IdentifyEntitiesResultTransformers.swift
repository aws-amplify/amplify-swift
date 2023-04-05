//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSRekognition
import Amplify

class IdentifyEntitiesResultTransformers: IdentifyResultTransformers {

    static func processFaces(_ rekognitionFaces: [AWSRekognitionFaceDetail]) -> [Entity] {
        var entities = [Entity]()
        for rekognitionFace in rekognitionFaces {

            guard let boundingBox = processBoundingBox(rekognitionFace.boundingBox) else {
                continue
            }
            let landmarks = processLandmarks(rekognitionFace.landmarks)
            let emotions = processEmotions(rekognitionFace.emotions)
            let ageRange = AgeRange(
                low: Int(truncating:
                    rekognitionFace.ageRange?.low ?? 0),
                high: Int(truncating:
                    rekognitionFace.ageRange?.high ?? 0))

            let genderAttribute = GenderAttribute(
                gender: mapGender(genderType:
                    rekognitionFace.gender?.value ?? .unknown),
                confidence: Double(truncating:
                    rekognitionFace.gender?.confidence ?? 0))
            let attributes = processAttributes(face: rekognitionFace)

            guard let pitch = rekognitionFace.pose?.pitch,
                let roll = rekognitionFace.pose?.roll,
                let yaw = rekognitionFace.pose?.yaw else {
                continue
            }

            let pose = Pose(
                pitch: Double(truncating: pitch),
                roll: Double(truncating: roll),
                yaw: Double(truncating: yaw))

            let metadata = EntityMetadata(confidence: Double(truncating: rekognitionFace.confidence ?? 0), pose: pose)

            let entity = Entity(boundingBox: boundingBox,
                                landmarks: landmarks,
                                ageRange: ageRange,
                                attributes: attributes,
                                gender: genderAttribute,
                                metadata: metadata,
                                emotions: emotions)

            entities.append(entity)

        }
        return entities
    }

    static func processCollectionFaces(_ rekognitionFaces: [AWSRekognitionFaceMatch]) -> [EntityMatch] {
        var entities = [EntityMatch]()
        for rekognitionFace in rekognitionFaces {

            guard let boundingBox = processBoundingBox(rekognitionFace.face?.boundingBox) else {
                continue
            }

            guard let similarity = rekognitionFace.similarity else {
                continue
            }

            let metadata = EntityMatchMetadata(
                externalImageId: rekognitionFace.face?.externalImageId,
                similarity: Double(truncating: similarity))
            let entity = EntityMatch(boundingBox: boundingBox, metadata: metadata)

            entities.append(entity)
        }

        return entities
    }

    static func processEmotions(_ rekognitionEmotions: [AWSRekognitionEmotion]?) -> [Emotion] {
        var emotions = [Emotion]()
        guard let rekognitionEmotions = rekognitionEmotions
            else {
            return emotions
        }
        for rekognitionEmotion in rekognitionEmotions {
            let emotion = Emotion(
                emotion: mapEmotion(emotionType: rekognitionEmotion.types),
                confidence: Double(truncating: rekognitionEmotion.confidence ?? 0))
            emotions.append(emotion)
        }

        return emotions
    }

    static func processAttributes(face: AWSRekognitionFaceDetail) -> [Attribute] {
        var attributes = [Attribute]()

        let beard = Attribute(
            name: "Beard",
            value: face.beard?.value == 0 ? false : true,
            confidence: Double(truncating: face.beard?.confidence ?? 0))

        let sunglasses = Attribute(
            name: "Sunglasses",
            value: face.sunglasses?.value == 0 ? false : true,
            confidence: Double(truncating: face.sunglasses?.confidence ?? 0))

        let smile = Attribute(
            name: "Smile",
            value: face.smile?.value == 0 ? false : true,
            confidence: Double(truncating: face.smile?.confidence ?? 0))

        let eyeglasses = Attribute(
            name: "EyeGlasses",
            value: face.eyeglasses?.value == 0 ? false : true,
            confidence: Double(truncating: face.eyeglasses?.confidence ?? 0))

        let mustache = Attribute(
            name: "Mustache",
            value: face.mustache?.value == 0 ? false : true,
            confidence: Double(truncating: face.mustache?.confidence ?? 0))

        let mouthOpen = Attribute(
            name: "MouthOpen",
            value: face.mouthOpen?.value == 0 ? false : true,
            confidence: Double(truncating: face.mouthOpen?.confidence ?? 0))
        let eyesOpen = Attribute(
            name: "EyesOpen",
            value: face.eyesOpen?.value == 0 ? false : true,
            confidence: Double(truncating: face.eyesOpen?.confidence ?? 0))

        attributes.append(beard)
        attributes.append(sunglasses)
        attributes.append(smile)
        attributes.append(eyeglasses)
        attributes.append(mustache)
        attributes.append(mouthOpen)
        attributes.append(eyesOpen)

        return attributes
    }

    static func mapGender(genderType: AWSRekognitionGenderType) -> GenderType {
        switch genderType {
        case .female:
            return .female
        case .male:
            return .male
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    private static func mapEmotion(emotionType: AWSRekognitionEmotionName) -> EmotionType {
        switch emotionType {
        case .angry:
            return .angry
        case .calm:
            return .calm
        case .unknown:
            return .unknown
        case .happy:
            return .happy
        case .sad:
            return .sad
        case .confused:
            return .confused
        case .disgusted:
            return .disgusted
        case .surprised:
            return .surprised
        case .fear:
            return .fear
        @unknown default:
            return .unknown
        }

    }
}
