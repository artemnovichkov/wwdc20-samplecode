/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A table view controller that displays a list of individual reservations in a group of reservations.
*/

import UIKit
import Intents

class ReservationsTableViewController: UITableViewController {
    var reservationContainerReference: INSpeakableString?
    var reservations: [INReservation] = []
    
    private var datasource: UITableViewDiffableDataSource<Int, INReservation>!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let reservationContainerReference = reservationContainerReference {
            self.navigationItem.title = reservationContainerReference.spokenPhrase
            if let reservations = Server.sharedInstance.reservations(inReservationContainer: reservationContainerReference) {
                self.reservations = reservations

                // Donate the reservations when the user sees them
                donateReservations()
                buildTable()
            }
        }
    }
    
    private final func buildTable() {
        datasource = UITableViewDiffableDataSource<Int, INReservation>(tableView: tableView) {
            (tableView: UITableView, indexPath: IndexPath, item: INReservation) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReservationCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = item.itemReference.spokenPhrase
            cell.contentConfiguration = content
            return cell
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if datasource.snapshot().itemIdentifiers.isEmpty {
            var snapshot = NSDiffableDataSourceSnapshot<Int, INReservation>()
            // remove the placehoolder storyboard snapshot and prepare the table for our data
            datasource.apply(snapshot, animatingDifferences: false)
            snapshot.appendSections([0])
            snapshot.appendItems(reservations, toSection: 0)
            datasource.apply(snapshot, animatingDifferences: false)
        }
    }

    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedReservation = reservations[indexPath.row]
        showReservation(selectedReservation)
    }

    // MARK: - Helpers
    
    fileprivate func showReservation(_ reservation: INReservation) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let reservationDetailsViewController = storyboard.instantiateViewController(withIdentifier: "ReservationDetailsViewController")
            as? ReservationDetailsViewController {
            reservationDetailsViewController.reservationContainerReference = reservationContainerReference
            reservationDetailsViewController.reservation = reservation
            self.present(reservationDetailsViewController, animated: true, completion: nil)
        }
    }

    fileprivate func donateReservations() {
        guard let reservationContainerReference = reservationContainerReference, !reservations.isEmpty else {
            return
        }

        let intent = INGetReservationDetailsIntent(reservationContainerReference: reservationContainerReference,
                                                   reservationItemReferences: nil)

        let intentResponse = INGetReservationDetailsIntentResponse(code: .success, userActivity: nil)
        intentResponse.reservations = reservations

        let interaction = INInteraction(intent: intent, response: intentResponse)
        interaction.donate { error in
            if let error = error {
                print(error)
            }
        }
    }
}
