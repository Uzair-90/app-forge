import Foundation
import SwiftUI

enum AppError: Error, LocalizedError {
    case networkError(Error)
    case validationError(String)
    case persistenceError(Error)
    case authenticationError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .persistenceError(let error):
            return "Data save error: \(error.localizedDescription)"
        case .authenticationError(let message):
            return "Authentication failed: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .validationError:
            return "Please check your input and try again."
        case .persistenceError:
            return "Please try again or restart the app."
        case .authenticationError:
            return "Please check your credentials and try again."
        case .unknownError:
            return "Please try again later."
        }
    }
}

class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showErrorAlert = false
    
    func handle(_ error: Error, userMessage: String? = nil) {
        let appError: AppError
        
        if let knownError = error as? AppError {
            appError = knownError
        } else {
            // Map common errors to AppError
            switch error {
            case let urlError as URLError:
                appError = .networkError(urlError)
            case let decodingError as DecodingError:
                appError = .persistenceError(decodingError)
            default:
                appError = .unknownError
            }
        }
        
        DispatchQueue.main.async {
            self.currentError = appError
            self.showErrorAlert = true
            
            // Log the error
            print("Error occurred: \(appError.errorDescription ?? "Unknown")")
            if let underlyingError = error as NSError? {
                print("Underlying error: \(underlyingError), UserInfo: \(underlyingError.userInfo)")
            }
        }
    }
    
    func clearError() {
        currentError = nil
        showErrorAlert = false
    }
}

// View modifier for error handling
struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.showErrorAlert) {
                Button("OK") {
                    errorHandler.clearError()
                }
            } message: {
                if let error = errorHandler.currentError {
                    Text(error.errorDescription ?? "An error occurred")
                }
            }
    }
}

extension View {
    func withErrorHandling(_ errorHandler: ErrorHandler) -> some View {
        self.modifier(ErrorAlertModifier(errorHandler: errorHandler))
    }
}
