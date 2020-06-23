/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's content view. The view controller calls AssetLoader to load the asset and the compositions.
 It then uses them to create an AVPlayerItem and an AVPlayer to play the video composition.
*/

import SwiftUI
import AVKit
import AVFoundation

struct AVPlayerViewControllerRepresentable: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = AVPlayerViewController
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let (avComposition, videoComposition) = AssetLoader.loadAsCompositions()
        let playerItem = AVPlayerItem(asset: avComposition)
        playerItem.videoComposition = videoComposition
        
        controller.player = AVPlayer(playerItem: playerItem)
        controller.player?.play()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    }
}

struct ContentView: View {
    var body: some View {
        AVPlayerViewControllerRepresentable()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
