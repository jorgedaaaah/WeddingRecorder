import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: Settings
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Duracion de la grabacion")) {
                    Picker("Countdown", selection: $settings.countdownDuration) {
                        ForEach(CountdownDuration.allCases) { duration in
                            Text(duration.displayName).tag(duration)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
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
        SettingsView()
            .environmentObject(Settings())
    }
}
