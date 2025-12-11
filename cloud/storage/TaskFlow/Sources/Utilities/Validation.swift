import Foundation

protocol Validatable {
    func validate() throws
}

enum ValidationError: Error, LocalizedError {
    case emptyField(field: String)
    case invalidEmail
    case passwordTooShort(minLength: Int)
    case passwordsDontMatch
    case custom(message: String)
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field) cannot be empty"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .passwordTooShort(let minLength):
            return "Password must be at least \(minLength) characters"
        case .passwordsDontMatch:
            return "Passwords do not match"
        case .custom(let message):
            return message
        }
    }
}

struct Validator {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func validateNotEmpty(_ value: String, field: String) throws {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyField(field: field)
        }
    }
    
    static func validateEmail(_ email: String) throws {
        try validateNotEmpty(email, field: "Email")
        if !isValidEmail(email) {
            throw ValidationError.invalidEmail
        }
    }
    
    static func validatePassword(_ password: String, minLength: Int = 8) throws {
        try validateNotEmpty(password, field: "Password")
        if password.count < minLength {
            throw ValidationError.passwordTooShort(minLength: minLength)
        }
    }
    
    static func validatePasswordsMatch(_ password: String, _ confirmPassword: String) throws {
        if password != confirmPassword {
            throw ValidationError.passwordsDontMatch
        }
    }
}

// Example usage in a ViewModel:
/*
 class LoginViewModel: ObservableObject {
     @Published var email = ""
     @Published var password = ""
     @Published var validationError: ValidationError?
     
     func validate() -> Bool {
         do {
             try Validator.validateEmail(email)
             try Validator.validatePassword(password)
             validationError = nil
             return true
         } catch let error as ValidationError {
             validationError = error
             return false
         } catch {
             validationError = .custom(message: "Unknown validation error")
             return false
         }
     }
 }
 */
