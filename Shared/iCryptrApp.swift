//
//  iCryptrApp.swift
//  Shared
//
//  Created by Brendan Lindsey on 8/17/21.
//

import SwiftUI

@main
struct iCryptrApp: App {
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background && !HelperService.isProcessing {
                HelperService.clearTemporaryDirectory()
            }
        }
    }
}
