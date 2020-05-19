//
//  ARRPSViewController.swift
//
//  Created by Minhyuk Kim on 2020/05/18.
//  Copyright © 2020 Minhyuk Kim. All rights reserved.
//
import UIKit
import Vision
import ARKit
import PlaygroundSupport
import RPS

@objc(Core_ARRPSViewController)
public class ARRPSViewController: UIViewController, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var modelChoiceLabel: UILabel!
    
    @IBAction func didSelectModel(_ sender: Any) {
        guard let control = sender as? UISegmentedControl else { return }
        
        switch control.selectedSegmentIndex {
        case 0:
            if self.model is PsychologicalModel { self.model = MarkovModel() }
            self.showDataView.isHidden = false
        case 1:
            if self.model is MarkovModel { self.model = PsychologicalModel() }
            self.showDataView.isHidden = true
        default: break
        }
    }
    @IBOutlet weak var winPercentageLabel: UILabel!
    @IBOutlet weak var modelWinPercentageLabel: UILabel!
    
    @IBOutlet weak var myChoiceLabel: UILabel!
    @IBOutlet weak var myChoiceConfidenceLabel: UILabel!
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet var timerView: UIView!
    
    @IBOutlet weak var startGameButton: UIButton!
    @IBAction func didPressStartGame(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        
        button.isHidden = true
        self.statusLabel.isHidden = false
        self.isGameOngoing = true
        
        self.runTimer()
    }
    
    @IBOutlet weak var endGameButton: UIButton!
    @IBAction func didPressEndGame(_ sender: Any) {
        self.statusLabel.text = ""
        
        self.timerView.isHidden = true
        self.gameTimer?.invalidate()
        self.isGameOngoing = false
        self.startGameButton.isHidden = false
        
        self.winHistory = []
    }
    
    
    @IBOutlet weak var RR_Label: UILabel!
    @IBOutlet weak var RP_Label: UILabel!
    @IBOutlet weak var RS_Label: UILabel!
    
    @IBOutlet weak var PR_Label: UILabel!
    @IBOutlet weak var PP_Label: UILabel!
    @IBOutlet weak var PS_Label: UILabel!
    
    @IBOutlet weak var SR_Label: UILabel!
    @IBOutlet weak var SP_Label: UILabel!
    @IBOutlet weak var SS_Label: UILabel!
    
    @IBOutlet var R_Label: UILabel!
    @IBOutlet var P_Label: UILabel!
    
    @IBOutlet var S_Label: UILabel!
    
    @IBOutlet var R_Labels: [UILabel]!
    @IBOutlet var P_Labels: [UILabel]!
    @IBOutlet var S_Labels: [UILabel]!
    
    @IBOutlet var dataViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var showDataView: UIView!
    @IBAction func didToggleShowData(_ sender: Any) {
        guard let toggle = sender as? UISwitch else { return }
        
        if toggle.isOn {
            self.dataViewHeightConstraint.constant = 100
            self.view.layoutIfNeeded()
        } else {
            self.dataViewHeightConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    
    var currentChoice = RPS.rock
    var gameTimer: Timer?
    var isGameOngoing = false {
        didSet {
            if self.isGameOngoing {
                self.endGameButton.isHidden = false
            } else {
                self.endGameButton.isHidden = true
            }
        }
    }
    
    func runTimer() {
        guard self.isGameOngoing else { return }
        
        var count = 0
        self.timerView.isHidden = false
        self.gameTimer = Timer.scheduledTimer(withTimeInterval: 0.125, repeats: true) { timer in
            if count >= 30 {
                self.selectChoice(self.currentChoice)
                self.timerView.isHidden = true
                timer.invalidate()
            }
            DispatchQueue.main.async {
                let num = (30-Double(count)) * 100 / 1000
                self.timerLabel.text = "\(num > 0 ? num : 0)"
            }
            count += 1
        }
        gameTimer?.fire()
    }
    
    var model: RPSable! {
        didSet {
            self.modelWinPercentageLabel.text = ""
            self.winPercentageLabel.text = ""
            self.statusLabel.text = ""
            
            self.RR_Label.text = "0"
            self.RS_Label.text = "0"
            self.RP_Label.text = "0"
            
            self.PR_Label.text = "0"
            self.PS_Label.text = "0"
            self.PP_Label.text = "0"
            
            self.SR_Label.text = "0"
            self.SS_Label.text = "0"
            self.SP_Label.text = "0"
            
            
            self.timerView.isHidden = true
            self.gameTimer?.invalidate()
            self.isGameOngoing = false
            self.startGameButton.isHidden = false
            
            self.winHistory = []
        }
    }
    
    var winHistory = [RPS.Result]() {
        didSet {
            guard self.winHistory.count > 0 else {
                self.modelWinPercentageLabel.text = ""
                self.winPercentageLabel.text = ""
                return
            }
            
            let winCount = self.winHistory.filter({ $0 == .win }).count
            let loseCount = self.winHistory.filter({ $0 == .lose }).count
            
            self.modelWinPercentageLabel.text = "Markov: \(loseCount)"
            self.winPercentageLabel.text = "You: \(winCount)"
        }
    }
    var userHistory = [RPS]()
    
    var processFrame = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.session.delegate = self
        sceneView.delegate = self
        sceneView.debugOptions = [.showFeaturePoints, .showPhysicsShapes]
        
        self.model = MarkovModel()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        self.sceneView.session.pause()
        
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
            
            // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
            //            request.usesCPUOnly = true
            
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    // The pixel buffer being held for analysis; used to serialize Vision requests.
    private var currentBuffer: CVPixelBuffer?
    // Queue for dispatching vision classification requests
    private let visionQueue = DispatchQueue(label: "com.mininny.wwdc20.playgroundbook.visionqueue")
    
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
                        self.myChoiceLabel.text = RPS.rock.asEmoji
                        self.myChoiceConfidenceLabel.text = "\(Double(bestResult.confidence*1000)/1000)"
                        
                        self.currentChoice = .rock
                    case "Paper":
                        self.myChoiceLabel.text = RPS.paper.asEmoji
                        self.myChoiceConfidenceLabel.text = "\(Double(bestResult.confidence*1000)/1000)"
                        
                        self.currentChoice = .paper
                    case "Scissors":
                        self.myChoiceLabel.text = RPS.scissors.asEmoji
                        self.myChoiceConfidenceLabel.text = "\(Double(bestResult.confidence*1000)/1000)"
                        
                        self.currentChoice = .scissors
                    default: break
                    }
                }
            }
        }
    }
    
    func parseIntoDoubleRPS(_ array: [RPS]) -> [RPS.Double: Int] {
        var rpsDict = RPS.Double.allCases.reduce(into: [RPS.Double: Int](), { $0[$1] = 0 })
        for index in 0..<array.count where array[exists: index+1] != nil {
            let doubleRPS = RPS.Double.doubleRPS(array[index], array[index+1])
            rpsDict[doubleRPS, default: 0] += 1
        }
        
        return rpsDict
    }
    
    func updateLabel() {
        let history = self.model.opponentHistory
        
        for item in self.parseIntoDoubleRPS(history) {
            switch item.key {
            case .RR:
                self.RR_Label.text = "\(item.value)"
            case .RS:
                self.RS_Label.text = "\(item.value)"
            case .RP:
                self.RP_Label.text = "\(item.value)"
            case .PR:
                self.PR_Label.text = "\(item.value)"
            case .PS:
                self.PS_Label.text = "\(item.value)"
            case .PP:
                self.PP_Label.text = "\(item.value)"
            case .SR:
                self.SR_Label.text = "\(item.value)"
            case .SS:
                self.SS_Label.text = "\(item.value)"
            case .SP:
                self.SP_Label.text = "\(item.value)"
            }
        }
    }
    
    func selectChoice(_ choice: RPS) {
        self.send(.string("Proceed"))
        UIView.animate(withDuration: 0.5, animations: {
            self.myChoiceLabel.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        }) { _ in
            self.updateMarkovChoice(with: choice)
            self.model.append(choice)
            self.userHistory.append(choice)
            
            UIView.animate(withDuration: 0.3) {
                self.myChoiceLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.runTimer()
                }
            }
        }
    }
    
    func highlight(_ label: UILabel?) {
        guard let label = label else { return }
        
        UIView.animate(withDuration: 0.5, animations: {
            label.layer.backgroundColor = UIColor.yellow.cgColor
        }) { _ in
            UIView.animate(withDuration: 0.5) {
                label.layer.backgroundColor = UIColor.clear.cgColor
            }
        }
    }
    
    func updateMarkovChoice(with myChoice: RPS) {
        if let modelChoice = self.model.predict() {
            self.modelChoiceLabel.text = modelChoice.asEmoji
            self.updateLabel()
            
            switch myChoice.wins(modelChoice) {
            case .draw:
                self.statusLabel.text = "\(myChoice.asEmoji) = \(modelChoice.asEmoji) \n⏺"
            case .win:
                self.statusLabel.text = "\(myChoice.asEmoji) 🤜 \(modelChoice.asEmoji) \n✅"
            case .lose:
                self.statusLabel.text = "\(myChoice.asEmoji) 🤛 \(modelChoice.asEmoji) \n❌"
            }
            
            if let secondLastMove = self.userHistory.secondLast {
                switch secondLastMove {
                case .rock:
                    self.highlight(self.R_Label)
                    if let lastMove = self.userHistory.last {
                        self.highlight(self.R_Labels[lastMove.asInt])
                    }
                case .paper:
                    self.highlight(self.P_Label)
                    if let lastMove = self.userHistory.last {
                        self.highlight(self.P_Labels[lastMove.asInt])
                    }
                case .scissors:
                    self.highlight(self.S_Label)
                    if let lastMove = self.userHistory.last {
                        self.highlight(self.S_Labels[lastMove.asInt])
                    }
                }
            }
            
            UIView.animate(withDuration: 0.5, animations: {
                self.modelChoiceLabel.transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
                self.statusLabel.transform = CGAffineTransform(scaleX: 2.5, y: 2.5)
            }) { _ in
                UIView.animate(withDuration: 0.3, animations: {
                    self.modelChoiceLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
                    self.statusLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.modelChoiceLabel.text = "❓"
                    }
                })
            }
            
            self.winHistory.append(myChoice.wins(modelChoice))
        }
    }
}

extension ARRPSViewController: ARSessionDelegate, ARSCNViewDelegate {
    // Pass camera frames received from ARKit to Vision (when not already processing one)
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        
        self.currentBuffer = frame.capturedImage
        classifyCurrentImage()
    }
}
