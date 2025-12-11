import json
import os
from openai import OpenAI
from dotenv import load_dotenv
from typing import Dict, Any, List
from pathlib import Path
from agents.BaseAgent import BaseAgent

load_dotenv()


class LogicAgent(BaseAgent):
    """
    Logic Agent for iOS projects:
        - Takes user request and metadata.json from previous phases
        - Creates data models, services, view models, and business logic
        - Updates existing files with necessary logic integrations
        - Maintains consistency with project architecture
    """

    def __init__(self, storage_path: str = "storage/"):
        super().__init__("LogicAgent", storage_path)
        self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        self.metadata = None
        self.project_root = None
        self.app_name = None
        self.clean_name = None
        self.llm_model = "gpt-5.1"

    # ------------------------------
    # METADATA & PROJECT SETUP
    # ------------------------------
    def load_metadata(self) -> Dict[str, Any]:
        """Load metadata.json from storage."""
        metadata_path = self.storage_path / "metadata.json"
        if not metadata_path.exists():
            raise FileNotFoundError(f"metadata.json not found at {metadata_path}")
        
        with open(metadata_path, "r") as f:
            metadata = json.load(f)
        
        self.metadata = metadata
        
        # Check if metadata is in the old format (flat dictionary)
        # or new format (with phases array)
        if "phases" in metadata:
            # New format: look for ArchitectAgent phase
            architect_phase = None
            for phase in reversed(metadata.get("phases", [])):
                if phase.get("agent") == "ArchitectAgent":
                    architect_phase = phase
                    break
            
            if not architect_phase:
                raise ValueError("No ArchitectAgent phase found in metadata")
            
            # Get app_name from results
            results = architect_phase.get("results", {})
            self.app_name = results.get("app_name", "MyApp")
            
        else:
            # OLD FORMAT: metadata is a flat dictionary of file changes
            # Extract app name from file paths
            app_names = set()
            for file_path in metadata.keys():
                parts = file_path.split('/')
                if parts:
                    app_names.add(parts[0])
            
            if not app_names:
                raise ValueError("Could not determine app name from metadata")
            
            # Use the most recent app (last one in the dictionary)
            last_file = list(metadata.keys())[-1]
            self.app_name = last_file.split('/')[0]
        
        self.clean_name = self.app_name.replace(" ", "")
        self.project_root = self.storage_path / self.clean_name
        
        return metadata

    def get_existing_files(self) -> List[str]:
        """Get list of existing Swift files in the project."""
        swift_files = []
        for root, dirs, files in os.walk(self.project_root):
            for file in files:
                if file.endswith(".swift"):
                    rel_path = Path(root) / file
                    project_relative_path = rel_path.relative_to(self.project_root)
                    swift_files.append(str(project_relative_path))
        return swift_files

    def get_app_description_from_metadata(self) -> str:
        """Extract app description from metadata if available."""
        if self.metadata and "phases" in self.metadata:
            for phase in self.metadata.get("phases", []):
                if phase.get("agent") == "ArchitectAgent":
                    results = phase.get("results", {})
                    llm_result = results.get("llm_result", {})
                    return llm_result.get("description", "An iOS application")
        return "An iOS application"

    # ------------------------------
    # LLM CALLS
    # ------------------------------
    def ask_llm_for_logic_components(self, query: str, existing_files: List[str]) -> Dict[str, Any]:
        """Calls GPT-5.1 to design data models, services, and business logic."""

        system_prompt = """
        You are an expert iOS software architect specializing in backend logic, data modeling, and business logic.
        Your job is to design the DATA LAYER and BUSINESS LOGIC for an iOS application.

        The user will provide:
        1. Requirements for backend logic, data models, and services
        2. List of existing Swift files in the project (to avoid duplication and understand context)

        You MUST return ONLY valid JSON with the following structure:
        {
            "new_files": [
                {
                    "path": "relative/path/to/file.swift",
                    "type": "model|service|viewmodel|manager|utility|repository",
                    "purpose": "Brief description",
                    "content": "Full Swift code content"
                }
            ],
            "modifications": [
                {
                    "file": "relative/path/to/existing/file.swift",
                    "changes": [
                        {
                            "type": "import|property|function|struct|class|protocol",
                            "action": "add|modify|remove",
                            "location_hint": "e.g., 'after AppState class', 'at end of file'",
                            "content": "Code to add or modify"
                        }
                    ]
                }
            ],
            "architecture_summary": {
                "core_entities": ["Entity1", "Entity2"],
                "data_persistence": "UserDefaults|CoreData|SwiftData|Realm|Custom",
                "networking_layers": ["APIClient", "WebSocketManager"],
                "business_logic_modules": ["Authentication", "DataSync", "Analytics"]
            }
        }

        CRITICAL GUIDELINES:
        1. Focus on DATA and LOGIC: Create data models, services, managers, repositories, and view models.
        2. Use modern Swift: Swift Concurrency (async/await), Codable, Combine, Result types.
        3. Follow SOLID principles and clean architecture patterns.
        4. Implement proper error handling with custom Error enums.
        5. Ensure dependency injection and testability.
        6. Don't duplicate existing files - build upon the project's foundation.
        7. Add comprehensive documentation and unit test stubs where appropriate.
        8. Design for scalability and maintainability.

        Example output for a Notes app:
        - new_files: ["Sources/Models/Note.swift", "Sources/Services/NoteService.swift", "Sources/ViewModels/NotesViewModel.swift"]
        - modifications: Update AppState to include notes array and loading state
        - architecture_summary: Core entities: ["Note"], Data persistence: "SwiftData", Networking: [], Business logic: ["NoteCRUD"]
        """

        existing_files_str = "\n".join(existing_files)
        app_description = self.get_app_description_from_metadata()
        
        full_context = f"""
        APP CONTEXT: {app_description}
        
        EXISTING FILES IN PROJECT:
        {existing_files_str}
        
        SPECIFIC LOGIC REQUIREMENTS:
        {query}
        """

        response = self.client.chat.completions.create(
            model=self.llm_model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": full_context}
            ]
        )

        content = response.choices[0].message.content
        return json.loads(content)

    def ask_llm_for_content_update(self, file_path: str, current_content: str, requirements: str) -> str:
        """Ask LLM to update existing file content for logic integration."""
        
        system_prompt = """
        You are an expert Swift developer. Update the given Swift file to integrate new business logic.
        Return ONLY the complete updated Swift code, no explanations.
        Maintain the existing structure, style, and imports.
        Ensure the updated code compiles and follows Swift best practices.
        """
        
        response = self.client.chat.completions.create(
            model=self.llm_model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"File: {file_path}\n\nCurrent content:\n{current_content}\n\nRequirements: {requirements}"}
            ]
        )
        
        return response.choices[0].message.content

    # ------------------------------
    # FILE OPERATIONS
    # ------------------------------
    def create_new_files(self, new_files: List[Dict[str, Any]]) -> Dict[str, dict]:
        """Create new Swift files for logic components."""
        file_changes = {}
        
        for file_info in new_files:
            project_relative_path = file_info["path"]
            content = file_info["content"]
            file_type = file_info.get("type", "model")
            purpose = file_info.get("purpose", "")
            
            storage_relative_path = f"{self.clean_name}/{project_relative_path}"
            full_path = self.storage_path / storage_relative_path
            
            full_path.parent.mkdir(parents=True, exist_ok=True)
            
            self.write_file(storage_relative_path, content)
            file_changes[storage_relative_path] = {
                "type": "created", 
                "file_type": file_type,
                "purpose": purpose
            }
            
            self.log(f"Created {file_type}: {storage_relative_path} ({purpose})")
        
        return file_changes

    def modify_existing_files(self, modifications: List[Dict[str, Any]]) -> Dict[str, dict]:
        """Modify existing Swift files to integrate logic."""
        file_changes = {}
        
        for mod_info in modifications:
            project_relative_path = mod_info["file"]
            storage_relative_path = f"{self.clean_name}/{project_relative_path}"
            full_path = self.storage_path / storage_relative_path
            
            if not full_path.exists():
                self.log(f"Warning: File {storage_relative_path} doesn't exist, skipping modifications")
                continue
            
            with open(full_path, "r") as f:
                current_content = f.read()
            
            requirements = f"Apply these changes: {json.dumps(mod_info['changes'])}"
            updated_content = self.ask_llm_for_content_update(project_relative_path, current_content, requirements)
            
            self.write_file(storage_relative_path, updated_content)
            file_changes[storage_relative_path] = {
                "type": "modified", 
                "changes": len(mod_info["changes"])
            }
            
            self.log(f"Modified: {storage_relative_path} ({len(mod_info['changes'])} changes)")
        
        return file_changes

    # ------------------------------
    # COMMON LOGIC COMPONENT GENERATORS
    # ------------------------------
    def create_common_logic_components(self) -> Dict[str, dict]:
        """Create common backend logic components that every app might need."""
        file_changes = {}
        
        components = [
            {
                "project_path": "Sources/Services/NetworkService.swift",
                "content": """import Foundation
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
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\\($0.value)") }
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
"""
            },
            {
                "project_path": "Sources/Utilities/ErrorHandler.swift",
                "content": """import Foundation
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
            return "Network error: \\(error.localizedDescription)"
        case .validationError(let message):
            return "Validation error: \\(message)"
        case .persistenceError(let error):
            return "Data save error: \\(error.localizedDescription)"
        case .authenticationError(let message):
            return "Authentication failed: \\(message)"
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
            print("Error occurred: \\(appError.errorDescription ?? "Unknown")")
            if let underlyingError = error as NSError? {
                print("Underlying error: \\(underlyingError), UserInfo: \\(underlyingError.userInfo)")
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
"""
            },
            {
                "project_path": "Sources/Utilities/Validation.swift",
                "content": """import Foundation

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
            return "\\(field) cannot be empty"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .passwordTooShort(let minLength):
            return "Password must be at least \\(minLength) characters"
        case .passwordsDontMatch:
            return "Passwords do not match"
        case .custom(let message):
            return message
        }
    }
}

struct Validator {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\\\.[A-Za-z]{2,64}"
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
"""
            }
        ]
        
        # Create necessary directories
        services_dir = self.project_root / "Sources" / "Services"
        services_dir.mkdir(parents=True, exist_ok=True)
        
        utilities_dir = self.project_root / "Sources" / "Utilities"
        utilities_dir.mkdir(parents=True, exist_ok=True)
        
        # Create component files
        for component in components:
            project_path = component["project_path"]
            storage_path = f"{self.clean_name}/{project_path}"
            content = component["content"]
            
            self.write_file(storage_path, content)
            file_changes[storage_path] = {"type": "created", "file_type": "utility"}
        
        return file_changes

    # ------------------------------
    # UPDATE EXISTING FILES WITH LOGIC
    # ------------------------------
    def update_app_state_with_logic(self) -> Dict[str, dict]:
        """Update AppState.swift to include logic-related properties."""
        file_changes = {}
        
        app_state_path = self.project_root / "Sources" / "Models" / "AppState.swift"
        if app_state_path.exists():
            with open(app_state_path, "r") as f:
                content = f.read()
            
            # Check if ErrorHandler is already imported/included
            if "ErrorHandler" not in content:
                # Simple update: add error handler property
                updated_content = content.replace(
                    "class AppState: ObservableObject {",
                    """class AppState: ObservableObject {
    @Published var errorHandler = ErrorHandler()
    @Published var isLoading: Bool = false
    @Published var user: User? = nil"""
                )
                
                storage_path = f"{self.clean_name}/Sources/Models/AppState.swift"
                self.write_file(storage_path, updated_content)
                file_changes[storage_path] = {"type": "modified", "changes": "added error handler"}
        
        return file_changes

    # ------------------------------
    # CORE METHOD
    # ------------------------------
    def perform_task(self, prompt: str, metadata: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Main entry for the Logic Agent.
        1. Load metadata from previous phases
        2. Get existing files
        3. Ask LLM for logic components
        4. Create files and apply modifications
        5. Create common logic components
        6. Update metadata.json
        """
        
        self.log("Loading metadata from previous phases...")
        self.load_metadata()
        
        self.log(f"Working on logic for project: {self.app_name}")
        self.log(f"Project root: {self.project_root}")
        
        # Get existing files
        existing_files = self.get_existing_files()
        self.log(f"Found {len(existing_files)} existing Swift files")
        
        # Ask LLM for logic components
        self.log(f"Querying {self.llm_model} for logic components...")
        llm_result = self.ask_llm_for_logic_components(prompt, existing_files)
        
        file_changes = {}
        
        # Create new files from LLM
        if "new_files" in llm_result and llm_result["new_files"]:
            self.log(f"Creating {len(llm_result['new_files'])} new logic files...")
            new_file_changes = self.create_new_files(llm_result["new_files"])
            file_changes.update(new_file_changes)
        
        # Modify existing files
        if "modifications" in llm_result and llm_result["modifications"]:
            self.log(f"Applying {len(llm_result['modifications'])} logic modifications...")
            mod_file_changes = self.modify_existing_files(llm_result["modifications"])
            file_changes.update(mod_file_changes)
        
        # Create common logic components
        self.log("Creating common logic components...")
        component_changes = self.create_common_logic_components()
        file_changes.update(component_changes)
        
        # Update AppState with logic
        self.log("Updating AppState with logic integration...")
        app_state_changes = self.update_app_state_with_logic()
        file_changes.update(app_state_changes)
        
        # Update metadata
        updated_metadata = self.update_metadata(file_changes)
        
        # Add architecture summary to results
        architecture_summary = llm_result.get("architecture_summary", {})
        
        return {
            "app_name": self.app_name,
            "llm_result": llm_result,
            "file_changes": file_changes,
            "architecture_summary": architecture_summary,
            "metadata": updated_metadata
        }