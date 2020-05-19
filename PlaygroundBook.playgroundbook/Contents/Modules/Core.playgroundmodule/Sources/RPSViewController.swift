//
//  RPSViewController.swift
//
//  Created by Minhyuk Kim on 2020/05/18.
//  Copyright © 2020 Minhyuk Kim. All rights reserved.
//

import UIKit
import PlaygroundSupport
import RPS

@objc(Core_RPSViewController)
public class RPSViewController: UIViewController, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer {
    public enum ModelType: String {
        case markov
        case psychological
        
        var modelString: String {
            switch self {
            case .markov: return "Markov Model"
            case .psychological: return "Psychological Model"
            }
        }
    }
    @IBOutlet var chartView: LineChartView!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var winPercentageLabel: UILabel!
    @IBOutlet weak var markovChoiceLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var markovWinPercentageLabel: UILabel!
    
    @IBOutlet weak var modelLabel: UILabel!
    
    @IBOutlet weak var dataViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var RR_Label: UILabel!
    @IBOutlet weak var RP_Label: UILabel!
    @IBOutlet weak var RS_Label: UILabel!
    
    @IBOutlet weak var PR_Label: UILabel!
    @IBOutlet weak var PP_Label: UILabel!
    @IBOutlet weak var PS_Label: UILabel!
    
    @IBOutlet weak var SR_Label: UILabel!
    @IBOutlet weak var SP_Label: UILabel!
    @IBOutlet weak var SS_Label: UILabel!
        
    @IBOutlet weak var predictionLabel: UILabel!
    
    
    @IBOutlet var R_Label: UILabel!
    @IBOutlet var P_Label: UILabel!
    
    @IBOutlet var S_Label: UILabel!
    
    @IBOutlet var R_Labels: [UILabel]!
    @IBOutlet var S_Labels: [UILabel]!
    @IBOutlet var P_Labels: [UILabel]!
    
    @IBOutlet weak var rockButton: UIButton!
    @IBOutlet weak var paperButton: UIButton!
    @IBOutlet weak var scissorsButton: UIButton!
    
    @IBAction func toggleShowData(_ sender: Any) {
        guard let toggle = sender as? UISwitch else { return }
        
        if toggle.isOn {
            self.dataViewHeightConstraint.constant = 130
            self.predictionLabel.isHidden = false
            self.view.layoutIfNeeded()
        } else {
            self.dataViewHeightConstraint.constant = 0
            self.predictionLabel.isHidden = true
            self.view.layoutIfNeeded()
        }
    }
    
    @IBOutlet weak var allowIntimidationSwitch: UISwitch!
    @IBOutlet weak var allowIntimidationLabel: UILabel!
    @IBOutlet weak var intimidationLabel: UILabel!
    @IBOutlet weak var intimidationView: UIView!
    
    @IBOutlet var showDataToggle: UISwitch!
    @IBOutlet var showDataLabel: UILabel!
    
    @IBOutlet weak var modelMemoryLabel: UILabel!
    @IBOutlet weak var modelMemorySlider: UISlider!
    @IBAction func didSlideModelMemory(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        guard let model = self.model as? MarkovModel else { return }
        
        model.limit = Int(slider.value)
        self.updateLabel()
        self.modelMemoryLabel.text = "\(Int(slider.value)) items"
    }
    
    func toggleButtonLock(_ lock: Bool) {
        DispatchQueue.main.async {
            self.rockButton.isEnabled = !lock
            self.paperButton.isEnabled = !lock
            self.scissorsButton.isEnabled = !lock
        }
    }
    
    func changeModelType(_ type: ModelType, useWeight: Bool = false) {
        switch type {
        case .markov:
            self.model = MarkovModel()
            if useWeight {
                (self.model as? MarkovModel)?.useWeightedChain = true
            }
        case .psychological: self.model = PsychologicalModel()
        }
        self.toggleButtonLock(false)
        
        self.resultLabel.text = "Gathering data..."
        
        self.RR_Label.text = "0"
        self.RS_Label.text = "0"
        self.RP_Label.text = "0"

        self.PR_Label.text = "0"
        self.PS_Label.text = "0"
        self.PP_Label.text = "0"
        
        self.SR_Label.text = "0"
        self.SS_Label.text = "0"
        self.SP_Label.text = "0"
        
        
        self.winHistory = []
        
        if useWeight {
            self.modelLabel.text = "Markov Model with Weight"
        } else {
            self.modelLabel.text = type.modelString
        }
        
        self.allowIntimidationLabel.isHidden = (self.model is PsychologicalModel == false)
        self.allowIntimidationSwitch.isHidden = (self.model is PsychologicalModel == false)
        
        self.modelMemorySlider.isHidden = (self.model is PsychologicalModel)
        self.modelMemoryLabel.isHidden = self.model is PsychologicalModel
        
        self.showDataLabel.isHidden = (self.model is PsychologicalModel || useWeight)
        self.showDataToggle.isHidden = (self.model is PsychologicalModel || useWeight)
    }
    
    var userHistory = [RPS]()
    
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
    
    var model: RPSable! //{
//        didSet {
//            self.allowIntimidationLabel.isHidden = (self.model is PsychologicalModel == false)
//            self.allowIntimidationSwitch.isHidden = (self.model is PsychologicalModel == false)
//
//            self.modelMemorySlider.isHidden = (self.model is PsychologicalModel)
//            self.modelMemoryLabel.isHidden = self.model is PsychologicalModel
//        }
//    }
    var winHistory = [RPS.Result]() {
        didSet {
            guard self.winHistory.count > 0 else {
                self.markovWinPercentageLabel.text = ""
                self.winPercentageLabel.text = ""
                return
            }
            
            let winCount = self.winHistory.filter({ $0 == .win }).count
            let loseCount = self.winHistory.filter({ $0 == .lose }).count

            let markovWinPercent = (Double(loseCount)/Double(self.winHistory.count))
            self.markovWinPercentageLabel.text = "Markov Won: \(Double(round(1000*markovWinPercent)/10))%"

            let winPercent = Double(winCount)/Double(self.winHistory.count)
            self.winPercentageLabel.text = "You Won: \(Double(round(1000*winPercent)/10))%"
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
//        if model != nil {
//            switch model {
//            case is MarkovModel:
//                self.changeModelType(.markov)
//            case is PsychologicalModel:
//                self.changeModelType(.psychological)
//            default: self.changeModelType(.markov)
//            }
//        } else {
//            self.changeModelType(.markov)
//        }
        self.toggleButtonLock(true)
        
        self.winPercentageLabel.text = ""
        self.markovWinPercentageLabel.text = ""
        self.resultLabel.text = "Waiting on input..."
        self.markovChoiceLabel.text = ""
        self.descriptionLabel.text = ""
    }
    
    func highlight(_ label: UILabel?) {
        guard let label = label else { return }
        
        UIView.animate(withDuration: 0.5, animations: {
            label.layer.backgroundColor = UIColor.yellow.cgColor
        }) { _ in
            UIView.animate(withDuration: 0.5) {
                label.layer.backgroundColor = UIColor.systemBackground.cgColor
            }
        }
    }
    
    func updateMarkovChoice(with myChoice: RPS) {
        if self.model.count < 10 {
            self.descriptionLabel.text = "Gathering data... you need at least \(10-self.model.count) more tries."
        } else { self.descriptionLabel.text = "" }

        if let markovChoice = self.model.predict() {
            self.predictionLabel.text = "Model predicted \(markovChoice.defeatingChoice.asEmoji)!"
            
            self.markovChoiceLabel.text = markovChoice.asEmoji
            
            switch myChoice.wins(markovChoice) {
            case .draw:
                resultLabel.text = "⏺"
            case .win:
                resultLabel.text = "✅"
            case .lose:
                resultLabel.text = "❌"
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
                self.markovChoiceLabel.transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
                self.resultLabel.transform = CGAffineTransform(scaleX: 2.5, y: 2.5)
            }) { _ in
                UIView.animate(withDuration: 0.3, animations: {
                    self.markovChoiceLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
                    self.resultLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
                    if self.allowIntimidationSwitch.isOn, Double.random(in: 0...1.0) < 0.333, let psychologicalModel = self.model as? PsychologicalModel {
                        let randomPick = RPS.randomChoice
                        psychologicalModel.nextIntimidation = randomPick
                        self.toggleButtonLock(true)
                        self.showIntimidatingAlert(randomPick)
                        self.intimidationView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5) //Scale label area
                        UIView.animate(withDuration: 1.25) {
                            self.intimidationView.transform = CGAffineTransform(scaleX: 1, y: 1)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                self.intimidationView.isHidden = true
                                self.toggleButtonLock(false)
                            }
                        }
                        
                    }
                })
            }
            
            self.winHistory.append(myChoice.wins(markovChoice))
        }
    }

    @IBAction func didPressButton(_ sender: Any) { // User choosd Rock, Paper, or Scissors.
        guard let button = sender as? UIButton else {
            return
        }
        
        self.toggleButtonLock(true)
        
        UIView.animate(withDuration: 0.5, animations: {
            button.transform = CGAffineTransform(scaleX: 2.0, y: 2.0) //Scale label area
        }) { _ in
            switch button.tag {
            case 0:
                self.updateMarkovChoice(with: .rock)
                self.model.append(.rock)
                self.userHistory.append(.rock)
            case 1:
                self.updateMarkovChoice(with: .paper)
                self.model.append(.paper)
                self.userHistory.append(.paper)
            case 2:
                self.updateMarkovChoice(with: .scissors)
                self.model.append(.scissors)
                self.userHistory.append(.scissors)
            default: break
            }
            self.updateLabel()
            
            
            UIView.animate(withDuration: 0.4, animations: {
                button.transform = CGAffineTransform(scaleX: 1, y: 1)
            }) { _ in
                self.toggleButtonLock(false)
            }
        }
    }
    
    func showIntimidatingAlert(_ choice: RPS) {
        self.intimidationView.isHidden = false
        self.intimidationLabel.text = "I'm Going to play \(choice.asEmoji)..!!"
    }

    public func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) {}
    
    public func receive(_ message: PlaygroundValue) {
        switch message {
        case .string(let msg):
            switch msg {
            case "Reveal Code": break
            case "Psychological":
                self.changeModelType(.psychological)
            case "Markov":
                self.changeModelType(.markov)
            case "Weighted":
                self.changeModelType(.markov, useWeight: true)
            default: break
            }
        default: break
        }
    }
}
