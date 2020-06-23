/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller for in-game 2D overlay UI.
*/

import UIKit
import AVFoundation
import os.log

protocol GameStartViewControllerDelegate: class {
    func gameStartViewController(_ gameStartViewController: UIViewController, didPressStartSoloGameButton: UIButton)
    func gameStartViewController(_ gameStartViewController: UIViewController, didSelect game: NetworkSession)
    func gameStartViewController(_ gameStartViewController: UIViewController, didStart game: NetworkSession)
    func gameStartViewControllerSelectedSettings(_ gameStartViewController: UIViewController)
}

enum GameSegue: String {
    case embeddedGameBrowser
    case embeddedOverlay
    case showSettings
    case levelSelector
    case worldMapSelector
}

class GameStartViewController: UIViewController {
    weak var delegate: GameStartViewControllerDelegate?
    
    @IBOutlet weak var hostButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var browserContainerView: UIView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var nearbyGamesLabel: UILabel!
    var buttonBeep: ButtonBeep!
    var backButtonBeep: ButtonBeep!
    
    private let myself = UserDefaults.standard.myself
    
    let proximityManager = ProximityManager.shared
    var gameBrowser: GameBrowser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        proximityManager.delegate = self
        hostButton.clipsToBounds = true
        hostButton.layer.cornerRadius = 30.0
        
        joinButton.clipsToBounds = true
        joinButton.layer.cornerRadius = 30.0

        buttonBeep = ButtonBeep(name: "button_forward.wav", volume: 0.5)
        backButtonBeep = ButtonBeep(name: "button_backward.wav", volume: 0.5)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UserDefaults.standard.gameRoomMode {
            os_log(.debug, "Will start beacon ranging")
            proximityManager.start()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        os_log(.info, "segue!")
        guard let segueIdentifier = segue.identifier,
            let segueType = GameSegue(rawValue: segueIdentifier) else {
                os_log(.error, "unknown segue %s", String(describing: segue.identifier))
                return
        }
        
        switch segueType {
        case .embeddedGameBrowser:
            guard let browser = segue.destination as? NetworkGameBrowserViewController else { return }
            gameBrowser = GameBrowser(myself: myself)
            browser.browser = gameBrowser
            browser.proximityManager = proximityManager
        default:
            break
        }
    }
    
    func joinGame(session: NetworkSession) {
        delegate?.gameStartViewController(self, didSelect: session)
        setupOverlayVC()
    }
    
    @IBAction func startSoloGamePressed(_ sender: UIButton) {
        delegate?.gameStartViewController(self, didPressStartSoloGameButton: sender)
    }
    
    @IBAction func startGamePressed(_ sender: UIButton) {
        buttonBeep.play()

        startGame(with: myself)
    }
    
    @IBAction func settingsPressed(_ sender: Any) {
        delegate?.gameStartViewControllerSelectedSettings(self)
    }
   
    @IBAction func joinButtonPressed(_ sender: Any) {
        buttonBeep.play()
        showViews(forSetup: false)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        backButtonBeep.play()
        setupOverlayVC()
    }
    
    func setupOverlayVC() {
        showViews(forSetup: true)
    }
    
    func showViews(forSetup: Bool) {
        UIView.transition(with: view, duration: 1.0, options: [.transitionCrossDissolve], animations: {
            self.blurView.isHidden = forSetup
            self.browserContainerView.isHidden = forSetup
            self.backButton.isHidden = forSetup
            self.nearbyGamesLabel.isHidden = forSetup
            
            self.joinButton.isHidden = !forSetup
            self.hostButton.isHidden = !forSetup
        }, completion: nil)
    }
    
    func startGame(with player: Player) {
        let location: GameTableLocation?
        if UserDefaults.standard.gameRoomMode {
            location = proximityManager.closestLocation
        } else {
            location = nil
        }
        
        let gameSession = NetworkSession(myself: player, asServer: true, location: location, host: myself)
        delegate?.gameStartViewController(self, didStart: gameSession)
        setupOverlayVC()
    }
}

extension GameStartViewController: ProximityManagerDelegate {
    func proximityManager(_ manager: ProximityManager, didChange location: GameTableLocation?) {
        gameBrowser?.refresh()
    }
    
    func proximityManager(_ manager: ProximityManager, didChange authorization: Bool) {

    }
}
