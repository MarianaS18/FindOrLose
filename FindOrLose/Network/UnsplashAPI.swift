import Combine
import Foundation

enum UnsplashAPI {
  static let accessToken = "Tx10R2W_9AkOJI7WWhNyQ7qXwiXH3GnZgqe7jHW1_m0"

  static func randomImage() -> AnyPublisher<RandomImageResponse, GameError> {
    let url = URL(string: "https://api.unsplash.com/photos/random/?client_id=\(accessToken)")!

    let config = URLSessionConfiguration.default
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    config.urlCache = nil
    let session = URLSession(configuration: config)

    var urlRequest = URLRequest(url: url)
    urlRequest.addValue("Accept-Version", forHTTPHeaderField: "v1")

    // 1. You get a publisher from the URL session for your URL request. This is a URLSession.DataTaskPublisher, which has an output type of (data: Data, response: URLResponse). That’s not the right output type, so you’re going to use a series of operators to get to where you need to be.
    return session.dataTaskPublisher(for: urlRequest)
    // 2. This operator takes the upstream value and attempts to convert it to a different type, with the possibility of throwing an error. There is also a map operator for mapping operations that can’t throw errors.
      .tryMap { response in
        guard
          // 3. Check for 200 OK HTTP status.
          let httpURLResponse = response.response as? HTTPURLResponse,
          httpURLResponse.statusCode == 200
          else {
            // 4. Throw the custom GameError.statusCode error if you did not get a 200 OK HTTP status.
            throw GameError.statusCode
          }
        // 5. Return the response.data if everything is OK. This means the output type of your chain is now Data
        return response.data
      }
    // 6. Apply the decode operator, which will attempt to create a RandomImageResponse from the upstream value using JSONDecoder. Your output type is now correct!
      .decode(type: RandomImageResponse.self, decoder: JSONDecoder())
    // 7. Your failure type still isn’t quite right. If there was an error during decoding, it won’t be a GameError. The mapError operator lets you deal with and map any errors to your preferred error type, using the function you added to GameError.
      .mapError { GameError.map($0) }
    // 8. If you were to check the return type of mapError at this point, you would be greeted with something quite horrific. The .eraseToAnyPublisher operator tidies all that mess up so you’re returning something more usable.
      .eraseToAnyPublisher()
    
  }
}
