/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Detail View Controller.
*/
import UIKit
import SwiftUI

final class RBDetailViewController: UIViewController {
    
    private var viewModel: RBViewModel

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private let shareButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "square.and.arrow.up.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20))
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = NSLocalizedString("Share", comment: "")
        return button
    }()

    private let favoriteButton: UIButton = {
        let button = UIButton()
        button.tintColor = .systemRed
        return button
    }()

    init(viewModel: RBViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "\(viewModel.coffee.brand), \(viewModel.coffee.caption)"

        view.backgroundColor = .systemBackground
        
        /*
         The view is a functional section, which holds information related to the selected
         coffee. Thus, we can make it an accessibilityContainer so VoiceOver on macOS can
         more easily navigate to and from this section.
        */
        view.accessibilityLabel = String(format: NSLocalizedString("%@ Details", comment: ""), viewModel.coffee.brand)
        view.accessibilityContainerType = .semanticGroup

        setupScrollableStackView()
        setupCustomNavigationBar()
        setupImage()
        setupTastingNotes()
        setupRoast()
        setupAvailabilityList()
        setupActions()
        setupImageGrid()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    @objc
    private func toggleFavorite() {
        viewModel.isFavorite.toggle()
        updateFavoriteButton()
    }

    private func updateFavoriteButton() {
        favoriteButton.focusGroupIdentifier = "com.example.apple-samplecode.RoastedBeans.detailsviewfocusgroup1"
        if viewModel.isFavorite {
            favoriteButton.setImage(
                UIImage(systemName: "suit.heart.fill")?.withConfiguration(UIImage.SymbolConfiguration(scale: .large)),
                for: .normal)
            favoriteButton.accessibilityLabel = NSLocalizedString("Remove from favorites", comment: "")
        } else {
            favoriteButton.setImage(
                UIImage(systemName: "heart")?.withConfiguration(UIImage.SymbolConfiguration(scale: .large)),
                for: .normal)
            favoriteButton.accessibilityLabel = NSLocalizedString("Add to favorites", comment: "")
        }
    }

    @objc
    private func share() {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let buyForYourself = UIAlertAction(title: NSLocalizedString("Buy one for yourself", comment: ""), style: .default, handler: nil)
        let buyForFriend = UIAlertAction(title: NSLocalizedString("Buy one for friend", comment: ""), style: .default, handler: nil)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        controller.addAction(buyForYourself)
        controller.addAction(buyForFriend)
        controller.addAction(cancelAction)

        // On Catalyst, action sheets are presented as a popover
        controller.popoverPresentationController?.sourceView = shareButton
        present(controller, animated: true, completion: nil)
    }
}

extension RBDetailViewController {

    private func setupScrollableStackView() {
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func setupCustomNavigationBar() {
        let navigationBar = UIView()
        navigationBar.backgroundColor = .brown

        /*
         This is a "fake" navigation bar. Since UINavigationBar is an
         accessibilityContainer of type semantic group by default, we should
         mirror that here.
        */
        navigationBar.accessibilityContainerType = .semanticGroup

        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle).bold()
        titleLabel.text = viewModel.coffee.brand
        titleLabel.textColor = .white
        let subtitleLabel = UILabel()
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        subtitleLabel.text = viewModel.coffee.caption
        subtitleLabel.textColor = .white
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: navigationBar.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -16),
            stackView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor, constant: -16)
        ])
        navigationBar.heightAnchor.constraint(equalToConstant: 100).isActive = true

        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        shareButton.focusGroupIdentifier = "com.example.apple-samplecode.RoastedBeans.detailsviewfocusgroup"
        navigationBar.addSubview(shareButton)
        NSLayoutConstraint.activate([
            shareButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            shareButton.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor, constant: -16),
            shareButton.heightAnchor.constraint(equalToConstant: 60),
            shareButton.widthAnchor.constraint(equalToConstant: 60)
        ])

        self.stackView.addArrangedSubview(navigationBar)
    }

    private func setupImage() {
        let imageView = UIImageView(image: viewModel.coffee.image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        let priceBadge = UIView()
        priceBadge.backgroundColor = .systemRed
        priceBadge.layer.cornerRadius = 25
        priceBadge.translatesAutoresizingMaskIntoConstraints = false
        let priceLabel = UILabel()
        priceLabel.textAlignment = .center
        priceLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        priceLabel.textColor = .white
        priceLabel.text = viewModel.coffee.price
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceBadge.addSubview(priceLabel)
        NSLayoutConstraint.activate([
            priceLabel.topAnchor.constraint(equalTo: priceBadge.topAnchor),
            priceLabel.bottomAnchor.constraint(equalTo: priceBadge.bottomAnchor),
            priceLabel.leadingAnchor.constraint(equalTo: priceBadge.leadingAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: priceBadge.trailingAnchor)
        ])

        imageView.addSubview(priceBadge)
        NSLayoutConstraint.activate([
            priceBadge.centerXAnchor.constraint(equalTo: imageView.centerXAnchor, constant: 50),
            priceBadge.centerYAnchor.constraint(equalTo: imageView.centerYAnchor, constant: -50),
            priceBadge.heightAnchor.constraint(equalToConstant: 50),
            priceBadge.widthAnchor.constraint(equalToConstant: 50)
        ])

        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = String(format: NSLocalizedString("Price: %@", comment: ""), viewModel.coffee.price)
        stackView.addArrangedSubview(imageView)
    }

    private func setupTastingNotes() {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title3).italic()
        label.text = viewModel.coffee.tags
        label.textAlignment = .center
        stackView.addArrangedSubview(label)
    }

    private func setupRoast() {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title3).bold()
        label.text = String(format: NSLocalizedString("%@ Roast", comment: ""), viewModel.coffee.roast.rawValue.capitalized)
        label.textAlignment = .center
        stackView.addArrangedSubview(label)
    }

    private func setupAvailabilityList() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let locationsAvailable = viewModel.locationsAvailable

        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body).bold()
        titleLabel.text = NSLocalizedString("Availability: ", comment: "")
        stackView.addArrangedSubview(titleLabel)

        for location in locationsAvailable {
            let label = UILabel()
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.text = "• " + location
            label.accessibilityLabel = location
            stackView.addArrangedSubview(label)
        }

        /*
         The view contains related elements. Thus, we can make it an
         accessibilityContainer so VoiceOver on macOS can navigate past the entire
         list of locations, rather than having to navigate through each one.
        */
        stackView.accessibilityLabel = String(format: NSLocalizedString("Available at %@ locations", comment: ""), String(locationsAvailable.count))
        stackView.accessibilityContainerType = .semanticGroup

        let descriptionView = UIView()
        let descriptionContentView = UIView()
        descriptionContentView.backgroundColor = .secondarySystemBackground
        descriptionContentView.layer.cornerCurve = .continuous
        descriptionContentView.layer.cornerRadius = 10
        descriptionContentView.translatesAutoresizingMaskIntoConstraints = false
        descriptionContentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: descriptionContentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: descriptionContentView.bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: descriptionContentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: descriptionContentView.trailingAnchor, constant: -8)
        ])

        descriptionView.addSubview(descriptionContentView)
        NSLayoutConstraint.activate([
            descriptionContentView.topAnchor.constraint(equalTo: descriptionView.topAnchor, constant: 16),
            descriptionContentView.bottomAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: 0),
            descriptionContentView.leadingAnchor.constraint(equalTo: descriptionView.leadingAnchor, constant: 16),
            descriptionContentView.trailingAnchor.constraint(equalTo: descriptionView.trailingAnchor, constant: -16),
            descriptionContentView.heightAnchor.constraint(equalTo: stackView.heightAnchor, constant: 16)
        ])

        self.stackView.addArrangedSubview(descriptionView)
    }

    private func setupActions() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false

        updateFavoriteButton()
        favoriteButton.addTarget(self, action: #selector(toggleFavorite), for: .touchUpInside)
        stackView.addArrangedSubview(favoriteButton)

        let giftButton = UIButton()
        giftButton.setImage(
            UIImage(systemName: "gift.fill")?.withConfiguration(UIImage.SymbolConfiguration(scale: .large)),
            for: .normal)
        giftButton.tintColor = .brown
        giftButton.focusGroupIdentifier = "com.example.apple-samplecode.RoastedBeans.detailsviewfocusgroup2"
        giftButton.accessibilityLabel = NSLocalizedString("Gift", comment: "")
        stackView.addArrangedSubview(giftButton)

        let descriptionView = UIView()
        let descriptionContentView = UIView()
        descriptionContentView.backgroundColor = .secondarySystemBackground
        descriptionContentView.layer.cornerCurve = .continuous
        descriptionContentView.layer.cornerRadius = 10
        descriptionContentView.translatesAutoresizingMaskIntoConstraints = false
        descriptionContentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: descriptionContentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: descriptionContentView.bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: descriptionContentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: descriptionContentView.trailingAnchor, constant: -8)
        ])

        descriptionView.addSubview(descriptionContentView)
        NSLayoutConstraint.activate([
            descriptionContentView.topAnchor.constraint(equalTo: descriptionView.topAnchor, constant: 16),
            descriptionContentView.bottomAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: 0),
            descriptionContentView.leadingAnchor.constraint(equalTo: descriptionView.leadingAnchor, constant: 16),
            descriptionContentView.trailingAnchor.constraint(equalTo: descriptionView.trailingAnchor, constant: -16),
            descriptionContentView.heightAnchor.constraint(equalTo: stackView.heightAnchor, constant: 16)
        ])

        self.stackView.addArrangedSubview(descriptionView)
    }

    private func setupImageGrid() {
        let hostingView = UIHostingController(
                rootView: RBImageGrid(
                    title: NSLocalizedString("Images", comment: ""),
                    images: [#imageLiteral(resourceName: "coffee"), #imageLiteral(resourceName: "coffee"), #imageLiteral(resourceName: "coffee")]))
        addChild(hostingView)
        self.stackView.addArrangedSubview(hostingView.view)
        hostingView.didMove(toParent: self)
    }
}
