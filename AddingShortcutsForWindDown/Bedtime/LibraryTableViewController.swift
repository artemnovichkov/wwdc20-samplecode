/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A `UIViewController` that displays the sound library's soundscape track containers.
*/

import UIKit
import BedtimeKit

class SoundLibraryTableViewCell: UITableViewCell {
    
    static let CellID = "LibraryCell"
    
    @IBOutlet weak var libraryItemImageView: UIImageView!
    @IBOutlet weak var libraryItemTitleLabel: UILabel!
    @IBOutlet weak var libraryItemSubtitleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        libraryItemImageView.layer.cornerRadius = 8
    }
}

class LibraryTableViewController: UITableViewController {
    
    private enum SegueIdentifiers: String {
        case trackSegue
    }
    
    var selectedContainer: Soundscape?
    
    private lazy var libraryManager: SoundLibraryDataManager = {
        let libraryManager = SoundLibraryDataManager.shared
        
        return libraryManager
    }()
    
    @IBAction private func stopPlayback(_ sender: Any) {
        AudioPlaybackManager.shared.stopPlaying()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.trackSegue.rawValue {
            guard let trackController = segue.destination as? TrackTableViewController else { return }
            
            var containerToPass = selectedContainer
            if containerToPass == nil, let selectedIndexPath = tableView.indexPathForSelectedRow {
                containerToPass = container(for: selectedIndexPath)
            }
           
            if let container = containerToPass {
                trackController.libraryContainer = container
            }
            
            selectedContainer = nil
        }
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)
        
        guard navigationController?.visibleViewController == self,
            let containerID = activity.userInfo?[NSUserActivity.LibraryItemContainerIDKey] as? LibraryItemID,
            let container = SoundLibraryDataManager.shared.container(matching: containerID)
            else { return }
        
        selectedContainer = container
        performSegue(withIdentifier: SegueIdentifiers.trackSegue.rawValue, sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let stopButton = UIBarButtonItem(title: "Stop Audio", style: .plain, target: self, action: #selector(stopPlayback(_:)))
        toolbarItems = [stopButton]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isToolbarHidden = false
    }
    
    private func container(for indexPath: IndexPath) -> Soundscape? {
        let containersForSection: [Soundscape] = libraryManager.soundLibrary.soundscapes
        
        return containersForSection[indexPath.row]
    }
}

extension LibraryTableViewController {
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return libraryManager.soundLibrary.soundscapes.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SoundLibraryTableViewCell.CellID, for: indexPath)
        
        if let libraryCell = cell as? SoundLibraryTableViewCell {
            let dataItem = libraryManager.soundLibrary.soundscapes[indexPath.row]
            libraryCell.libraryItemTitleLabel.text = dataItem.title
            libraryCell.libraryItemSubtitleLabel.text = dataItem.containerName
            libraryCell.libraryItemImageView.image = UIImage(named: dataItem.artworkName)
            let trackCount = libraryManager.tracks(for: dataItem.itemID).count
            libraryCell.detailLabel.text = "\(trackCount)"
        }
        
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Soundscapes"
    }
}
