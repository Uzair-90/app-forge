import Foundation
import Combine

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func downloadData(from url: URL) async throws -> Data
}

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case statusCode(Int)
    case decodingFailed(Error)
}

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let parameters: [String: Any]?
    let body: Data?
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }
}

class NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let baseURL: String
    
    init(baseURL: String = "https://api.example.com", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Add headers
        endpoint.headers?.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add default headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Handle parameters for GET requests
        if endpoint.method == .get, let parameters = endpoint.parameters {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            if let newURL = components?.url {
                request.url = newURL
            }
        }
        
        // Add body for POST/PUT/PATCH
        if let body = endpoint.body, [.post, .put, .patch].contains(endpoint.method) {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.statusCode(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                throw APIError.decodingFailed(error)
            }
        } catch {
            throw APIError.requestFailed(error)
        }
    }
    
    func downloadData(from url: URL) async throws -> Data {
        let (data, _) = try await session.data(from: url)
        return data
    }
}

// Example usage:
// let networkService = NetworkService()
// let user: User = try await networkService.request(APIEndpoint(path: "/users/1", method: .get))
