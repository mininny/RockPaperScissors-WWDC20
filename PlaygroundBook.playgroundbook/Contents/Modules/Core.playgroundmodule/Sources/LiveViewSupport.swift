//
//  LiveViewSupport.swift
//
//  Created by Minhyuk Kim on 2020/05/18.
//  Copyright © 2020 Minhyuk Kim. All rights reserved.
//

import UIKit
import PlaygroundSupport
import RPS

/// Instantiates a new instance of a live view.
///
/// By default, this loads an instance of `LiveViewController` from `LiveView.storyboard`.
public enum ViewType {
    case RPS//(type: String)
    case ARView
    case ARRPSView
    case Test
    case Updatable
    
    var asString: String {
        switch self {
        case .RPS: return "RPS"
        case .ARView: return "ARView"
        case .ARRPSView: return "ARRPSView"
        case .Test: return "Test"
        case .Updatable: return "UpdatableModel"
        }
    }
}

public func instantiateLiveView(_ type: ViewType) -> PlaygroundLiveViewable {
    let storyboard = UIStoryboard(name: "LiveView", bundle: nil)

    let viewController = storyboard.instantiateViewController(withIdentifier: type.asString)
//    
//    if case let ViewType.RPS(modelType) = type, let vc = viewController as? RPSViewController {
//        switch RPSViewController.ModelType(rawValue: modelType) {
//        case .markov: vc.model = MarkovModel()
//        case .psychological: vc.model = PsychologicalModel()
//        default: vc.model = MarkovModel()
//        }
//    }

    return viewController
}
