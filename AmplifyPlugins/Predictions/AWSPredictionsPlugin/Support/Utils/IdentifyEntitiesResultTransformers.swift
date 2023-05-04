//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSRekognition
import Amplify

enum IdentifyEntitiesResultTransformers {
    static func processFaces(
        _ rekognitionFaces: [RekognitionClientTypes.FaceDetail]
    ) -> [Predictions.Entity] {
        var entities = [Predictions.Entity]()
        for rekognitionFace in rekognitionFaces {

            guard let boundingBox = IdentifyResultTransformers.processBoundingBox(rekognitionFace.boundingBox) else {
                continue
            }
            let landmarks = IdentifyResultTransformers.processLandmarks(rekognitionFace.landmarks)
            let emotions = processEmotions(rekognitionFace.emotions)
            let ageRange = (rekognitionFace.ageRange?.low ?? 0)...(rekognitionFace.ageRange?.high ?? 0)

            let genderAttribute = Predictions.GenderAttribute(
                gender: mapGender(
                    genderType: rekognitionFace.gender?.value ?? .sdkUnknown("") // TODO: don't use .sdkUnknown here
                ),
                confidence: rekognitionFace.gender?.confidence.map(Double.init) ?? 0
            )
            let attributes = processAttributes(face: rekognitionFace)

            guard let pitch = rekognitionFace.pose?.pitch,
                let roll = rekognitionFace.pose?.roll,
                let yaw = rekognitionFace.pose?.yaw else {
                continue
            }

            let pose = Predictions.Pose(
                pitch: Double(pitch),
                roll: Double(roll),
                yaw: Double(yaw)
            )

            let metadata = Predictions.Entity.Metadata(
                confidence: Double(rekognitionFace.confidence ?? 0),
                pose: pose
            )

            let entity = Predictions.Entity(
                boundingBox: boundingBox,
                landmarks: landmarks,
                ageRange: ageRange,
                attributes: attributes,
                gender: genderAttribute,
                metadata: metadata,
                emotions: emotions
            )

            entities.append(entity)
        }
        return entities
    }

    static func processCollectionFaces(
        _ rekognitionFaces: [RekognitionClientTypes.FaceMatch]
    ) -> [Predictions.Entity.Match] {
        var entities = [Predictions.Entity.Match]()
        for rekognitionFace in rekognitionFaces {

            guard let boundingBox = IdentifyResultTransformers.processBoundingBox(rekognitionFace.face?.boundingBox) else {
                continue
            }

            guard let similarity = rekognitionFace.similarity else {
                continue
            }

            let metadata = Predictions.Entity.Match.Metadata(
                externalImageId: rekognitionFace.face?.externalImageId,
                similarity: Double(similarity)
            )
            let entity = Predictions.Entity.Match(boundingBox: boundingBox, metadata: metadata)

            entities.append(entity)
        }

        return entities
    }

    static func processEmotions(
        _ rekognitionEmotions: [RekognitionClientTypes.Emotion]?
    ) -> [Predictions.Emotion] {
        var emotions = [Predictions.Emotion]()
        guard let rekognitionEmotions = rekognitionEmotions
            else {
            return emotions
        }
        for rekognitionEmotion in rekognitionEmotions {
            let emotion = Predictions.Emotion(
                emotion: mapEmotion(emotionType: rekognitionEmotion.type ?? .unknown),
                confidence: rekognitionEmotion.confidence.map(Double.init) ?? 0
            )
            emotions.append(emotion)
        }
        return emotions
    }

    static func processAttributes(face: RekognitionClientTypes.FaceDetail) -> [Predictions.Attribute] {
        var attributes = [Predictions.Attribute]()

        let beard = Predictions.Attribute(
            name: "Beard",
            value: face.beard?.value ?? false,
            confidence: face.beard?.confidence.map(Double.init) ?? 0
        )

        let sunglasses = Predictions.Attribute(
            name: "Sunglasses",
            value: face.sunglasses?.value ?? false,
            confidence: face.sunglasses?.confidence.map(Double.init) ?? 0
        )

        let smile = Predictions.Attribute(
            name: "Smile",
            value: face.smile?.value ?? false,
            confidence: face.smile?.confidence.map(Double.init) ?? 0
        )

        let eyeglasses = Predictions.Attribute(
            name: "EyeGlasses",
            value: face.eyeglasses?.value ?? false,
            confidence: face.eyeglasses?.confidence.map(Double.init) ?? 0
        )

        let mustache = Predictions.Attribute(
            name: "Mustache",
            value: face.mustache?.value ?? false,
            confidence: face.mustache?.confidence.map(Double.init) ?? 0
        )

        let mouthOpen = Predictions.Attribute(
            name: "MouthOpen",
            value: face.mouthOpen?.value ?? false,
            confidence: face.mouthOpen?.confidence.map(Double.init) ?? 0
        )

        let eyesOpen = Predictions.Attribute(
            name: "EyesOpen",
            value: face.eyesOpen?.value ?? false,
            confidence: face.eyesOpen?.confidence.map(Double.init) ?? 0
        )

        attributes.append(beard)
        attributes.append(sunglasses)
        attributes.append(smile)
        attributes.append(eyeglasses)
        attributes.append(mustache)
        attributes.append(mouthOpen)
        attributes.append(eyesOpen)

        return attributes
    }

    static func mapGender(genderType: RekognitionClientTypes.GenderType) -> Predictions.Gender {
        switch genderType {
        case .female:
            return .female
        case .male:
            return .male
        case .sdkUnknown:
            return .unknown
        }
    }

    private static func mapEmotion(emotionType: RekognitionClientTypes.EmotionName) -> Predictions.Emotion.Kind {
        switch emotionType {
        case .angry:
            return .angry
        case .calm:
            return .calm
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
        case .unknown, .sdkUnknown:
            return .unknown
        }
    }
}
