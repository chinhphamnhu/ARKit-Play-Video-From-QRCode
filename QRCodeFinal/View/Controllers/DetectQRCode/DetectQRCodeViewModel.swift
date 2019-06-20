//
//  DetectQRCodeViewModel.swift
//  QRCodeFinal
//
//  Created by Chính Phạm on 6/19/19.
//  Copyright © 2019 Chính Phạm. All rights reserved.
//

import UIKit
import ARKit
import AVFoundation

final class DetectQRCodeViewModel {

    // MARK: - Struct

    struct QRCodeObject {
        var content: String?
        var image: UIImage?
    }

    // MARK: - Properties

    private var qrCodeObjects: [QRCodeObject] = []
}

// MARK: - Public Functions

extension DetectQRCodeViewModel {

    func validateObjectType(objectType: AVMetadataObject.ObjectType) -> Bool {
        return supportedCodeTypes.contains(objectType)
    }

    func appedQRCode(_ object: QRCodeObject) {
        qrCodeObjects.append(object)
    }

    func isExistQRCode(object: QRCodeObject) -> Bool {
        return qrCodeObjects.filter { $0.content == object.content }.count > 0
    }

    func clearData() {
        qrCodeObjects.removeAll()
    }

    func getTrackingImages() -> Set<ARReferenceImage> {
        var trackingImages = Set<ARReferenceImage>()

        _ = qrCodeObjects.map { element in
            if let cgImage = element.image?.cgImage {
                trackingImages.insert(ARReferenceImage(
                    cgImage,
                    orientation: .up,
                    physicalWidth: 0.032))
            }
        }
        return trackingImages
    }
}

// MARK: - Computed Properties

extension DetectQRCodeViewModel {

    var supportedCodeTypes: [AVMetadataObject.ObjectType] {
        return [
            .upce,
            .code39,
            .code39Mod43,
            .code93,
            .code128,
            .ean8,
            .ean13,
            .aztec,
            .pdf417,
            .itf14,
            .dataMatrix,
            .interleaved2of5,
            .qr
        ]
    }
}
