/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A controller that configures and updates the complications.
*/

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // The Coffee Tracker app's data model
    lazy var data = CoffeeData.shared
    
    // MARK: - Timeline Configuration
    
    // Define whether the app can provide future data.
    func getSupportedTimeTravelDirections(for complication: CLKComplication,
                                          withHandler handler:@escaping (CLKComplicationTimeTravelDirections) -> Void) {
        // Indicate that the app can provide future timeline entries.
        handler([.forward])
    }
    
    // Define how far into the future the app can provide data.
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Indicate that the app can provide timeline entries for the next 24 hours.
        handler(Date().addingTimeInterval(24.0 * 60.0 * 60.0))
    }
    
    // Define whether the complication is visible when the watch is unlocked.
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // This is potentially sensitive data. Hide it on the lock screen.
        handler(.hideOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    // Return the current timeline entry.
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        handler(createTimelineEntry(forComplication: complication, date: Date()))
    }
    
    // Return future timeline entries.
    func getTimelineEntries(for complication: CLKComplication,
                            after date: Date,
                            limit: Int,
                            withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        
        let fiveMinutes = 5.0 * 60.0
        let twentyFourHours = 24.0 * 60.0 * 60.0
        
        // Create an array to hold the timeline entries.
        var entries = [CLKComplicationTimelineEntry]()
        
        // Calculate the start and end dates.
        var current = date.addingTimeInterval(fiveMinutes)
        let endDate = date.addingTimeInterval(twentyFourHours)
        
        // Create a timeline entry for every five minutes from the starting time.
        // Stop once you reach the limit or the end date.
        while (current.compare(endDate) == .orderedAscending) && (entries.count < limit) {
            entries.append(createTimelineEntry(forComplication: complication, date: current))
            current = current.addingTimeInterval(fiveMinutes)
        }
        
        handler(entries)
    }
    
    // MARK: - Placeholder Templates
    
    // Return a localized template with generic information.
    // The system displays the placeholder in the complication selector.
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // Use a date more than 24-hours from now--so the complication always shows
        // zero cups and zero mg caffeine.
        let future = Date().addingTimeInterval(25.0 * 60.0 * 60.0)
        let template = createTemplate(forComplication: complication, date: future)
        handler(template)
    }
    
    //    We don't need to implement this method because our privacy behavior is hideOnLockScreen.
    //    Always-On Time automatically hides complications that would be hidden when the device is locked.
    //    func getAlwaysOnTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
    //
    //    }
    // MARK: - Private Methods
    
    // Return a timeline entry for the specified complication and date.
    private func createTimelineEntry(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry {
        
        // Get the correct template based on the complication.
        let template = createTemplate(forComplication: complication, date: date)
        
        // Use the template and date to create a timeline entry.
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
    
    // Select the correct template based on the complication's family.
    private func createTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate(forDate: date)
        case .modularLarge:
            return createModularLargeTemplate(forDate: date)
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createUtilitarianSmallFlatTemplate(forDate: date)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(forDate: date)
        case .circularSmall:
            return createCircularSmallTemplate(forDate: date)
        case .extraLarge:
            return createExtraLargeTemplate(forDate: date)
        case .graphicCorner:
            return createGraphicCornerTemplate(forDate: date)
        case .graphicCircular:
            return createGraphicCircleTemplate(forDate: date)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(forDate: date)
        case .graphicBezel:
            return createGraphicBezelTemplate(forDate: date)
        case .graphicExtraLarge:
            if #available(watchOSApplicationExtension 7.0, *) {
                return createGraphicExtraLargeTemplate(forDate: date)
            } else {
                fatalError("Graphic Extra Large template is only available on watchOS 7.")
            }
        @unknown default:
            fatalError("*** Unknown Complication Family ***")
        }
    }
    
    // Return a modular small template.
    private func createModularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        
        // Create the template using the providers.
        let template = CLKComplicationTemplateModularSmallStackText()
        template.line1TextProvider = mgCaffeineProvider
        template.line2TextProvider = mgUnitProvider
        return template
    }
    
    // Return a modular large template.
    private func createModularLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let titleTextProvider = CLKSimpleTextProvider(text: "Coffee Tracker", shortText: "Coffee")

        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
               
        let numberOfCupsProvider = CLKSimpleTextProvider(text: data.totalCupsTodayString)
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        let combinedCupsProvider = CLKTextProvider(format: "%@ %@", numberOfCupsProvider, cupsUnitProvider)
        
        // Create the template using the providers.
        let imageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeModularLarge"))
        let template = CLKComplicationTemplateModularLargeStandardBody()
        template.headerImageProvider = imageProvider
        template.headerTextProvider = titleTextProvider
        template.body1TextProvider = combinedCupsProvider
        template.body2TextProvider = combinedMGProvider
        return template
    }
    
    // Return a utilitarian small flat template.
    private func createUtilitarianSmallFlatTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeSmallFlat"))
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
        
        // Create the template using the providers.
        let template = CLKComplicationTemplateUtilitarianSmallFlat()
        template.imageProvider = flatUtilitarianImageProvider
        template.textProvider = combinedMGProvider
        return template
    }
    
    // Return a utilitarian large template.
    private func createUtilitarianLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeSmallFlat"))
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
        
        // Create the template using the providers.
        let template = CLKComplicationTemplateUtilitarianLargeFlat()
        template.imageProvider = flatUtilitarianImageProvider
        template.textProvider = combinedMGProvider
        return template
    }
    
    // Return a circular small template.
    private func createCircularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        
        // Create the template using the providers.
        let template = CLKComplicationTemplateCircularSmallStackText()
        template.line1TextProvider = mgCaffeineProvider
        template.line2TextProvider = mgUnitProvider
        return template
    }
    
    // Return an extra large template.
    private func createExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg")
        
        // Create the template using the providers.
        let template = CLKComplicationTemplateExtraLargeStackText()
        template.line1TextProvider = mgCaffeineProvider
        template.line2TextProvider = mgUnitProvider
        return template
    }
    
    // Return a graphic template that fills the corner of the watch face.
    private func createGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let leadingValueProvider = CLKSimpleTextProvider(text: "0")
        leadingValueProvider.tintColor = data.color(forCaffeineDose: 0.0)
        
        let trailingValueProvider = CLKSimpleTextProvider(text: "500")
        trailingValueProvider.tintColor = data.color(forCaffeineDose: 500.0)
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        mgUnitProvider.tintColor = data.color(forCaffeineDose: data.mgCaffeine(atDate: date))
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
        
        let percentage = Float(min(data.mgCaffeine(atDate: date) / 500.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        // Create the template using the providers.
        let template = CLKComplicationTemplateGraphicCornerGaugeText()
        template.leadingTextProvider = leadingValueProvider
        template.trailingTextProvider = trailingValueProvider
        template.outerTextProvider = combinedMGProvider
        template.gaugeProvider = gaugeProvider
        return template
    }
    
    // Return a graphic circle template.
    private func createGraphicCircleTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let percentage = Float(min(data.mgCaffeine(atDate: date) / 500.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        mgUnitProvider.tintColor = data.color(forCaffeineDose: data.mgCaffeine(atDate: date))
        
        // Create the template using the providers.
        let template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
        template.gaugeProvider = gaugeProvider
        template.centerTextProvider = mgCaffeineProvider
        template.bottomTextProvider = CLKSimpleTextProvider(text: "mg")
        return template
    }
    
    // Return a large rectangular graphic template.
    private func createGraphicRectangularTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let imageProvider = CLKFullColorImageProvider(fullColorImage: #imageLiteral(resourceName: "CoffeeGraphicRectangular"))
        let titleTextProvider = CLKSimpleTextProvider(text: "Coffee Tracker", shortText: "Coffee")
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        mgUnitProvider.tintColor = data.color(forCaffeineDose: data.mgCaffeine(atDate: date))
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
        
        let percentage = Float(min(data.mgCaffeine(atDate: date) / 500.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        // Create the template using the providers.
        let template = CLKComplicationTemplateGraphicRectangularTextGauge()
        template.headerImageProvider = imageProvider
        template.headerTextProvider = titleTextProvider
        template.body1TextProvider = combinedMGProvider
        template.gaugeProvider = gaugeProvider
        return template
    }
    
    // Return a circular template with text that wraps around the top of the watch's bezel.
    private func createGraphicBezelTemplate(forDate date: Date) -> CLKComplicationTemplate {
        
        // Create a graphic circular template with an image provider.
        let circle = CLKComplicationTemplateGraphicCircularImage()
        circle.imageProvider = CLKFullColorImageProvider(fullColorImage: #imageLiteral(resourceName: "CoffeeGraphicCircular"))
        
        // Create the text provider.
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        mgUnitProvider.tintColor = data.color(forCaffeineDose: data.mgCaffeine(atDate: date))
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
               
        let numberOfCupsProvider = CLKSimpleTextProvider(text: data.totalCupsTodayString)
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        cupsUnitProvider.tintColor = data.color(forTotalCups: data.totalCupsToday)
        let combinedCupsProvider = CLKTextProvider(format: "%@ %@", numberOfCupsProvider, cupsUnitProvider)
        
        let separator = NSLocalizedString(",", comment: "Separator for compound data strings.")
        let textProvider = CLKTextProvider(format: "%@%@ %@",
                                           combinedMGProvider,
                                           separator,
                                           combinedCupsProvider)
        
        // Create the bezel template using the circle template and the text provider.
        let template = CLKComplicationTemplateGraphicBezelCircularText()
        template.textProvider = textProvider
        template.circularTemplate = circle
        return template
    }
    
    // Returns an extra large graphic template
    @available(watchOSApplicationExtension 7.0, *)
    private func createGraphicExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        
        // Create the data providers.
        let percentage = Float(min(data.mgCaffeine(atDate: date) / 500.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        
        return CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText(
            gaugeProvider: gaugeProvider,
            bottomTextProvider: CLKSimpleTextProvider(text: "mg"),
            center: mgCaffeineProvider)
    }
}
