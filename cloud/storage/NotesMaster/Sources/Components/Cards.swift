import SwiftUI

// MARK: - Card View
struct CardView<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var backgroundColor: Color = .white
    var cornerRadius: CGFloat = 16
    var shadowColor: Color = .black.opacity(0.1)
    var shadowRadius: CGFloat = 8
    
    init(padding: CGFloat = 16,
         backgroundColor: Color = .white,
         cornerRadius: CGFloat = 16,
         shadowColor: Color = .black.opacity(0.1),
         shadowRadius: CGFloat = 8,
         @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
    }
}

// MARK: - Card Preview
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Card Title")
                    .font(.title2)
                    .bold()
                
                Text("This is a sample card with some content. Cards are great for displaying related information in a contained manner.")
                    .font(.body)
                    .foregroundColor(.gray)
                
                HStack {
                    Spacer()
                    Text("Footer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
