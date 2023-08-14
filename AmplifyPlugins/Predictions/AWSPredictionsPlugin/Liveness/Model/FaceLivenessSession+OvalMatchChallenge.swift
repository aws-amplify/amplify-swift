//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FaceLivenessSession {
    @_spi(PredictionsFaceLiveness)
    public struct OvalMatchChallenge {
        public let faceDetectionThreshold: Double
        public let face: Face
        public let oval: Oval

        public init(faceDetectionThreshold: Double, face: Face, oval: Oval) {
            self.faceDetectionThreshold = faceDetectionThreshold
            self.face = face
            self.oval = oval
        }
    }
}

extension FaceLivenessSession.OvalMatchChallenge {
    @_spi(PredictionsFaceLiveness)
    public struct Face {
        public let distanceThreshold: Double
        public let distanceThresholdMax: Double
        public let distanceThresholdMin: Double
        public let iouWidthThreshold: Double
        public let iouHeightThreshold: Double

        public init(
            distanceThreshold: Double,
            distanceThresholdMax: Double,
            distanceThresholdMin: Double,
            iouWidthThreshold: Double,
            iouHeightThreshold: Double
        ) {
            self.distanceThreshold = distanceThreshold
            self.distanceThresholdMax = distanceThresholdMax
            self.distanceThresholdMin = distanceThresholdMin
            self.iouWidthThreshold = iouWidthThreshold
            self.iouHeightThreshold = iouHeightThreshold
        }
    }
}

extension FaceLivenessSession.OvalMatchChallenge {
    @_spi(PredictionsFaceLiveness)
    public struct Oval {
        public let boundingBox: FaceLivenessSession.BoundingBox
        public let heightWidthRatio: Double
        public let iouThreshold: Double
        public let iouWidthThreshold: Double
        public let iouHeightThreshold: Double
        public let ovalFitTimeout: Double

        public init(
            boundingBox: FaceLivenessSession.BoundingBox,
            heightWidthRatio: Double,
            iouThreshold: Double,
            iouWidthThreshold: Double,
            iouHeightThreshold: Double,
            ovalFitTimeout: Double
        ) {
            self.boundingBox = boundingBox
            self.heightWidthRatio = heightWidthRatio
            self.iouThreshold = iouThreshold
            self.iouWidthThreshold = iouWidthThreshold
            self.iouHeightThreshold = iouHeightThreshold
            self.ovalFitTimeout = ovalFitTimeout
        }
    }
}
