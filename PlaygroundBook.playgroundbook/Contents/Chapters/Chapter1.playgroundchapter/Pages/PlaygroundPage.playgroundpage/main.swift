//#-hidden-code
import RPS
import PlaygroundSupport

func loadMarkovModel() {
    let proxy = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy
    let command: PlaygroundValue = .string("Markov")
    proxy?.send(command)
    
    PlaygroundPage.current.assessmentStatus = .pass(message: "Great! We just initialized a markov model and learned that hacking Rock-Paper-Scissors is possible! Play a few dozens of rounds with the machine and proceed... 👉 [Next Page](@next)")
}
//#-end-hidden-code
/*:
# Welcome!
 Hi! My name is Minhyuk Kim. Today, we're going to take a brief look at Algorithms, Machine Learning and its posible applications to our lives by taking a fresh look at a well-known *classical* game.

- Important: Please disable "Enable Results" in the playground setting for the best experience.
 
## Rock, Paper, Scissors

I hope you understand the basic rules of this game:
   * ✊ beats ✌️
   * ✌️ beats 🖐
   * 🖐 beats ✊

Simple random game, right?

Not quite...

## Algorithms
 Algorithms....sounds very intimidating, but we'll take an eaiser look at it with **RPS**(Rock-Paper-Scissors).
 
 There are many statistical as well as huge psychological factors that play in this game, and we're going to look at the statistical factor with machine learning.
 
 After all, algorithm(and machine learning, and artificial intelligence) is basically gathering and summing up bunch of data points and using them to inference what is most likely to happen.
 
 And most people also have their own pattern of playing the game when playing *rock paper scissors.*
 
 ## Markov Model
 Markov Model tackles on that exact idea. It gathers the previous moves that a player has played, and predicts the next move based on the previous moves.
 
 Here's a simple diagram of it:
 
 ![Some Name](RPS_Markov.mp4)

 We're taking user's every action, and map them with the previous move and second previous move. By doing so, we can infer on the general pattern of the player.
 For example, if the opponent plays ✌️, 🖐, ✊, ✊, ✌️, we may infer that the oppoent will likely play 🖐 based on the previous movements.
 
 This algorithm is called the Markov Algorithm which allows us to make better movements by remembering the previous movements of the opponent.
 */
 //#-code-completion(identifier, show, loadMarkovModel())
 // Call loadMarkovModel() function here.
 //#-editable-code
 
 //#-end-editable-code
/*:
 Try it out using the RPS machine on the right.
 You can view the data that is acccumulating by toggling the `Show Data` button!
 
 Because users can change their strategy throughout the game, the algorithm periodically removes past records to keep it synchronous. The default number of data stored is 30 movements.
 You can change the memory of the model by changing the slider that is revealed when you toggle `Show Data`.
 
 In average, you will notice that the Markov Model has a higher winning rate than you... Note, due to the randomness of a human mind, sometimes, you may have a higher win rate. Human mind is more random than we can ever imagine, so it's pretty hard for a machine to penetrate through your mind. But we'll try.

 - Important: Play with the algorithmic model and see how you do against a machine! If you toggle `Show Data` and change the slider's value, the model's memory will change. See how that affects the win rate!
 */

class MarkovMachine: MarkovModel {
//    typealias Vector<T : Hashable> = [T : Int]
//    typealias Matrix<T : Hashable> = [T : Vector<T>]
//    typealias DoubleMatrix<T: Hashable> = [T: Matrix<T>]
//    open var singleChain: Matrix<RPS> // This is a single layered chain. E.g. ✊ -> ✌️
//    open var doubleChain: DoubleMatrix<RPS> // This is a double layered chain. E.g. 🖐 -> ✌️ -> ✊
//    open var opponentHistory: [RPS] // This is the actual history of the opponent's movements.
    
//    public var limit = 30 {
//        didSet {
//            if self.limit > self.count { // If the model has more data than the limit
//                while self.opponentHistory.count > self.limit { // it removes oldest history until it satisfies the constraint.
//                    self.opponentHistory.removeFirst()
//                }
//            }
//        }
//    }
    
    override public func predict() -> RPS? {
        guard let singlePrediction = predictSingle(), let singleChoice = singlePrediction.max(by: { $0.value < $1.value }) else { return .randomChoice } // No data, retunr random movement
        guard let doublePrediction = predictDouble(), let doubleChoice = doublePrediction.max(by: { $0.value < $1.value }) else { return singleChoice.key } // No double chained result, returning data from the single layered chain.
        
        let singleChoiceProbability = Double(singleChoice.value)/Double(singlePrediction.values.reduce(1,+)) // Getting the probability for the single chain
        let doubleChoiceProbability = Double(doubleChoice.value)/Double(doublePrediction.values.reduce(1,+)) // Getting the probability for the double chain.
        
        return (singleChoiceProbability > doubleChoiceProbability) ? singleChoice.key.winningChoice : doubleChoice.key.winningChoice // Return the result with more probability.
    }
    
    override public func predictSingle() -> [RPS: Int]? { // Returns the dictionary of the history of opponent's play following the given movement with a single chain model.
        guard let value = self.opponentHistory.last else { return nil }
        return singleChain.probabilities(given: value)
    }
    
    override public func predictDouble() -> [RPS: Int]? { // Returns the dictionary of the history of opponent's play following the given movement with a double chain model .
        guard let first = self.opponentHistory.secondLast,
            let second = self.opponentHistory.last else { return nil }
        return doubleChain.probabilities(given: (first, second))
    }
}
