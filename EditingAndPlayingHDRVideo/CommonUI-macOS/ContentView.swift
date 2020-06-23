/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's content view. It uses AVPlayer to play back the video composition, and respond to "Export" menu selection to
 initiate the export.
*/

import SwiftUI
import AVKit
import AVFoundation
import CoreImage

class PlayerView: AVPlayerView {
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let (avComposition, videoComposition) = AssetLoader.loadAsCompositions()
        let playerItem = AVPlayerItem(asset: avComposition)
        playerItem.videoComposition = videoComposition
        
        let player = AVPlayer(playerItem: playerItem)
        self.player = player
        if AVPlayer.eligibleForHDRPlayback {
            play()
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct PlayerViewRepresentable: NSViewRepresentable {
    static private var coordinator = Coordinator()
    class Coordinator {
        var playerView: PlayerView? = nil
    }
    func play() {
        Self.coordinator.playerView?.play()
    }
    func pause() {
        Self.coordinator.playerView?.pause()
    }
    func updateNSView(_ nsView: PlayerView, context: NSViewRepresentableContext<PlayerViewRepresentable>) {
        context.coordinator.playerView = nsView
    }
    
    func makeNSView(context: Context) -> PlayerView {
        context.coordinator.playerView = PlayerView(frame: .zero)
        return context.coordinator.playerView!
    }
    
    func makeCoordinator() -> Self.Coordinator {
        return Self.coordinator
    }
}

struct ContentView: View {
    enum AlertReason {
        case hdrNotSupported
        case tryToExportToExistingFile
        case exportDone
        case exportFailed
        case none
    }
    @State private var showingAlert = false
    @State private var alertReason: AlertReason = .none
    @State private var showingExportProgress = false
    @State private var exportProgressChecker: AssetExporter.ProgressChecker? = nil
    
    private let exportAssetMenuSelectPublisher = NotificationCenter.default.publisher(for: .exportAsset)
    
    var body: some View {
        let playerViewRepresentable = PlayerViewRepresentable()
        return playerViewRepresentable
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear() {
                if !AVPlayer.eligibleForHDRPlayback {
                    self.triggerAlert(reason: .hdrNotSupported)
                }
            }
            .onReceive(exportAssetMenuSelectPublisher) {_ in
                playerViewRepresentable.pause()
                self.exportAsset()
            }
            .alert(isPresented: $showingAlert) {
                switch alertReason {
                case .hdrNotSupported:
                    return Alert(title: Text("Warning"),
                                 message: Text("HDR playback is not supported under the current system configuration. Final display will be SDR."),
                                 dismissButton: Alert.Button.default(Text("OK"), action: {
                                    playerViewRepresentable.play()
                                 }))
                case .tryToExportToExistingFile:
                    return Alert(title: Text("Cannot Export"), message: Text("Cannot export to an existing file."))
                case .exportDone:
                    return Alert(title: Text("Export finished"), message: nil, dismissButton: Alert.Button.default(Text("OK"), action: {
                        self.showingExportProgress = false
                    }))
                case .exportFailed:
                    return Alert(title: Text("Export failed"), message: nil, dismissButton: Alert.Button.default(Text("OK"), action: {
                        self.showingExportProgress = false
                    }))
                case .none:
                    // should not get here
                    return Alert(title: Text(""))
                }
            }
            .sheet(isPresented: $showingExportProgress) {
                ProgressPopup(isVisible: self.$showingExportProgress, title: Text("Exporting ..."), progressUpdateHandler: { () -> Float in
                    return self.exportProgressChecker?.progress ?? 0
                })
            }
    }
    
    func triggerAlert(reason: AlertReason) {
        alertReason = reason
        showingAlert = true
    }
    
    func exportAsset() {
        let dialog = NSSavePanel()
        
        dialog.title = "Export to a movie file."
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canCreateDirectories = true
        dialog.allowedFileTypes = ["mov"]
        
        if dialog.runModal() == .OK {
            let fileURL = dialog.url
            if FileManager.default.fileExists(atPath: fileURL!.path) {
                self.triggerAlert(reason: .tryToExportToExistingFile)
                return
            }
            exportProgressChecker = AssetExporter.exportAsynchronously(url: dialog.url!) {
                if self.exportProgressChecker != nil && self.exportProgressChecker!.succeeded {
                    self.triggerAlert(reason: .exportDone)
                } else {
                    self.triggerAlert(reason: .exportFailed)
                }
            }
            if exportProgressChecker != nil && exportProgressChecker!.inProgress {
                self.showingExportProgress = true
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
}

struct ProgressPopup: View {
    @Binding var isVisible: Bool
    var title: Text
    var progressUpdateHandler: () -> Float
    
    @State private var progress: Float = 0
    @State private var timer: Timer? = nil
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                self.title.font(.headline)
                Text(self.getProgressPercentage()).padding()
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).opacity(0.1)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(minWidth: 0,
                               idealWidth: self.getProgressBarProgressWidth(geometry: geometry),
                               maxWidth: self.getProgressBarProgressWidth(geometry: geometry))
                        .opacity(1)
                        .animation(.default)
                }.frame(height: 8)
            }
            .padding()
            .onAppear() {
                self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {_ in
                    self.progress = self.progressUpdateHandler()
                }
            }
            .onDisappear() {
                self.timer?.invalidate()
            }
        }
        .frame(width: 350, height: 140)
        .cornerRadius(25)
    }
    
    func getProgressPercentage() -> String {
        return String(format: "%d%%", (Int) (progress * 100 + 0.5))
    }
    
    func getProgressBarProgressWidth(geometry: GeometryProxy) -> CGFloat {
        let frame = geometry.frame(in: .global)
        return frame.size.width * CGFloat(progress)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
