/*:
 ## More Machine Learning
 
 That was a brief look at the fundamental idea behind algorithms and its applicance. It can predict what you're going to play and try to counter it!
 
 Machine learning works the same way. By learning what happened before and memorizing it in an effective way, it is able to successfully 'predict' the future.
 
 Here, I prepared a trained machine learning model that can detect rock, paper, scissors hand gestures from a camera. It's a **neural network** model that trains "neurons" to detect and classify parts of the image separately, and aggregate it together to construct a full-sized prediction of RPS choice.
 
 Before we get into the playing a game with the machine in AR, familiarize yourself and play around it on the right! Machine Learning Model will predict what hand shape you are making, and print out the prediction and the confidence percentage on the top view.
 
 When you're ready, proceed to the next page! 👉
 
 - Important: If you are not getting the correct classification, make sure you are in a well-lit area, have fairly clean background behind your hands, and make clear gestures with your hand. Depending on your hand shape, the results may differ. Again... machines have their pitfalls. 
 */
//#-hidden-code
 import PlaygroundSupport
PlaygroundPage.current.assessmentStatus = .pass(message: "If you played around with the classifier, proceed to the [Next Page](@next) 👉")
//#-end-hidden-code
