import SwiftUI

// MARK: - Loading Views
struct LoadingView: View {
    var message: String = "Loading..."
    var size: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryColor))
                .frame(width: size, height: size)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct SkeletonView: View {
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .shimmering()
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .modifier(Shimmer(phase: phase))
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct Shimmer: AnimatableModifier {
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: phase - 0.3),
                        .init(color: .black, location: phase - 0.2),
                        .init(color: .black, location: phase - 0.1),
                        .init(color: .clear, location: phase)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerEffect())
    }
}

// MARK: - Preview
struct LoadingViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingView()
                .previewLayout(.sizeThatFits)
                .frame(height: 200)
            
            SkeletonView()
                .frame(height: 100)
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
