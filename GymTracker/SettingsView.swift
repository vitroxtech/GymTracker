import SwiftUI

struct SettingsView: View {
    @ObservedObject var syncManager = GoogleSheetsSyncManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingInstructions = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Google Sheets Sync"), footer: Text("This URL is obtained by deploying a script in your Google Sheet as a 'Web App'.")) {
                    TextField("Web App URL", text: $syncManager.webhookURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if let error = syncManager.lastSyncError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: {
                        showingInstructions.toggle()
                    }) {
                        Label("How to get this URL?", systemImage: "questionmark.circle")
                    }
                    
                    Button(action: {
                        GoogleSheetsSyncManager.shared.sync(context: PersistenceController.shared.container.viewContext)
                    }) {
                        if syncManager.isSyncing {
                            HStack {
                                Text("Syncing...")
                                Spacer()
                                ProgressView()
                            }
                        } else {
                            Label("Test Sync Now", systemImage: "arrow.counterclockwise")
                        }
                    }
                    .disabled(syncManager.webhookURL.isEmpty || syncManager.isSyncing)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingInstructions) {
                SyncInstructionsView()
            }
        }
    }
}

struct SyncInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Setup Guide")
                        .font(.largeTitle)
                        .bold()
                    
                    Group {
                        StepView(number: 1, text: "Open your Google Sheet.")
                        StepView(number: 2, text: "Go to Extensions > Apps Script.")
                        StepView(number: 3, text: "Paste the script provided by Antigravity.")
                        StepView(number: 4, text: "Click 'Deploy' > 'New Deployment'.")
                        StepView(number: 5, text: "Select type 'Web App'.")
                        StepView(number: 6, text: "Set 'Who has access' to 'Anyone'.")
                        StepView(number: 7, text: "Copy the 'Web App URL' and paste it here.")
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StepView: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(number).")
                .bold()
                .foregroundColor(.blue)
            Text(text)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
