import SwiftUI

struct NoteCardView: View {
    var note: Note

    var body: some View {
        VStack(alignment: .leading) {
            Text(note.title)
                .font(.headline)
            Text(note.content)
                .font(.subheadline)
        }
    }
}

struct NoteCardView_Previews: PreviewProvider {
    static var previews: some View {
        NoteCardView(note: Note(id: UUID(), title: 'Test Title', content: 'Test Content', tags: ['test'], category: 'Test'))
    }
}