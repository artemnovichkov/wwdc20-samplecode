/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A table view controller that displays a list of reservation containers.
*/

import UIKit
import Intents

class ReservationContainersTableViewController: UITableViewController {
    var reservationContainers = [INSpeakableString]()
    fileprivate var showReservationNotificationToken: NSObjectProtocol?
    fileprivate var startCheckInNotificationToken: NSObjectProtocol?
    private var datasource: UITableViewDiffableDataSource<Int, INSpeakableString>!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        buildTable()
    }
    
    private final func buildTable() {
        updateReservations()
        datasource = UITableViewDiffableDataSource<Int, INSpeakableString>(tableView: tableView) {
            (tableView: UITableView, indexPath: IndexPath, item: INSpeakableString) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "reservationCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = item.spokenPhrase
            cell.contentConfiguration = content
            return cell
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if datasource.snapshot().itemIdentifiers.isEmpty {
            var snapshot = NSDiffableDataSourceSnapshot<Int, INSpeakableString>()
            // remove any old data and prepare the table for our data
            datasource.apply(snapshot, animatingDifferences: false)
            snapshot.appendSections([0])
            snapshot.appendItems(reservationContainers, toSection: 0)
            datasource.apply(snapshot, animatingDifferences: false)
        }
    }

    // MARK: - IBAction
    @IBAction func didPressClearButton(_ sender: AnyObject) {
        /**
         * Delete all interactions made by this app.
         *
         * - Note: Deleting an INInteraction with reservation details means Siri no longer knows about the
         *         reservation. If a user cancels a reservation, please donate an updated INReservation
         *         with the .canceled status instead of deleting the donation.
         */
        INInteraction.deleteAll(completion: nil)
    }

    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedReservationContainerReference = reservationContainers[indexPath.row]
        guard let reservations = Server.sharedInstance.reservations(inReservationContainer: selectedReservationContainerReference) else {
            return
        }

        if reservations.count == 1,
            let firstReservation = reservations.first,
            firstReservation.itemReference == selectedReservationContainerReference {
            // This is a single reservation, show it.
            showReservation(firstReservation, withReservationContainerReference: selectedReservationContainerReference)
        } else {
            // This is a group of reservations, show a list of individual reservations.
            showReservations(reservations, withReservationContainerReference: selectedReservationContainerReference)
        }
    }

    // MARK: - Helpers
    fileprivate func updateReservations() {
        let server = Server.sharedInstance
        reservationContainers = server.reservationContainers()
    }

    fileprivate func setupNotifications() {
        let notificationCenter = NotificationCenter.default

        // Handle notifications to show a specific reservation
        showReservationNotificationToken = notificationCenter.addObserver(forName: .showReservation, object: nil, queue: nil) { notification in
            guard let userActivity = notification.object as? NSUserActivity else {
                return
            }
            self.handleShowReservationNotification(withUserActivity: userActivity)
        }

        // Handle notifications to start the check-in flow
        startCheckInNotificationToken = notificationCenter.addObserver(forName: .startReservationCheckIn, object: nil, queue: nil) { notification in
            guard let userActivity = notification.object as? NSUserActivity else {
                return
            }
            self.handleStartCheckInNotification(withUserActivity: userActivity)
        }
    }

    fileprivate func showReservation(_ reservation: INReservation,
                                     withReservationContainerReference reservationContainerReference: INSpeakableString?) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let reservationDetailsViewController = storyboard.instantiateViewController(withIdentifier: "ReservationDetailsViewController")
            as? ReservationDetailsViewController {
            reservationDetailsViewController.reservationContainerReference = reservationContainerReference
            reservationDetailsViewController.reservation = reservation
            self.present(reservationDetailsViewController, animated: true, completion: nil)
        }
    }

    fileprivate func showReservations(_ reservations: [INReservation],
                                      withReservationContainerReference reservationContainerReference: INSpeakableString?) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let reservationsTableViewController = storyboard.instantiateViewController(withIdentifier: "ReservationsTableViewController")
            as? ReservationsTableViewController {
            reservationsTableViewController.reservationContainerReference = reservationContainerReference
            reservationsTableViewController.reservations = reservations
            self.navigationController?.pushViewController(reservationsTableViewController, animated: true)
        }
    }

    fileprivate func handleStartCheckInNotification(withUserActivity userActivity: NSUserActivity) {
        if let userInfo = userActivity.userInfo {
            if let bookingNumber = userInfo["bookingNumber"] {
                self.navigationController?.popToRootViewController(animated: false)
                let alert = UIAlertController(title: "Check in for \(bookingNumber)", message: "Start check-in flow", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    fileprivate func handleShowReservationNotification(withUserActivity userActivity: NSUserActivity) {
        guard let intent = userActivity.interaction?.intent as? INGetReservationDetailsIntent else {
            return
        }

        guard let reservationItemReferences = intent.reservationItemReferences else {
            return
        }

        // The app was launched with an reservationItemReferences array containing a single reservation, indicating it should
        // show a single reservation.
        if reservationItemReferences.count == 1, let reservationItemReference = reservationItemReferences.first {
            guard let reservation = Server.sharedInstance.reservation(withItemReference: reservationItemReference) else {
                return
            }
            showReservation(reservation, withReservationContainerReference: intent.reservationContainerReference)
        }
        // The app was launched with multiple items in the reservationItemReferences array indicating we should show a group
        // of reservations. Use the reservationContainerReference property to figure out what group to show.
        else if let reservationContainerReference = intent.reservationContainerReference {
            guard let reservations = Server.sharedInstance.reservations(inReservationContainer: reservationContainerReference) else {
                return
            }
            showReservations(reservations, withReservationContainerReference: reservationContainerReference)
        }
    }

    deinit {
        let notificationCenter = NotificationCenter.default
        if let showReservationNotificationToken = showReservationNotificationToken {
            notificationCenter.removeObserver(showReservationNotificationToken)
        }
        if let startCheckInNotificationToken = startCheckInNotificationToken {
            notificationCenter.removeObserver(startCheckInNotificationToken)
        }
    }
}

