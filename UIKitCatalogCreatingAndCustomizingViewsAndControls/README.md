# UIKit Catalog: Creating and Customizing Views and Controls

Customize your app's user interface with views and controls in UIKit.

## Overview

This sample guides you through several types of customizations that you can make in your iOS app. The sample uses a split view controller architecture for navigating UIKit views and controls. The primary view controller (`MasterViewController`) shows the available views and controls. Selecting one shows the secondary view controller associated with it.

The name of each secondary view controller reflects its *target item*. For example, the `AlertControllerViewController` class shows how to use a `UIAlertController` object. The only exceptions to this rule are `UISearchBar` and `UIToolbar`; the sample demonstrates these APIs in multiple view controllers to explain how their controls function and how to customize them. To demonstrate how to manage the complexity of your storyboards, the app hosts all view controllers in a separate storyboard and loaded when needed.

This sample demonstrates the following views and controls (several of which are referenced in the sections below):

* [`UIActivityIndicatorView`](https://developer.apple.com/documentation/uikit/uiactivityindicatorview)
* [`UIAlertController`](https://developer.apple.com/documentation/uikit/uialertcontroller)
* [`UIButton`](https://developer.apple.com/documentation/uikit/uibutton)
* [`UIDatePicker`](https://developer.apple.com/documentation/uikit/uidatepicker)
* [`UIPickerView`](https://developer.apple.com/documentation/uikit/uipickerview)
* [`UIColorPickerViewController`](https://developer.apple.com/documentation/uikit/uicolorpickerviewcontroller)
* [`UIFontPickerViewController`](https://developer.apple.com/documentation/uikit/uifontpickerviewcontroller)
* [`UIImagePickerViewController`](https://developer.apple.com/documentation/uikit/uiimagepickercontroller)
* [`UIImageView`](https://developer.apple.com/documentation/uikit/uiimageview)
* [`UIPageControl`](https://developer.apple.com/documentation/uikit/uipagecontrol)
* [`UIProgressView`](https://developer.apple.com/documentation/uikit/uiprogressview)
* [`UISearchBar`](https://developer.apple.com/documentation/uikit/uisearchbar)
* [`UISegmentedControl`](https://developer.apple.com/documentation/uikit/uisegmentedcontrol)
* [`UISlider`](https://developer.apple.com/documentation/uikit/uislider)
* [`UIStackView`](https://developer.apple.com/documentation/uikit/uistackview)
* [`UIStepper`](https://developer.apple.com/documentation/uikit/uistepper)
* [`UISwitch`](https://developer.apple.com/documentation/uikit/uiswitch)
* [`UITextField`](https://developer.apple.com/documentation/uikit/uitextfield)
* [`UITextView`](https://developer.apple.com/documentation/uikit/uitextview)
* [`UIToolbar`](https://developer.apple.com/documentation/uikit/uitoolbar)
* [`WKWebView`](https://developer.apple.com/documentation/webkit/wkwebview)

## Add Accessibility Support to Your Views

VoiceOver and other system accessibility technologies use the information provided by your views and controls to help all users navigate your content. UIKit views include default accessibility support, but you can improve the user experience by providing custom accessibility information.

In this UIKitCatalog sample, several view controllers configure the `accessibilityType` and `accessibilityLabel` properties of their associated view. Picker view columns don't have labels, so the picker view asks its delegate for the corresponding accessibility information:

``` swift
func pickerView(_ pickerView: UIPickerView, accessibilityLabelForComponent component: Int) -> String? {
    
    switch ColorComponent(rawValue: component)! {
    case .red:
        return NSLocalizedString("Red color component value", comment: "")

    case .green:
        return NSLocalizedString("Green color component value", comment: "")

    case .blue:
        return NSLocalizedString("Blue color component value", comment: "")
    }
}
```

## Display a Custom Alert

`AlertControllerViewController` demonstrates several techniques for displaying modal alerts and action sheets from your interface. The configuration process is similar for all alerts:

1. Determine the message you want to display in the alert.
2. Create and configure a `UIAlertController` object.
3. Add handlers for actions that the user may take.
4. Present the alert controller.

The `showSimpleAlert` function uses the `NSLocalizedString` function to retrieve the alert messages in the user’s preferred language. The `showSimpleAlert` function uses those strings to create and configure the `UIAlertController` object. Although the button in the alert has the title OK, the sample uses a cancel action to ensure that the alert controller applies the proper styling to the button:

``` swift
func showSimpleAlert() {
    let title = NSLocalizedString("A Short Title is Best", comment: "")
    let message = NSLocalizedString("A message should be a short, complete sentence.", comment: "")
    let cancelButtonTitle = NSLocalizedString("OK", comment: "")

    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

    // Create the action.
    let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in
        print("The simple alert's cancel action occurred.")
    }

    // Add the action.
    alertController.addAction(cancelAction)

    present(alertController, animated: true, completion: nil)
}
```

## Customize the Appearance of Sliders

This sample demonstrates different ways to display a `UISlider`, a control used to select a single value from a continuous range of values. You customize the appearance of a slider by assigning stretchable images for left-side tracking, right-side tracking, and the thumb. In this example, the track image is stretchable and is one pixel wide. Make the track images wider to provide rounded corners, but be sure to set these images' `capInsets` property to allow for the corners.

The `configureCustomSlider` function sets up a custom slider:

``` swift
func configureCustomSlider() {
    let leftTrackImage = UIImage(named: "slider_blue_track")
    customSlider.setMinimumTrackImage(leftTrackImage, for: .normal)

    let rightTrackImage = UIImage(named: "slider_green_track")
    customSlider.setMaximumTrackImage(rightTrackImage, for: .normal)

    // Set the sliding thumb image (normal and highlighted).
    let thumbImageConfig = UIImage.SymbolConfiguration(scale: .large)
    let thumbImage = UIImage(systemName: "circle.fill", withConfiguration: thumbImageConfig)
    customSlider.setThumbImage(thumbImage, for: .normal)
    let thumbImageHighlighted = UIImage(systemName: "circle", withConfiguration: thumbImageConfig)
    customSlider.setThumbImage(thumbImageHighlighted, for: .highlighted)

    customSlider.minimumValue = 0
    customSlider.maximumValue = 100
    customSlider.isContinuous = false
    customSlider.value = 84

    customSlider.addTarget(self, action: #selector(SliderViewController.sliderValueDidChange(_:)), for: .valueChanged)
}
```

## Add a Search Bar to Your Interface

Use a `UISearchBar` for receiving search-related information from the user. There are various ways to customize the look of the search bar:

* Add a cancel button.
* Add a bookmark button.
* Set the bookmark image, both normal and highlighted states.
* Change the tint color that applies to key elements in the search bar.
* Set the search bar's background image.

The `configureSearchBar` function sets up a custom search bar:

``` swift
func configureSearchBar() {
    searchBar.showsCancelButton = true
    searchBar.showsBookmarkButton = true

    searchBar.tintColor = UIColor.systemPurple

    searchBar.backgroundImage = UIImage(named: "search_bar_background")

    // Set the bookmark image for both normal and highlighted states.
    let bookImage = UIImage(systemName: "bookmark")
    searchBar.setImage(bookImage, for: .bookmark, state: .normal)

    let bookFillImage = UIImage(systemName: "bookmark.fill")
    searchBar.setImage(bookFillImage, for: .bookmark, state: .highlighted)
}
```

## Customize the Appearance of Toolbars

This sample shows how to customize a `UIToolbar`, a specialized view that displays one or more buttons along the bottom edge of your interface. Customize a toolbar by determining its bar style (black or default), translucency, tint color, and background color.

The following `viewDidLoad` function in `CustomToolbarViewController` sets up a tinted tool bar:

``` swift
override func viewDidLoad() {
    super.viewDidLoad()

    // See the `UIBarStyle` enum for more styles, including `.Default`.
    toolbar.barStyle = .black
    toolbar.isTranslucent = false

    toolbar.tintColor = UIColor.systemGreen
    toolbar.backgroundColor = UIColor.systemBlue

    let toolbarButtonItems = [
        refreshBarButtonItem,
        flexibleSpaceBarButtonItem,
        actionBarButtonItem
    ]
    toolbar.setItems(toolbarButtonItems, animated: true)
}
```

`CustomToolbarViewController` demonstrates further customization by changing the toolbar's background image:

``` swift
override func viewDidLoad() {
    super.viewDidLoad()

    let toolbarBackgroundImage = UIImage(named: "toolbar_background")
    toolbar.setBackgroundImage(toolbarBackgroundImage, forToolbarPosition: .bottom, barMetrics: .default)

    let toolbarButtonItems = [
        customImageBarButtonItem,
        flexibleSpaceBarButtonItem,
        customBarButtonItem
    ]
    toolbar.setItems(toolbarButtonItems, animated: true)
}
```

## Add a Page Control Interface

Use a `UIPageControl` to structure your app's user interface. A page control is a specialized control that displays a horizontal series of dots, each of which corresponds to a page in the app’s document or other data-model entity. You customize a page control by setting its tint color for all the page indicator dots, and for the current page indicator dot.

The `configurePageControl` function sets up a customized page control:

``` swift
func configurePageControl() {
    // The total number of available pages is based on the number of available colors.
    pageControl.numberOfPages = colors.count
    pageControl.currentPage = 2

    pageControl.pageIndicatorTintColor = UIColor.systemGreen
    pageControl.currentPageIndicatorTintColor = UIColor.systemPurple
    
    pageControl.addTarget(self, action: #selector(PageControlViewController.pageControlValueDidChange), for: .valueChanged)
}
```

## Add Menus to Your Controls

You can attach menus to controls like `UIButton` and `UIBarButtonItem`. Create menus with the [`UIAction`](https://developer.apple.com/documentation/uikit/uiaction) class, and attach a menu to each control by setting the [`UIMenu`](https://developer.apple.com/documentation/uikit/uimenu) property.

Attach a menu to a `UIButton` as shown here:

``` swift
func configureMenuButton() {
    let buttonTitle = NSLocalizedString("Button", comment: "")
    menuButton.setTitle(buttonTitle, for: .normal)

    let items = (1...5).map {
        UIAction(title: String(format: NSLocalizedString("ItemTitle", comment: ""), $0.description), handler: menuHandler)
    }
    menuButton.menu = UIMenu(title: NSLocalizedString("ChooseItemTitle", comment: ""), children: items)
    menuButton.showsMenuAsPrimaryAction = true
}
```

Create a `UIBarButtonItem` with a menu attached as shown here:

``` swift
var customTitleBarButtonItem: UIBarButtonItem {
    let buttonMenu = UIMenu(title: "",
                            children: (1...5).map {
                               UIAction(title: "Option \($0)", handler: menuHandler)
                            })
    return UIBarButtonItem(image: UIImage(systemName: "list.number"), menu: buttonMenu)
}
```


