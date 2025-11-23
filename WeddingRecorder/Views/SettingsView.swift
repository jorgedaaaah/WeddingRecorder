import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: Settings
    @Environment(\.presentationMode) var presentationMode
    @Binding var captureMode: CaptureMode // Add this binding
    
    var body: some View {
        NavigationView {
            Form {
                // Conditional Section for Video Settings
                if captureMode == .video {
                    Section(header: Text("Duracion de la grabacion")) {
                        Picker("Countdown", selection: $settings.countdownDuration) {
                            ForEach(CountdownDuration.allCases) { duration in
                                Text(duration.displayName).tag(duration)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                // Conditional Section for Photo Burst Settings
                if captureMode == .photo {
                    Section(header: Text("Duracion del conteo para ráfaga de fotos")) {
                        Picker("Conteo", selection: $settings.photoBurstCountdownDuration) {
                            ForEach(PhotoBurstCountdownDuration.allCases) { duration in
                                Text(duration.displayName).tag(duration)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
            .navigationTitle("Configuracion")
            .navigationBarItems(trailing: Button("Listo!") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(captureMode: .constant(.video)) // Provide a constant binding for preview
            .environmentObject(Settings.shared) // Use the singleton instance
    }
}
