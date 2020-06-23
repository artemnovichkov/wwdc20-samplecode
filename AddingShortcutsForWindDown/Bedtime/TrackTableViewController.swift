/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A table view controller that displays the tracks within a specific soundscape container.
*/

import UIKit
import BedtimeKit

class TrackTableViewController: UITableViewController {
    
    private static let CellID = "TrackCell"
    
    var libraryContainer: Soundscape! {
        didSet {
            title = libraryContainer.title
            tracksInContainer = SoundLibraryDataManager.shared.tracks(for: libraryContainer.itemID)
            tableView.reloadData()
        }
    }
    
    private var tracksInContainer = [Track]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
    }
    
    private func play(tracks: [Track]?) {
        let request = PlayRequest(container: libraryContainer, tracks: tracks)
        SoundLibraryDataManager.shared.donatePlayRequestToSystem(request)
        
        if let itemsToPlay = AudioPlaybackManager.shared.resolveItems(for: request) {
            AudioPlaybackManager.shared.play(itemsToPlay)
        }
    }
    
    @IBAction private func playAll(_ sender: Any) {
        play(tracks: nil)
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)
        
        guard let containerID = activity.userInfo?[NSUserActivity.LibraryItemContainerIDKey] as? LibraryItemID,
            let container = SoundLibraryDataManager.shared.container(matching: containerID)
            else { return }
        
        libraryContainer = container
    }
}

/// UITableViewDataSource
extension TrackTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracksInContainer.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = tracksInContainer[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewController.CellID, for: indexPath)
        cell.textLabel?.text = track.title
        
        return cell
    }
}

/// UITableViewDelegate
extension TrackTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        play(tracks: [tracksInContainer[indexPath.row]])
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
