import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var viewModel: NotesViewModel
    @State var note: Note

    var body: some View {
        VStack {
            TextField('Note Title', text: $note.title)
            TextEditor(text: $note.content)
            Button(action: { viewModel.addNewNote(note) }) {
                Text('Save Note')
            }
        }
    }
}

struct NoteEditorView_Previews: PreviewProvider {
    static var previews: some View {
        NoteEditorView(viewModel: NotesViewModel(), note: Note(id: UUID(), title: '', content: '', tags: [], category: ''))
    }
}