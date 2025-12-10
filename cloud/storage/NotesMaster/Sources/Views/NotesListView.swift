import SwiftUI

struct NotesListView: View {
    @ObservedObject var viewModel: NotesViewModel

    var body: some View {
        NavigationView {
            List(viewModel.notes) { note in
                NoteCardView(note: note)
            }
            .navigationTitle('Notes')
        }
    }
}

struct NotesListView_Previews: PreviewProvider {
    static var previews: some View {
        NotesListView(viewModel: NotesViewModel())
    }
}