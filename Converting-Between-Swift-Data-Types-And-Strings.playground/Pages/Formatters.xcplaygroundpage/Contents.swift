/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convert Swift data types to and from their string representations.
*/
//: [Table of Contents](Table%20of%20Contents) | [Next](@next)
import Foundation
/*:
 ## Number Formatter
 Provides localized representations of units and measurements.
*/

let numberFormatter = NumberFormatter()

let money = NSNumber(value: 5)
numberFormatter.locale = Locale(identifier: "en_US")
numberFormatter.numberStyle = .currency
numberFormatter.string(from: money)

let percentage = NSNumber(value: 0.05)
numberFormatter.numberStyle = .percent
numberFormatter.string(from: percentage)

let spell = NSNumber(value: 345)
numberFormatter.numberStyle = .spellOut
numberFormatter.string(from: spell)

let cents = NSNumber(value: 1.2345)
numberFormatter.maximumFractionDigits = 2 // Limits fraction to two decimal places
numberFormatter.locale = Locale.autoupdatingCurrent // Sets locale based on user's current location
numberFormatter.numberStyle = .currency
numberFormatter.string(from: cents)

/*:
 ## Person Name Components Formatter
 Provides localized representations of the components of a person’s name.
*/

let pncf = PersonNameComponentsFormatter()
var person = PersonNameComponents()
person.namePrefix = "Miss"
person.givenName = "Jane"
person.middleName = "Doe"
person.familyName = "Smith"

// Get string from Person Name Components
pncf.style = .short
pncf.string(from: person)

pncf.style = .medium // Same as .default
pncf.string(from: person)

pncf.style = .long
pncf.string(from: person)

pncf.style = .default
pncf.string(from: person)

// Get name components from string
let jane: PersonNameComponents = pncf.personNameComponents(from: "Jane Doe Smith")!
jane.givenName
jane.familyName

/*:
 ## Date Formatter
 Converts between dates and their textual representations.
*/

let paymentDate = Calendar.current.date(byAdding: DateComponents(day: 15), to: Date())! // 15 days from now
let dateFormatter = DateFormatter()

// Generate string representations from different locales and date styles
dateFormatter.locale = Locale(identifier: "en_US") // Change locale to US
dateFormatter.dateStyle = .short
dateFormatter.string(from: paymentDate) // Prints in US date format

dateFormatter.locale = Locale(identifier: "fr_FR") // Change locale to French for France
dateFormatter.dateStyle = .medium
dateFormatter.string(from: paymentDate) // Prints in French date format

dateFormatter.locale = Locale(identifier: "ja_JP") // Change locale to Japanese for Japan
dateFormatter.setLocalizedDateFormatFromTemplate("MMM d") // Define data format using template
dateFormatter.string(from: paymentDate) // Equivalent of "MMM d" in Japanese due to locale

// Generate Date from string representation
dateFormatter.dateFormat = "yyyy-MM-dd"
dateFormatter.date(from: "1984-01-24")

/*:
 ## Date Components Formatter
 Creates string representations of quantities of time.
*/

var dcf = DateComponentsFormatter()

dcf.unitsStyle = .full
dcf.includesApproximationPhrase = true // about...
dcf.includesTimeRemainingPhrase = true // ...remaining
dcf.allowedUnits = [.minute]

// Use the configured formatter to generate the string.
dcf.string(from: 300.0)

// DateComponentsFormatter configuration
var calendar = Calendar.current
dcf.calendar = calendar // Set formatter to Gregorian calendar.
dcf.allowedUnits = [.minute, .hour]

// DateComponentsFormatter unit styles
dcf.unitsStyle = .abbreviated
dcf.string(from: 250.0)

dcf.unitsStyle = .brief
dcf.string(from: 250.0)

dcf.unitsStyle = .positional
dcf.string(from: 250.0)

dcf.unitsStyle = .short
dcf.string(from: 250.0)

dcf.unitsStyle = .full
dcf.string(from: 250.0)

/*:
 ## Date Interval Formatter
 Creates string representations of time intervals.
*/

let start = Date() // Current date
let end = Calendar.current.date(byAdding: DateComponents(day: 10), to: Date())! // 10 days from current date
let interval = DateInterval(start: start, end: end)

let dif = DateIntervalFormatter()

// Short date and time style
dif.dateStyle = .short
dif.timeStyle = .short
dif.string(from: interval)

// Medium date and time style
dif.dateStyle = .medium
dif.timeStyle = .medium
dif.string(from: interval)

// Long date and time style
dif.dateStyle = .long
dif.timeStyle = .long
dif.string(from: interval)

// Only time of day
dif.dateStyle = .none
dif.timeStyle = .short
dif.string(from: interval)

dif.string(from: start, to: end)
/*:
 ## ISO8601 Date Formatter
 Converts between dates and their ISO 8601 string representations.
*/

let isof = ISO8601DateFormatter()
let date = Date(timeIntervalSince1970: 443_826_000)

// Configuration
isof.timeZone = TimeZone.current

// Get ISO 8601 string representation from Date
isof.string(from: date)

// Get Date from ISO 8601 formatted strings
isof.formatOptions = [.withInternetDateTime]
isof.date(from: "1984-01-24T21:00:00Z") // String format: yyyy-mm-dd'T'hh:mm:ss'Z'

isof.formatOptions = [.withFullDate]
isof.date(from: "2000-09-16") // String format: yyyy-mm-dd

/*:
 ## Byte Count Formatter
 Converts a byte count value into a localized description that is formatted with the appropriate byte modifier (KB, MB, GB, etc.).
*/

let bcf = ByteCountFormatter()
var bytes: Int64 = Int64(123_456_789)
bcf.includesUnit = true
bcf.includesActualByteCount = true

// Changing units
bcf.allowedUnits = .useKB
bcf.string(fromByteCount: bytes)

bcf.allowedUnits = .useMB
bcf.string(fromByteCount: bytes)

bcf.allowedUnits = .useGB
bcf.string(fromByteCount: bytes)

// Changing count styles
bytes = Int64(100_000)
bcf.allowedUnits = .useAll // Determines best unit to use based on number of bytes

bcf.countStyle = .binary // 1024 bytes converts to 1 KB
bcf.string(fromByteCount: bytes)

bcf.countStyle = .decimal // 1000 bytes converts to 1 KB
bcf.string(fromByteCount: bytes)

bcf.countStyle = .file // File byte counts (decimal style in macOS)
bcf.string(fromByteCount: bytes)

bcf.countStyle = .memory // Memory byte counts (binary style in macOS)
bcf.string(fromByteCount: bytes)

/*:
 ## Measurement Formatter
 Provides localized representations of units and measurements.
*/

let distanceInMiles = Measurement(value: 5373, unit: UnitLength.miles)
let lengthInFeet = Measurement(value: 1000.0, unit: UnitLength.yards)
let measurementFormatter = MeasurementFormatter()

// Changing unit styles
measurementFormatter.unitStyle = .short
measurementFormatter.string(from: distanceInMiles)

measurementFormatter.unitStyle = .medium // Defaults to medium if not set
measurementFormatter.string(from: distanceInMiles)

measurementFormatter.unitStyle = .long
measurementFormatter.string(from: distanceInMiles)

// Changing locales
measurementFormatter.locale = Locale(identifier: "en_US") // Set locale to English for U.S.
measurementFormatter.string(from: distanceInMiles)

measurementFormatter.locale = Locale(identifier: "es_MX") // Set locale to Spanish for Mexico
measurementFormatter.string(from: distanceInMiles)

measurementFormatter.locale = Locale(identifier: "fr_FR") // Set locale to French for France
measurementFormatter.string(from: distanceInMiles)

// Formatter supports right to left locales
measurementFormatter.locale = Locale(identifier: "ar_SA") // Set locale to Arabic for Saudi Arabia
measurementFormatter.string(from: distanceInMiles) // Prints right to left

measurementFormatter.locale = Locale(identifier: "he_IL") // Set locale to Hebrew for Israel
measurementFormatter.string(from: distanceInMiles) // Prints right to left
//: [Table of Contents](Table%20of%20Contents)  | [Next](@next)
