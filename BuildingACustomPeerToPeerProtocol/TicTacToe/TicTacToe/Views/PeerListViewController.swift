/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implement the view controller in which you allow the user
		to host a game and discover peers.
*/

import UIKit
import Network

class PeerListViewController: UITableViewController {

	@IBOutlet weak var nameField: UITextField!
	@IBOutlet weak var passcodeLabel: UILabel!

	var results: [NWBrowser.Result] = [NWBrowser.Result]()
	var name: String = "Default"
	var passcode: String = ""

	var sections: [GameFinderSection] = [.host, .join]

	enum GameFinderSection {
		case host
		case passcode
		case join
	}

	func shouldShowPasscode() -> Bool {
		if sharedListener != nil {
			return true
		}
		return false
	}

	func resultRows() -> Int {
		if results.isEmpty {
			return 1
		} else {
			return min(results.count, 6)
		}
	}

	// Generate a new random passcode when the app starts hosting games.
	func generatePasscode() -> String {
		return String("\(Int.random(in: 0...9))\(Int.random(in: 0...9))\(Int.random(in: 0...9))\(Int.random(in: 0...9))")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		// Generate a new passcode.
		passcode = generatePasscode()
		passcodeLabel.text = passcode

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "joinGameCell")
	}

	func hostGameButton() {
		// Dismiss the keyboard when the user starts hosting.
		view.endEditing(true)

		// Validate that the user's entered name is not empty.
		guard let name = nameField.text,
			!name.isEmpty else {
			return
		}

		self.name = name
		if let listener = sharedListener {
			// If your app is already listening, just update the name.
			listener.resetName(name)
		} else {
			// If your app is not yet listening, start a new listener.
			sharedListener = PeerListener(name: name, passcode: passcode, delegate: self)
		}

		// Show the passcode field once you have started hosting a game.
		sections = [.host, .passcode, .join]
		tableView.reloadData()
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let passcodeVC = segue.destination as? PasscodeViewController {
			passcodeVC.browseResult = sender as? NWBrowser.Result
			passcodeVC.peerListViewController = self
		}
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return sections.count
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let currentSection = sections[section]
		switch currentSection {
		case .host:
			return 2
		case .passcode:
			return 1
		case .join:
			return resultRows()
		}
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let currentSection = sections[section]
		switch currentSection {
		case .host:
			return "Host Game"
		case .passcode:
			return "Passcode"
		case .join:
			return "Join Game"
		}
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let currentSection = sections[indexPath.section]
		if currentSection == .join {
			let cell = tableView.dequeueReusableCell(withIdentifier: "joinGameCell") ?? UITableViewCell(style: .default, reuseIdentifier: "joinGameCell")
			// Display the results that we've found, if any. Otherwise, show "searching..."
			if sharedBrowser == nil {
				cell.textLabel?.text = "Search for games"
				cell.textLabel?.textAlignment = .center
				cell.textLabel?.textColor = .systemBlue
			} else if results.isEmpty {
				cell.textLabel?.text = "Searching for games..."
				cell.textLabel?.textAlignment = .left
				cell.textLabel?.textColor = .black
			} else {
				let peerEndpoint = results[indexPath.row].endpoint
				if case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = peerEndpoint {
					cell.textLabel?.text = name
				} else {
					cell.textLabel?.text = "Unknown Endpoint"
				}
				cell.textLabel?.textAlignment = .left
				cell.textLabel?.textColor = .black
			}
			return cell
		}
		return super.tableView(tableView, cellForRowAt: indexPath)
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let currentSection = sections[indexPath.section]
		switch currentSection {
		case .host:
			if indexPath.row == 1 {
				hostGameButton()
			}
		case .join:
			if sharedBrowser == nil {
				sharedBrowser = PeerBrowser(delegate: self)
			} else if !results.isEmpty {
				// Handle the user tapping on a discovered game
				let result = results[indexPath.row]
				performSegue(withIdentifier: "showPasscodeSegue", sender: result)
			}
		default:
			print("Tapped inactive row: \(indexPath)")
		}

		tableView.deselectRow(at: indexPath, animated: true)
	}
}

extension PeerListViewController: PeerBrowserDelegate {
	// When the discovered peers change, update the list.
	func refreshResults(results: Set<NWBrowser.Result>) {
		self.results = [NWBrowser.Result]()
		for result in results {
			if case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = result.endpoint {
				if name != self.name {
					self.results.append(result)
				}
			}
		}
		tableView.reloadData()
	}

	// Show an error if peer discovery failed.
	func displayBrowseError(_ error: NWError) {
		var message = "Error \(error)"
		if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_NoAuth)) {
			message = "Not allowed to access the network"
		}
		let alert = UIAlertController(title: "Cannot discover other players",
									  message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		self.present(alert, animated: true)
	}
}

extension PeerListViewController: PeerConnectionDelegate {
	// When a connection becomes ready, move into game mode.
	func connectionReady() {
		navigationController?.performSegue(withIdentifier: "showGameSegue", sender: nil)
	}

	// When the a game cannot be advertised, show an error
	func displayAdvertiseError(_ error: NWError) {
		var message = "Error \(error)"
		if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_NoAuth)) {
			message = "Not allowed to access the network"
		}
		let alert = UIAlertController(title: "Cannot host game",
									  message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		self.present(alert, animated: true)
	}

	// Ignore connection failures and messages prior to starting a game.
	func connectionFailed() { }
	func receivedMessage(content: Data?, message: NWProtocolFramer.Message) { }
}
