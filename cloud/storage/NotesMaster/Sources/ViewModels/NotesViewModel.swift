import Foundation
import Combine

class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    func addNewNote(_ note: Note) {
        notes.append(note)
    }
}