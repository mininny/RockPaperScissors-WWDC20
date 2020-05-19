//
//  ARViewController.swift
//
//  Created by Minhyuk Kim on 2020/05/18.
//  Copyright © 2020 Minhyuk Kim. All rights reserved.
//

import UIKit
import Vision
import ARKit
import PlaygroundSupport
import RPS

@objc(Core_ARViewController)
public class ARViewController: UIViewController, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer {
    
    @IBOutlet weak var detectedLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.debugOptions = [.showFeaturePoints, .showPhysicsShapes]
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
        
    }
    
    // MARK: - Vision classification
    // Vision classification request and model
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // Instantiate the model from its generated Swift class.
            let mlmodel = try VNCoreMLModel(for: RPSModel().model)
            let request = VNCoreMLRequest(model: mlmodel, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })

            // Crop input images to square area at center, matching the way the ML model was trained.
            request.imageCropAndScaleOption = .centerCrop

            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()

    // The pixel buffer being held for analysis; used to serialize Vision requests.
    private var currentBuffer: CVPixelBuffer?

    // Queue for dispatching vision classification requests
    private let visionQueue = DispatchQueue(label: "com.mininny.wwdc20.playgroundbook.visionqueue")

    // Run the Vision+ML classifier on the current image buffer.
    private func classifyCurrentImage() {
        let orientation = exifOrientationFromDeviceOrientation()
        
        if let currentBuffer = self.currentBuffer {
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer, orientation: orientation)
            visionQueue.async {
                defer { self.currentBuffer = nil }
                try? requestHandler.perform([self.classificationRequest])
            }
        }
    }

    // Handle completion of the Vision request and choose results to display.
    func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results else {
            print("Unable to classify image.\n\(error!.localizedDescription)")
            return
        }
        // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
        if let classifications = results as? [VNClassificationObservation] {
            DispatchQueue.main.async {
                if let bestResult = classifications.filter({ $0.confidence > 0.33 }).max(by: { $0.confidence < $1.confidence }) {
                    switch bestResult.identifier {
                    case "Rock":
                        self.detectedLabel.text = RPS.rock.asEmoji
                        self.confidenceLabel.text = "\(Double(bestResult.confidence*1000)/1000)"
                    case "Paper":
                        self.detectedLabel.text = RPS.paper.asEmoji
                        self.confidenceLabel.text = "\(Double(bestResult.confidence*1000)/1000)"
                    case "Scissors":
                        self.detectedLabel.text = RPS.scissors.asEmoji
                        self.confidenceLabel.text = "\(Double(bestResult.confidence*1000)/1000)"
                    default: break
                    }
                }
            }
        }
    }
}

extension ARViewController: ARSessionDelegate, ARSCNViewDelegate {
    // Pass camera frames received from ARKit to Vision (when not already processing one)
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do not enqueue other buffers for processing while another Vision task is still running.
        // The camera stream has only a finite amount of buffers available; holding too many buffers for analysis would starve the camera.
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }

        // Retain the image buffer for Vision processing.
        self.currentBuffer = frame.capturedImage
        classifyCurrentImage()
    }
}

public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
    let curDeviceOrientation = UIDevice.current.orientation
    let exifOrientation: CGImagePropertyOrientation

    switch curDeviceOrientation {
    case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, Home button on the top
        exifOrientation = .left
    case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, Home button on the right
        exifOrientation = .upMirrored
    case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, Home button on the left
        exifOrientation = .down
    case UIDeviceOrientation.portrait:            // Device oriented vertically, Home button on the bottom
        exifOrientation = .up
    default:
        exifOrientation = .up
    }
    return exifOrientation
}
