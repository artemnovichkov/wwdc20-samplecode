/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A server that vends SiriKit objects.
*/

import Foundation
import Intents
import Contacts

class Server {
    static let sharedInstance: Server = {
        let instance = Server()
        instance.createReservations()
        return instance
    }()

    fileprivate let bookingTime = Date(timeIntervalSince1970: 1_559_554_860)

    fileprivate var reservationContainersDictionary: [INSpeakableString: [INReservation]] = [:]

    func reservationContainers() -> [INSpeakableString] {
        return Array(reservationContainersDictionary.keys)
    }

    func reservations(inReservationContainer reservationContainer: INSpeakableString) -> [INReservation]? {
        return reservationContainersDictionary[reservationContainer]
    }

    func reservation(withItemReference itemReference: INSpeakableString) -> INReservation? {
        for reservationContainer in reservationContainersDictionary.keys {
            let reservations = reservationContainersDictionary[reservationContainer]
            if let reservation = reservations?.first(where: { $0.itemReference == itemReference }) {
                return reservation
            }
        }
        return nil
    }

    func reservationContainerReference(forReservationItemReference reservationItemReference: INSpeakableString) -> INSpeakableString? {
        let containerReference = reservationContainersDictionary.first { speakableString, reservations in
            return reservations.contains { $0.itemReference == reservationItemReference }
        }
        return containerReference?.key
    }

    fileprivate func createReservations() {
        /*
         For this sample to produce reliable results regardless of when it's run, all dates are laid
         out relative to today and to each other.

         In your app, this kind of datetime gymnastics should not be necessary since you're likely
         dealing with fixed times for your users reservations.

         For the best user experience, it is recommended to use dates, times and time zones relevant to where
         the occurence is taking place. For instance, for a flight departing in one time zone and arriving in
         another it is recommended to specify the departure time in the time zone of the departure location
         and the arrival time in the time zone of the arrival location.

         If this is not possible in your app, please provide datetimes in UTC.
         */
        createSanFranciscoTripReservation()
        createRentalCarReservation()
    }

    fileprivate func createSanFranciscoTripReservation() {

        // This marks the start of laying out the datetimes relative to each other. Your app should not need to do this.

        let calendar = Calendar(identifier: .gregorian)
        let originTimeZone = TimeZone(identifier: "Europe/Paris")!
        let destinationTimeZone = TimeZone(identifier: "America/Los_Angeles")!
        let tomorrowDateComponents = DateComponents.dateComponentsForTomorrow(withCalendar: calendar)

        // Flight departs tomorrow at 10 am:
        var flightDepartureDateComponents = tomorrowDateComponents
        flightDepartureDateComponents.hour = 10
        flightDepartureDateComponents.minute = 0
        flightDepartureDateComponents.timeZone = originTimeZone

        // Flight arrives 9 hours and 35 minutes after departure:
        let flightArrivalDateComponents = calendar.components(inTimeZone: destinationTimeZone,
                                                              byAdding: DateComponents(hour: 9, minute: 35),
                                                              to: calendar.date(from: flightDepartureDateComponents)!)!

        // Check-in for this flight opens 24 hours prior to departure and is open until 1 hour prior to departure.
        let checkStartDateComponents = calendar.components(inTimeZone: originTimeZone,
                                                           byAdding: DateComponents(hour: -24),
                                                           to: flightDepartureDateComponents)!
        let checkEndDateComponents = calendar.components(inTimeZone: originTimeZone,
                                                         byAdding: DateComponents(hour: -1),
                                                         to: flightDepartureDateComponents)!
        let checkInValidDuration = INDateComponentsRange(start: checkStartDateComponents, end: checkEndDateComponents)

        // The hotel reservation is for the day the flight arrives with check-in at 3pm
        var hotelCheckInDateComponents = flightArrivalDateComponents
        hotelCheckInDateComponents.hour = 15
        hotelCheckInDateComponents.minute = 0

        // The hotel reservation is for 2 nights and check out is at 11 am
        var hotelCheckOutDateComponents = calendar.components(inTimeZone: destinationTimeZone,
                                                              byAdding: DateComponents(day: 2),
                                                              to: hotelCheckInDateComponents)!
        hotelCheckOutDateComponents.hour = 11
        hotelCheckOutDateComponents.minute = 0

        // This marks the end of laying out the datetimes relative to each other and start of API usage example

        /**
         * The reserved flight departs from OSL airport and arrives at SFO airport.
         *
         * - Note: If you don't know both the IATA and ICAO code, it's OK to only use one of them.
         * - Note: If you don't know the terminal or gate, it's OK to set them to nil.
         */
        let departureAirport = INAirport(name: nil, iataCode: "OSL", icaoCode: nil)
        let departureAirportGate = INAirportGate(airport: departureAirport, terminal: nil, gate: nil)
        let arrivalAirport = INAirport(name: nil, iataCode: "SFO", icaoCode: nil)
        let arrivalAirportGate = INAirportGate(airport: arrivalAirport, terminal: "1", gate: nil)

        /**
         * The reservation is for flight XX 815.
         *
         * - Note: Specify only the flight number in the flightNumber parameter, exluding the IATA or ICAO code.
         */
        let flight = INFlight(airline: INAirline(name: "Sample Airlines", iataCode: "XX", icaoCode: nil),
                              flightNumber: "815",
                              boardingTime: nil,
                              flightDuration: INDateComponentsRange(start: flightDepartureDateComponents, end: flightArrivalDateComponents),
                              departureAirportGate: departureAirportGate,
                              arrivalAirportGate: arrivalAirportGate)

        /**
         * Provide a user activity for checking in. Siri may display this as a suggested shortcut at an opportune time
         * that falls within the validDuration. When pressed, your app is expected to handle being launched with the specified
         * user activity and display the check-in flow to the user.
         *
         * - Note: If the user has already checked in for this reservation, do not attach a check in activity. If the reservation
         *         is being shown as a result of the user checking in, donate again without the check in activity.
         * - Note: The user activity title is what's being displayed to the user as the title of the suggested shortcut.
         * - Note: Make sure you specify what keys from the userInfo dictionary your app needs to be able to successfully start the
         *         check-in flow.
         */
        let checkInActivity = NSUserActivity(activityType: "com.example.apple-samplecode.Siri-Event-Suggestions.check-in")
        checkInActivity.title = "Check in for flight \(flight.airline.iataCode!) \(flight.flightNumber)"
        checkInActivity.userInfo = ["bookingNumber": "SAMPLE-001"]
        checkInActivity.requiredUserInfoKeys = ["bookingNumber"]
        checkInActivity.webpageURL = URL(string: "http://sample.example/checkin?bookingNumber=SAMPLE-001")
        let checkInAction = INReservationAction(type: .checkIn, validDuration: checkInValidDuration, userActivity: checkInActivity)

        /**
         * The two flights where booked together and share a booking number. Since there are two passengers, you should donate two reservations
         * sharing the same booking number.
         *
         * - Note: Be sure to specify an identifier that is unique within your app for every INReservation object you intend to donate.
         *         Your app may be launched with an INGetReservationDetailsIntent containing this INSpeakableString in the
         *         reservationItemReferences array.
         */
        let johnnysFlightReservationItemReference = INSpeakableString(vocabularyIdentifier: "c7e795f2",
                                                                      spokenPhrase: "Flight to San Francisco (Johnny)",
                                                                      pronunciationHint: nil)
        let johnnysFlightReservationURL = URL(string: "http://sample.example/reservation?bookingNumber=SAMPLE-001&ticket=c7e795f2")
        let johnnysFlightReservation = INFlightReservation(itemReference: johnnysFlightReservationItemReference,
                                                           reservationNumber: "SAMPLE-001",
                                                           bookingTime: bookingTime,
                                                           reservationStatus: .confirmed,
                                                           reservationHolderName: "Johnny Appleseed",
                                                           actions: [checkInAction],
                                                           url: johnnysFlightReservationURL,
                                                           reservedSeat: nil,
                                                           flight: flight)

        let janesFlightReservationItemReference = INSpeakableString(vocabularyIdentifier: "c7f7q5l1",
                                                                    spokenPhrase: "Flight to San Francisco (Jane)",
                                                                    pronunciationHint: nil)
        let janesFlightReservationURL = URL(string: "http://sample.example/reservation?bookingNumber=SAMPLE-001&ticket=c7f7q5l1")
        let janesFlightReservation = INFlightReservation(itemReference: janesFlightReservationItemReference,
                                                         reservationNumber: "SAMPLE-001",
                                                         bookingTime: bookingTime,
                                                         reservationStatus: .confirmed,
                                                         reservationHolderName: "Jane Appleseed",
                                                         actions: [checkInAction],
                                                         url: janesFlightReservationURL,
                                                         reservedSeat: nil,
                                                         flight: flight)

        /**
         * The hotel was booked together with the flight and shares the same booking number.
         *
         * - Note: If you don't know the coordinate of a location, please use 0,0 to indicate this.
         * - Note: Be sure to specify an identifier that is unique within your app for every INReservation object you intend to donate.
         *         Your app may be launched with an INGetReservationDetailsIntent containing this INSpeakableString in the
         *         reservationItemReferences array.
         */
        let hotelReservationItemReference = INSpeakableString(vocabularyIdentifier: "c7e795f3",
                                                              spokenPhrase: "2 nights at Sample Inn",
                                                              pronunciationHint: nil)
        let hotelAddress = CNMutablePostalAddress()
        hotelAddress.street = "800 John F Kennedy Dr"
        hotelAddress.city = "San Francisco"
        hotelAddress.state = "CA"
        hotelAddress.postalCode = "94121"
        hotelAddress.country = "USA"
        let hotel = CLPlacemark(location: CLLocation(latitude: 0, longitude: 0), name: "Sample Inn", postalAddress: hotelAddress)
        let hotelReservationURL = URL(string: "http://sample.example/reservation?bookingNumber=SAMPLE-001&id=c7e795f3")
        let hotelReservation = INLodgingReservation(itemReference: hotelReservationItemReference,
                                                    reservationNumber: "SAMPLE-001",
                                                    bookingTime: bookingTime,
                                                    reservationStatus: .confirmed,
                                                    reservationHolderName: "Jane Appleseed",
                                                    actions: nil,
                                                    url: hotelReservationURL,
                                                    lodgingBusinessLocation: hotel,
                                                    reservationDuration: INDateComponentsRange(start: hotelCheckInDateComponents,
                                                                                               end: hotelCheckOutDateComponents),
                                                    numberOfAdults: 1,
                                                    numberOfChildren: 0)

        /**
         * Donate all three reservations together.
         *
         * - Note: Since all three reservations will end up being donated together, the container reference should be an identifier the app
         *         can use to uniquely identify this group of three reservations. The spoken phrase should also be something that makes
         *         sense to the user as it might be used as a shortcut.
         */
        let reservationContainerReference = INSpeakableString(vocabularyIdentifier: "df9bc3f5",
                                                              spokenPhrase: "Trip to San Francisco",
                                                              pronunciationHint: nil)
        reservationContainersDictionary[reservationContainerReference] = [johnnysFlightReservation, janesFlightReservation, hotelReservation]
    }

    fileprivate func createRentalCarReservation() {
        // This marks the start of laying out the datetimes relative to each other. Your app should not need to do this.

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let todayDateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        let inFourDaysDateComponents = calendar.components(inTimeZone: calendar.timeZone,
                                                           byAdding: DateComponents(day: 4),
                                                           to: todayDateComponents, wrappingComponents: false)!

        // This marks the end of laying out the datetimes relative to each other and start of API usage example

        let rentalCarReservationNumber = "SAMPLE-002"
        let rentalCarReservationReference = INSpeakableString(vocabularyIdentifier: "9f111gz3",
                                                              spokenPhrase: "Car reservation \(rentalCarReservationNumber)",
            pronunciationHint: nil)

        /**
         * The reservation is for a Sample Make Sample Model
         *
         * - Note: The rental company name might be different from the location name. For instance, the company name might be
         *         "Sample Rental Corp",  but a specific location might be named "Sample Rental Sample Location".
         */
        let rentalCar = INRentalCar(rentalCompanyName: "Sample Rental Corp",
                                    type: "Economy Class Car",
                                    make: "Sample Make",
                                    model: "Sample Model",
                                    rentalCarDescription: "An economy class Sample Make Sample Model or similar with 4 doors")

        /**
         * The pickup date is four days from today at 10 am and drop-off is the same day at 9 pm.
         *
         * - Note: Be sure to set the correct time zone for the pick-up and drop-off locations even if they're
         *         in the same time zone as the user.
         */
        var pickupTime = inFourDaysDateComponents
        pickupTime.hour = 10
        pickupTime.minute = 00

        var dropOffTime = inFourDaysDateComponents
        dropOffTime.hour = 21
        dropOffTime.minute = 00

        /**
         * The car should be picked up and dropped off at Sample Rental Sample Location
         *
         * - Note: If you don't know the coordinate of a location, please use 0,0 to indicate this.
         */
        let pickupLocation = CLPlacemark(location: CLLocation(latitude: 37.770_233, longitude: -122.509_659),
                                         name: "Sample Rental Sample Location",
                                         postalAddress: nil)

        /**
         * Create the INRentalCarReservation object
         *
         * - Note: Be sure to specify an identifier that is unique within your app for every INReservation object you intend to donate.
         *         Your app may be launched with an INGetReservationDetailsIntent containing this INSpeakableString in the
         *         reservationItemReferences array.
         * - Note: Even if your pickup and dropoff locations are the same, be sure to specify both.
         */
        let rentalReservation = INRentalCarReservation(itemReference: rentalCarReservationReference,
                                                       reservationNumber: rentalCarReservationNumber,
                                                       bookingTime: bookingTime,
                                                       reservationStatus: .confirmed,
                                                       reservationHolderName: "Jane Appleseed",
                                                       actions: nil,
                                                       rentalCar: rentalCar,
                                                       rentalDuration: INDateComponentsRange(start: pickupTime, end: dropOffTime),
                                                       pickupLocation: pickupLocation,
                                                       dropOffLocation: pickupLocation)

        reservationContainersDictionary[rentalCarReservationReference] = [rentalReservation]
    }
}
