/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller for user settings.
*/

import UIKit
import os.log

class UserSettingsTableViewController: UITableViewController {
    @IBOutlet weak var playerNameTextField: UITextField!
    @IBOutlet weak var spectatorSwitch: UISwitch!
    @IBOutlet weak var musicVolume: UISlider!
    @IBOutlet weak var effectsVolume: UISlider!
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var selectedLevelLabel: UILabel!

    let defaults = UserDefaults.standard
    var effectsLevelReleased: ButtonBeep!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateSelectedLevel()
        
        playerNameTextField.text = defaults.myself.username
        spectatorSwitch.isOn = defaults.spectator
        musicVolume.value = defaults.musicVolume
        effectsVolume.value = defaults.effectsVolume
        effectsLevelReleased = ButtonBeep(name: "catapult_highlight_on_02.wav", volume: defaults.effectsVolume)
        appVersionLabel.text = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? 0)"
            + " (\(Bundle.main.infoDictionary?["CFBundleVersion"] ?? 0))"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier,
            let segueType = GameSegue(rawValue: segueIdentifier) else {
                return
        }
        
        switch segueType {
        case .levelSelector:
            guard let levelSelector = segue.destination as? LevelSelectorViewController else { return }
            levelSelector.delegate = self
        default:
            break
        }
    }

    @IBAction func spectatorChanged(_ sender: UISwitch) {
        defaults.spectator = sender.isOn
    }
    
    @IBAction func musicVolumeChanged(_ sender: UISlider) {
        UserDefaults.standard.musicVolume = sender.value
    }
    
    @IBAction func effectsVolumeChanged(_ sender: UISlider) {
        UserDefaults.standard.effectsVolume = sender.value
    }
    
    @IBAction func effectsVolumeSliderReleased(_ sender: UISlider) {
        effectsLevelReleased.play()
    }

    @IBAction func doneTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func updateSelectedLevel() {
        let selectedLevel = UserDefaults.standard.selectedLevel
        selectedLevelLabel.text = selectedLevel.name
        os_log(.debug, "Selected level: %s", selectedLevel.name)
    }
}

extension UserSettingsTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if reason == .committed, let username = playerNameTextField.text {
            UserDefaults.standard.myself = Player(username: username)
        } else {
            playerNameTextField.text = UserDefaults.standard.myself.username
        }
    }
}

extension UserSettingsTableViewController: LevelSelectorViewControllerDelegate {
    func levelSelectorViewController(_ levelSelectorViewController: LevelSelectorViewController, didSelect level: GameLevel) {
        updateSelectedLevel()
    }
}
