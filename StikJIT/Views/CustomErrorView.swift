import SwiftUI

struct CustomErrorView: View {
    var title: String
    var message: String
    var onDismiss: () -> Void
    var showButton: Bool = true
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .opacity(opacity)
                .onTapGesture {
                    if showButton {
                        dismissWithAnimation()
                    }
                }
            
            // Error card
            VStack(spacing: 16) {
                // Error icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 38))
                    .foregroundColor(.red.opacity(0.9))
                    .padding(.top, 8)
                
                // Title
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Divider
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.horizontal, 16)
                
                // Message
                Text(message)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                
                // Restart instructions when button is hidden
                if !showButton {
                    Text("Please connect to WireGuard VPN and restart the app.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                }
                
                // Dismiss button (only shown when showButton is true)
                if showButton {
                    Button(action: dismissWithAnimation) {
                        Text("OK")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .padding(.top, 8)
                } else {
                    Spacer()
                        .frame(height: 16)
                }
            }
            .frame(width: min(UIScreen.main.bounds.width - 60, 340))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemGray6).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                opacity = 1
                scale = 1
            }
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
            scale = 0.8
        }
        
        // Delay the actual dismissal to allow the animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
} 