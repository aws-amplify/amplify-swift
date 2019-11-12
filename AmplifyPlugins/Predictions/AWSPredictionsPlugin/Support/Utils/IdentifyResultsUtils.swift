//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSRekognition

class IdentifyResultsUtils {

    static func processLabels(_ rekognitionLabels: [AWSRekognitionLabel]) -> [Label] {
        var labels = [Label]()
        for rekognitionLabel in rekognitionLabels {

            guard let name = rekognitionLabel.name else {
                continue
            }

            let parents = processParents(rekognitionLabel.parents)

            let metadata = LabelMetadata(confidence: Double(
                truncating: rekognitionLabel.confidence ?? 0.0), parents: parents)

            let boundingBoxes = processInstances(rekognitionLabel.instances)

            let label = Label(name: name, metadata: metadata, boundingBoxes: boundingBoxes)

            labels.append(label)
        }
        return labels
    }

    static func processParents(_ rekognitionParents: [AWSRekognitionParent]?) -> [Parent] {
        var parents = [Parent]()
        guard let rekognitionParents = rekognitionParents else {
            return parents
        }

        for parent in rekognitionParents {
            if let name = parent.name {
                parents.append(Parent(name: name))
            }
        }
        return parents
    }

    static func processInstances(_ rekognitionInstances: [AWSRekognitionInstance]?) -> [BoundingBox] {
        var boundingBoxes = [BoundingBox]()
        guard let rekognitionInstances = rekognitionInstances else {
            return boundingBoxes
        }
        for rekognitionInstance in rekognitionInstances {
            guard let height = rekognitionInstance.boundingBox?.height,
                let left = rekognitionInstance.boundingBox?.left,
                let top = rekognitionInstance.boundingBox?.top,
                let width = rekognitionInstance.boundingBox?.width else {
                    continue
            }
            let boundingBox = BoundingBox(
                height: Double(truncating: height),
                left: Double(truncating: left),
                top: Double(truncating: top),
                width: Double(truncating: width))
            boundingBoxes.append(boundingBox)
        }

        return boundingBoxes
    }

    static func processCelebs(_ rekognitionCelebs: [AWSRekognitionCelebrity]) -> [Celebrity] {
        var celebs = [Celebrity]()
        for rekognitionCeleb in rekognitionCelebs {

            guard let name = rekognitionCeleb.name,
                let identifier = rekognitionCeleb.identifier,
                let face = rekognitionCeleb.face,
                let stringUrls = rekognitionCeleb.urls else {
                continue
            }
            var urls = [URL]()
            for url in stringUrls {
                guard let newUrl = URL(string: url) else { continue }

                urls.append(newUrl)
            }

            guard let pitch = face.pose?.pitch, let roll = face.pose?.roll, let yaw = face.pose?.yaw else {
                continue
            }

            let pose = Pose(
                pitch: Double(truncating: pitch),
                roll: Double(truncating: roll),
                yaw: Double(truncating: yaw))

            let metadata = CelebMetadata(name: name, identifier: identifier, urls: urls, pose: pose)

            guard let height = face.boundingBox?.height,
                let left = face.boundingBox?.left,
                let top = face.boundingBox?.top,
                let width = face.boundingBox?.width else {
                    continue
            }

            let boundingBox = BoundingBox(
                height: Double(truncating: height),
                left: Double(truncating: left),
                top: Double(truncating: top),
                width: Double(truncating: width))

            let landmarks = processLandmarks(face.landmarks)

            let celeb = Celebrity(metadata: metadata, boundingBox: boundingBox, landmarks: landmarks)

            celebs.append(celeb)
        }

        return celebs
    }

    static func processLandmarks(_ rekognitionLandmarks: [AWSRekognitionLandmark]?) -> [Landmark] {
        var landmarks = [Landmark]()
        guard let rekognitionLandmarks = rekognitionLandmarks else {
            return landmarks
        }

        for rekognitionLandmark in rekognitionLandmarks {
            guard let xPosition = rekognitionLandmark.x, let yPosition = rekognitionLandmark.y else {
                continue
            }
            let landmark = Landmark(
                type: String(rekognitionLandmark.types.rawValue),
                xPosition: Double(truncating: xPosition),
                yPosition: Double(truncating: yPosition))

            landmarks.append(landmark)

        }

        return landmarks
    }

    static func processCollectionFaces(_ rekognitionFaces: [AWSRekognitionFaceMatch]) -> [CollectionEntity] {
        var entities = [CollectionEntity]()
        for rekognitionFace in rekognitionFaces {

            guard let height = rekognitionFace.face?.boundingBox?.height,
                let left = rekognitionFace.face?.boundingBox?.left,
                let top = rekognitionFace.face?.boundingBox?.top,
                let width = rekognitionFace.face?.boundingBox?.width else {
                    continue
            }
            let boundingBox = BoundingBox(
                height: Double(truncating: height),
                left: Double(truncating: left),
                top: Double(truncating: top),
                width: Double(truncating: width))

            guard let similarity = rekognitionFace.similarity,
                let externalImageId = rekognitionFace.face?.externalImageId else {
                continue
            }
            let metadata = CollectionEntityMetadata(
                externalImageId: externalImageId,
                similarity: Double(truncating: similarity))
            let entity = CollectionEntity(boundingBox: boundingBox, metadata: metadata)

            entities.append(entity)
        }

        return entities
    }

    static func processFaces(_ rekognitionFaces: [AWSRekognitionFaceDetail]) -> [Entity] {
        var entities = [Entity]()
        for rekognitionFace in rekognitionFaces {
            guard let height = rekognitionFace.boundingBox?.height,
                let left = rekognitionFace.boundingBox?.left,
                let top = rekognitionFace.boundingBox?.top,
                let width = rekognitionFace.boundingBox?.width else {
                    continue
            }
            let boundingBox = BoundingBox(
                height: Double(truncating: height),
                left: Double(truncating: left),
                top: Double(truncating: top),
                width: Double(truncating: width))

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

    static func mapEmotion(emotionType: AWSRekognitionEmotionName) -> EmotionType {
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
