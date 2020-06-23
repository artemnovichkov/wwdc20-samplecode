/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implement the passcode entry view controller.
*/

import UIKit
import Network

class PasscodeViewController: UITableViewController {

	@IBOutlet weak var passcodeField: UITextField!
	var browseResult: NWBrowser.Result?
	var peerListViewController: PeerListViewController?

	var hasPlayedGame = false

	override func viewDidLoad() {
		super.viewDidLoad()

		if let browseResult = browseResult,
			case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = browseResult.endpoint {
			title = "Join \(name)"
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if hasPlayedGame {
			navigationController?.popToRootViewController(animated: false)
			hasPlayedGame = false
		}
	}

	func joinPressed() {
		hasPlayedGame = true
		if let passcode = passcodeField.text,
			let browseResult = browseResult,
			let peerListViewController = peerListViewController {
			sharedConnection = PeerConnection(endpoint: browseResult.endpoint,
											  interface: browseResult.interfaces.first,
											  passcode: passcode,
											  delegate: peerListViewController)
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 1 {
			joinPressed()
		}
		tableView.deselectRow(at: indexPath, animated: true)
	}
}
