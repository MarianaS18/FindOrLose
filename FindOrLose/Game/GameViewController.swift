import Combine
import UIKit


class GameViewController: UIViewController {
  // MARK: - Variables
  // property to store all of your subscriptions
  var subscriptions: Set<AnyCancellable> = []

  var gameState: GameState = .stop {
    didSet {
      switch gameState {
        case .play:
          playGame()
        case .stop:
          stopGame()
      }
    }
  }

  var gameImages: [UIImage] = []
  var gameTimer: AnyCancellable?
  var gameLevel = 0
  var gameScore = 0

  // MARK: - Outlets

  @IBOutlet weak var gameStateButton: UIButton!

  @IBOutlet weak var gameScoreLabel: UILabel!

  @IBOutlet var gameImageView: [UIImageView]!

  @IBOutlet var gameImageButton: [UIButton]!

  @IBOutlet var gameImageLoader: [UIActivityIndicatorView]!

  // MARK: - View Controller Life Cycle

  override func viewDidLoad() {
    precondition(!UnsplashAPI.accessToken.isEmpty, "Please provide a valid Unsplash access token!")

    title = "Find or Lose"
    gameScoreLabel.text = "Score: \(gameScore)"
  }

  // MARK: - Game Actions

  @IBAction func playOrStopAction(sender: UIButton) {
    gameState = gameState == .play ? .stop : .play
  }

  @IBAction func imageButtonAction(sender: UIButton) {
    let selectedImages = gameImages.filter { $0 == gameImages[sender.tag] }
    
    if selectedImages.count == 1 {
      playGame()
    } else {
      gameState = .stop
    }
  }

  // MARK: - Game Functions

  func playGame() {
    gameTimer?.cancel()

    gameStateButton.setTitle("Stop", for: .normal)

    gameLevel += 1
    title = "Level: \(gameLevel)"

    gameScoreLabel.text = "Score: \(gameScore)"
    gameScore += 200

    resetImages()
    startLoaders()
    
    // 1. Get a publisher that will provide you with a random image value.
    let firstImage = UnsplashAPI.randomImage()
      // 2. Apply the flatMap operator, which transforms the values from one publisher into a new publisher. In this case you’re waiting for the output of the random image call, and then transforming that into a publisher for the image download call.
      .flatMap { randomImageResponse in
        ImageDownloader.download(url: randomImageResponse.urls.regular)
      }
    
    let secondImage = UnsplashAPI.randomImage()
      .flatMap { randomImageResponse in
        ImageDownloader.download(url: randomImageResponse.urls.regular)
      }
    
    // 3. zip makes a new publisher by combining the outputs of existing ones. It will wait until both publishers have emitted a value, then it will send the combined values downstream.
    firstImage.zip(secondImage)
      // 4. The receive(on:) operator allows you to specify where you want events from the upstream to be processed. Since you’re operating on the UI, you’ll use the main dispatch queue.
      .receive(on: DispatchQueue.main)
      // 5. It’s your first subscriber! sink(receiveCompletion:receiveValue:) creates a subscriber for you which will execute those two closures on completion or receipt of a value.
      .sink(receiveCompletion: { [unowned self] completion in
        // 6. Your publisher can complete in two ways — either it finishes or fails. If there’s a failure, you stop the game.
        switch completion {
          case .finished: break
          case .failure(let error):
            print("Error: \(error)")
            self.gameState = .stop
        }
      }, receiveValue: { [unowned self] first, second in
        // 7. When you receive your two random images, add them to an array and shuffle, then update the UI.
        self.gameImages = [first, second, second, second].shuffled()
        self.gameScoreLabel.text = "Score: \(self.gameScore)"
        
        // 8. You use the new API for vending publishers from Timer. The publisher will repeatedly send the current date at the given interval, on the given run loop.
        self.gameTimer = Timer.publish(every: 0.1, on: RunLoop.main, in: .common)
          // 9. The publisher is a special type of publisher that needs to be explicitly told to start or stop. The .autoconnect operator takes care of this by connecting or disconnecting as soon as subscriptions start or are canceled.
          .autoconnect()
          // 10. The publisher can't ever fail, so you don't need to deal with a completion. In this case, sink makes a subscriber that just processes values using the closure you supply.
          .sink { [unowned self] _ in
            self.gameScoreLabel.text = "Score: \(self.gameScore)"
            self.gameScore -= 10
            
            if self.gameScore <= 0 {
              self.gameScore = 0
              
              self.gameTimer?.cancel()
            }
          }
          
        
        self.stopLoaders()
        self.setImages()
      })
    // 11. Store the subscription in subscriptions. Without keeping this reference alive, the subscription will cancel and the publisher will terminate immediately.
      .store(in: &subscriptions)

  }

  func stopGame() {
    subscriptions.forEach { $0.cancel() }
    gameTimer?.cancel()

    gameStateButton.setTitle("Play", for: .normal)

    title = "Find or Lose"

    gameLevel = 0

    gameScore = 0
    gameScoreLabel.text = "Score: \(gameScore)"

    stopLoaders()
    resetImages()
  }

  // MARK: - UI Functions

  func setImages() {
    if gameImages.count == 4 {
      for (index, gameImage) in gameImages.enumerated() {
        gameImageView[index].image = gameImage
      }
    }
  }

  func resetImages() {
    subscriptions = []
    gameImages = []

    gameImageView.forEach { $0.image = nil }
  }

  func startLoaders() {
    gameImageLoader.forEach { $0.startAnimating() }
  }

  func stopLoaders() {
    gameImageLoader.forEach { $0.stopAnimating() }
  }
}
