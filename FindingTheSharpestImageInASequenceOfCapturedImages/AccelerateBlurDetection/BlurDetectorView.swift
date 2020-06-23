/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Blur Detector Main View.
*/

import SwiftUI
import AVFoundation
import Combine

struct BlurDetectorView: View {
    
    @Environment(\.blurDetector) var blurDetector: BlurDetector
    @EnvironmentObject var model: BlurDetectorResultModel

    func takePhoto() {
        model.mode = .processing
        blurDetector.takePhoto()
    }
    
    func showCameraView() {
        model.mode = .camera
    }
    
    func assignDelegate() {
        blurDetector.resultsDelegate = model
    }
    
    var isBlurringCameraView: Bool {
        model.mode == .resultsTable || model.mode == .processing
    }

    var body: some View {
        VStack() {
            PreviewView()
            
            Button(action: self.takePhoto) {
                Text("Take Photograph")
                    .bold()
            }
        }
        .onAppear(perform: assignDelegate)
        .padding()
        .blur(radius: self.isBlurringCameraView ? 20 : 0)
        .sheet(isPresented: $model.showResultsTable,
               onDismiss: showCameraView) {
                VStack() {
                    BlurDetectorResultsList(results: self.model.blurDetectionResults)
                    Button(action: self.showCameraView) {
                        Text("Close")
                            .bold()
                    }
                }
                .padding()
        }
            
        .overlay(
            Text("Processing...")
                .bold()
                .opacity(self.model.mode == .processing ? 1 : 0)
        )
    }
}
