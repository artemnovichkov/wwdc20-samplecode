/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that displays a single reservation.
*/

import UIKit
import Intents

class ReservationDetailsViewController: UIViewController {
    var reservationContainerReference: INSpeakableString?
    var reservation: INReservation?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Donate the reservation when the user sees it
        donateReservation()
    }

    func donateReservation() {
        guard let reservation = reservation, let reservationContainerReference = reservationContainerReference else {
            return
        }

        let intent = INGetReservationDetailsIntent(reservationContainerReference: reservationContainerReference,
                                                   reservationItemReferences: nil)
        let intentResponse = INGetReservationDetailsIntentResponse(code: .success, userActivity: nil)
        intentResponse.reservations = [reservation]
        let interaction = INInteraction(intent: intent, response: intentResponse)
        interaction.donate { error in
            if let error = error {
                print(error)
            }
        }
    }
}
