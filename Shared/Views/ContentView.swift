//
//  ContentView.swift
//  Shared
//
//  Created by Brendan Lindsey on 8/17/21.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import os.log

struct ContentView: View {
    @State var pickedURL: URL?
    @State var pickedPhoto: PhotosPickerItem?
    @State var fileTypes: [UTType] = []
    @State var presentFileImporter = false
    @State var presentEncryptionView = false
    @State private var showHelp = false
    @State private var isImporting = false
    @State private var importProgress: Double = 0.0
    @State private var importIsIndeterminate = false
    @State private var importProgressObservation: NSKeyValueObservation? = nil

    /// Handle file importer completion
    func fileImporterOnCompletion(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            pickedURL = url
        case .failure(let error):
            // Log only domain+code — the error's description can embed the source
            // file's plaintext path/name, which this app deliberately keeps off disk.
            let nsError = error as NSError
            os_log("File import cancelled or failed: %{public}@ (%ld)", type: .error, nsError.domain, nsError.code)
        }
    }

    func handleButtonPress(for action: EncryptionMode) {
        if action == .encrypt {
            fileTypes = [.data]
        } else {
            let iCryptrFileType = UTType(filenameExtension: "icryptr") ?? UTType.data
            fileTypes = [iCryptrFileType]
        }
        presentFileImporter = true
    }

    /// Handle a picked photo. Get it ready for encryption
    func photoPickerCompletionHandler() {
        if pickedPhoto != nil {
            getPhotoURL(item: pickedPhoto!) { result in
                switch result {
                    case .success(let photoURL):
                        self.pickedURL = photoURL
                    case .failure(let failure):
                        os_log("Failed to import item: %{public}@", type: .error, String(describing: failure))
                        // TODO: Display an import error to user
                }
                self.pickedPhoto = nil
                self.isImporting = false
            }
        }
    }

    // TODO: change this to swift concurrency
    /// Converts a picked photo into a usable URL for encryption
    /// - Parameters:
    ///   - item: The picked item
    ///   - completionHandler: a completion handler to handle the result
    func getPhotoURL(item: PhotosPickerItem, completionHandler: @escaping (_ result: Result<URL, Error>) -> Void) {
        // Step 1: Load as Data object.
        let progress = item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                importProgressObservation?.invalidate()
                importProgressObservation = nil
            }
            switch result {
            case .success(let data):
                guard let contentType = item.supportedContentTypes.first else {
                    completionHandler(.failure(PhotoImportError.noContentType))
                    return
                }
                guard let data = data else {
                    completionHandler(.failure(PhotoImportError.noData))
                    return
                }
                // Step 2: make the URL file name and a get a file extention.
                let directory = FileManager.default.temporaryDirectory
                let url = directory.appendingPathComponent("\(UUID().uuidString).\(contentType.preferredFilenameExtension ?? "")")
                do {
                    // Step 3: write to temp App file directory and return in completionHandler
                    try data.write(to: url)
                    completionHandler(.success(url))
                } catch {
                    completionHandler(.failure(error))
                }
            case .failure(let failure):
                completionHandler(.failure(failure))
            }
        }
        // On the main thread, observe progress
        DispatchQueue.main.async {
            self.importProgress = progress.fractionCompleted
            self.importIsIndeterminate = (progress.totalUnitCount <= 0)
            guard !progress.isFinished else { return }
            self.importProgressObservation = progress.observe(\.fractionCompleted, options: [.new, .initial]) { prog, _ in
                DispatchQueue.main.async {
                    self.importProgress = prog.fractionCompleted
                    self.importIsIndeterminate = (prog.totalUnitCount <= 0)
                }
            }
        }
    }
    
    /// Encapsulates the import overlay
    @ViewBuilder
    private var importingOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            Group {
                if importIsIndeterminate {
                    ProgressView {
                        Text("Importing…")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .controlSize(.large)
                    .scaleEffect(1.5)
                } else {
                    VStack(spacing: 16) {
                        Text("Importing…")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        ProgressView(value: importProgress, total: 1.0)
                            .frame(width: 240)
                        Text("\(Int(importProgress * 100))%")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .scaledToFit()
                }
            }
            .tint(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gray
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Button(action: {() -> () in handleButtonPress(for: .encrypt)}, label: {
                        Text("  Encrypt File  ")
                            .foregroundColor(Color.white)
                            .font(.largeTitle)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10.0)
                    })
                    Spacer().frame(height: 20.0)
                    PhotosPicker(selection: $pickedPhoto, label: {
                        Text("Encrypt Photo")
                            .foregroundColor(Color.white)
                            .font(.largeTitle)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10.0)
                    })
                    Spacer().frame(height: 20.0)
                    Button(action: {() -> () in handleButtonPress(for: .decrypt)}, label: {
                        Text(" Decrypt File  ")
                            .foregroundColor(Color.white)
                            .font(.largeTitle)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10.0)
                        }
                    )
                }
                .disabled(isImporting)
                .onChange(of: pickedPhoto) {
                    if pickedPhoto != nil {
                        importProgress = 0.0
                        importIsIndeterminate = true // start with activity indicator
                        isImporting = true
                        photoPickerCompletionHandler()
                    }
                }
                .onChange(of: pickedURL) {
                    if pickedURL != nil {
                        presentEncryptionView = true
                    }
                }
                .fileImporter(isPresented: $presentFileImporter, allowedContentTypes: fileTypes, onCompletion: fileImporterOnCompletion)
                .toolbar {
                    Button(action: { showHelp = true }) {
                        Text("?")
                            .font(.title)
                    }
                    .disabled(isImporting)
                }
                .sheet(isPresented: $showHelp) {
                    HelpView()
                }
                if isImporting {
                    importingOverlay
                }
            }
            .navigationDestination(isPresented: $presentEncryptionView) {
                EncryptActionView(fileURL: $pickedURL)
                    .onDisappear {
                        pickedURL = nil    // allow the next picked URL to re-trigger navigation
                    }
            }
            .navigationTitle("iCryptr")
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 13 Pro")
    }
}
