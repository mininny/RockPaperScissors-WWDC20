//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  Instantiates a live view and passes it to the PlaygroundSupport framework.
//

import UIKit
import Core
import PlaygroundSupport
import ARKit

// Instantiate a new instance of the live view from Core and pass it to PlaygroundSupport.
PlaygroundPage.current.liveView = instantiateLiveView(.ARView)

