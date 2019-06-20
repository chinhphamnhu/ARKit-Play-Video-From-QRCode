//
//  DetectQRCodeViewController.swift
//  QRCodeFinal
//
//  Created by Chính Phạm on 6/19/19.
//  Copyright © 2019 Chính Phạm. All rights reserved.
//

import UIKit
import ARKit
import Vision
import CoreImage
import AVFoundation
import SwifterSwift

final class DetectQRCodeViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var sceneView: ARSCNView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var clearDataButton: UIButton!

    // MARK: - Properties
    
    // Common

    private let viewModel = DetectQRCodeViewModel()
    private let configuration = ARImageTrackingConfiguration()

    private var qrCodeObject = DetectQRCodeViewModel.QRCodeObject() {
        didSet {
            imageView.image = qrCodeObject.image
        }
    }
    
    // ARKit

    private var processing = false

    private lazy var qrCodeFrameView: UIView = {
        let view = UIView()
        view.borderColor = .yellow
        view.borderWidth = 2
        view.cornerRadius = 4
        return view
    }()

    // MARK: - Override

    override func viewDidLoad() {
        super.viewDidLoad()
        configARKit()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configTracking()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}

// MARK: - Private Functions

extension DetectQRCodeViewController {

    private func configUI() {
        UIApplication.shared.isIdleTimerDisabled = true
        navigationController?.navigationBar.isHidden = true
        sceneView.addSubview(qrCodeFrameView)
    }

    private func configARKit() {
        sceneView.debugOptions = .showFeaturePoints
        sceneView.delegate = self
        sceneView.session.delegate = self
    }

    private func configTracking() {
        viewModel.appedQRCode(Config.defaultQRCode)
        let scene = SCNScene(named: "art.scnassets/container.scn")!
        sceneView.scene = scene
        configuration.trackingImages = viewModel.getTrackingImages()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    private func renderImage(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let context = CIContext()
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let newSize = CGSize(width: view.width / 2, height: view.height / 2)
            var newImage = UIImage(cgImage: cgImage, scale: 1, orientation: .right)
            newImage = newImage.resizeImage(targetSize: newSize)
            let maskImageView = UIImageView(image: newImage)
            let cropRect = maskImageView.detectEdges()
            return maskImageView.crop(cropRect, andApplyBW: false)
        }

        return nil
    }

    @IBAction private func clearDataButtonTouchUpInside(_ sender: UIButton) {
        viewModel.clearData()
    }
}

// MARK: - ARSCNViewDelegate

extension DetectQRCodeViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        guard
            let imageAnchor = anchor as? ARImageAnchor,
            let container = sceneView.scene.rootNode.childNode(withName: Config.containerNodeName, recursively: false),
            let videoChildNode = container.childNode(withName: Config.videoNodeName, recursively: true)
            else { return }
        
        container.removeFromParentNode()
        node.addChildNode(container)
        container.isHidden = false
        
        // video
        let urlString = qrCodeObject.content ?? "https://www.w3schools.com/html/mov_bbb.mp4"
        if let videoURL = URL(string: urlString) {
            let videoPlayer = AVPlayer(url: videoURL)
            let videoScene = SKScene(size: Config.resolutionVideo)
            let videoNode = SKVideoNode(avPlayer: videoPlayer)
            videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
            videoNode.size = videoScene.size
            videoNode.yScale = -1
            videoNode.play()
            
            videoScene.addChild(videoNode)
            
            videoChildNode.geometry?.firstMaterial?.diffuse.contents = videoScene
            // animations
            if let videoContainer = container.childNode(withName: Config.videoContainerNodeName, recursively: true) {
                let videoActions = SCNAction.sequence([
                    SCNAction.wait(duration: 1.0),
                    SCNAction.scale(to: 1.0, duration: 0.5)])
                videoContainer.runAction(videoActions)
            }
        }
    }
}

// MARK: - ARSessionDelegate

extension DetectQRCodeViewController: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate frame: ARFrame) {

        if processing { return }

        processing = true
        
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            
            guard
                let this = self,
                let results = request.results,
                let result = results.first as? VNBarcodeObservation,
                let content = result.payloadStringValue,
                let image = this.renderImage(from: frame.capturedImage),
                image.size.width < 120 && image.size.height < 120 else {
                    self?.processing = false
                    return
                }

            let object = DetectQRCodeViewModel.QRCodeObject(
                content: content,
                image: image.scaled(toWidth: 150))

            if !this.viewModel.isExistQRCode(object: object) {
                this.viewModel.appedQRCode(object)
                this.qrCodeObject = object
                this.configTracking()
            }

            this.processing = false
        }
        
        DispatchQueue.main.async {
            do {
                request.symbologies = [.QR]
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage)
                try imageRequestHandler.perform([request])
            } catch { }
        }
    }
}

// MARK: - Configure

private struct Config {
    static let containerNodeName = "container"
    static let videoContainerNodeName = "videoContainer"
    static let videoNodeName = "video"
    static let resolutionVideo = CGSize(width: 1280, height: 720)
    static let defaultQRCode = DetectQRCodeViewModel.QRCodeObject(content: "https://www.w3schools.com/html/mov_bbb.mp4", image: #imageLiteral(resourceName: "qrcode.jpg"))
}
