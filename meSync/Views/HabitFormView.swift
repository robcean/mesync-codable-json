import SwiftUI

struct HabitFormView: View {
    @Binding var quickAddState: QuickAddState
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Habit Form")
                .font(.largeTitle)
                .padding()
            
            Text("🚧 Under Construction 🚧")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("Esta vista necesita ser migrada de SwiftData a Codable")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Cerrar") {
                withAnimation {
                    quickAddState = .hidden
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    @Previewable @State var quickAddState: QuickAddState = .habitForm()
    HabitFormView(quickAddState: $quickAddState)
        .environmentObject(DataManager.shared)
}
