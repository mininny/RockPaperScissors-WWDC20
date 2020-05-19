//
//  RPSModel.swift
//
//  Created by Minhyuk Kim on 2020/05/18.
//  Copyright © 2020 Minhyuk Kim. All rights reserved.
//
  
import CoreML

/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class RPSModelInput : MLFeatureProvider {
    
    /// data as color (kCVPixelFormatType_32BGRA) image buffer, 227 pixels wide by 227 pixels high
    var data: CVPixelBuffer
    
    var featureNames: Set<String> {
        get {
            return ["data"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "data") {
            return MLFeatureValue(pixelBuffer: data)
        }
        return nil
    }
    
    init(data: CVPixelBuffer) {
        self.data = data
    }
}


/// Model Prediction Output Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class RPSModelOutput : MLFeatureProvider {
    
    /// loss as dictionary of strings to doubles
    let loss: [String : Double]
    
    /// classLabel as string value
    let classLabel: String
    
    var featureNames: Set<String> {
        get {
            return ["loss", "classLabel"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "loss") {
            return try! MLFeatureValue(dictionary: loss as [NSObject : NSNumber])
        }
        if (featureName == "classLabel") {
            return MLFeatureValue(string: classLabel)
        }
        return nil
    }
    
    init(loss: [String : Double], classLabel: String) {
        self.loss = loss
        self.classLabel = classLabel
    }
}


/// Class for model loading and prediction
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class RPSModel {
    var model: MLModel
    
    /**
     Construct a model with explicit path to mlmodel file
     - parameters:
     - url: the file url of the model
     - throws: an NSError object that describes the problem
     */
    init(contentsOf url: URL) throws {
        self.model = try MLModel(contentsOf: url)
    }
    
    /// Construct a model that automatically loads the model from the app's bundle
    convenience init() {
        let bundle = Bundle(for: RPSModel.self)
        let assetPath = bundle.url(forResource: "RPSModel", withExtension:"mlmodelc")
        try! self.init(contentsOf: assetPath!)
    }
    
    /**
     Make a prediction using the structured interface
     - parameters:
     - input: the input to the prediction as RPSInput
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as RPSOutput
     */
    func prediction(input: RPSModelInput) throws -> RPSModelOutput {
        let outFeatures = try model.prediction(from: input)
        let result = RPSModelOutput(loss: outFeatures.featureValue(for: "loss")!.dictionaryValue as! [String : Double], classLabel: outFeatures.featureValue(for: "classLabel")!.stringValue)
        return result
    }
    
    /**
     Make a prediction using the convenience interface
     - parameters:
     - data as color (kCVPixelFormatType_32BGRA) image buffer, 227 pixels wide by 227 pixels high
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as RPSOutput
     */
    func prediction(data: CVPixelBuffer) throws -> RPSModelOutput {
        let input_ = RPSModelInput(data: data)
        return try self.prediction(input: input_)
    }
}
