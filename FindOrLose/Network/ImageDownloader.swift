import Combine
import UIKit

enum ImageDownloader {
  // 1. method returns a publisher
  static func download(url: String) -> AnyPublisher<UIImage, GameError> {
    guard let url = URL(string: url) else {
      return Fail(error: GameError.invalidURL)
        .eraseToAnyPublisher()
    }

    // 2. Get a dataTaskPublisher for the image URL.
    return URLSession.shared.dataTaskPublisher(for: url)
    // 3. Use tryMap to check the response code and extract the data if everything is OK.
      .tryMap { response -> Data in
        guard
          let httpURLResponse = response.response as? HTTPURLResponse,
          httpURLResponse.statusCode == 200
          else {
          throw GameError.statusCode
        }
        return response.data
      }
    // 4. Use another tryMap operator to change the upstream Data to UIImage, throwing an error if this fails.
      .tryMap { data in
        guard let image = UIImage(data: data) else {
          throw GameError.invalidImage
      }
        return image
    }
    // 5. Map the error to a GameError.
      .mapError { GameError.map($0) }
    // 6. .eraseToAnyPublisher to return a nice type.
      .eraseToAnyPublisher()
  }
}
