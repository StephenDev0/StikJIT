//
//  RunJSView.swift
//  StikJIT
//
//  Created by s s on 2025/4/24.
//

import SwiftUI


struct RunJSWebView: UIViewControllerRepresentable {
    @Binding var scriptPath: String
    
    func makeUIViewController(context: Context) -> IDeviceWebViewController {
        return IDeviceWebViewController()
    }

    func updateUIViewController(_ vc: IDeviceWebViewController, context: Context) {
        vc.loadScript(scriptPath)
    }
}

struct RunJSView : View {
    @State var selectedScript = ""
    @State var webViewShow = false

    
    
    var body: some View {
        List {
            Section {
                Button("Enable JIT") {
                    selectScript(path: "test.html")
                }
                Button("Install App") {
                    selectScript(path: "test2.html")
                }
                Button("Location Simulation") {
                    selectScript(path: "test3.html")
                }
            }
        }
        .sheet(isPresented: $webViewShow) {
            NavigationView {
                RunJSWebView(scriptPath:$selectedScript)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                selectedScript = ""
                                webViewShow = false
                            }
                        }
                    }
                    .navigationTitle(selectedScript)
                    .navigationBarTitleDisplayMode(.inline)
            }

        }
    }
    
    func selectScript(path: String) {
        selectedScript = path
        webViewShow = true
    }
}
