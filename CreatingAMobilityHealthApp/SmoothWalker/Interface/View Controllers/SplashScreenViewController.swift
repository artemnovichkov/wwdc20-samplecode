/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller with a simple message and action button.
*/

import UIKit

protocol SplashScreenViewControllerDelegate: class {
    func didSelectActionButton()
}

private extension CGFloat {
    static let inset: CGFloat = 20
    static let padding: CGFloat = 12
}

class SplashScreenViewController: UIViewController {
    
    lazy var containerView: UIView = {
        let view = UIView()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    lazy var actionButton: UIButton = {
        let button = UIButton()
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitleColor(.systemBlue, for: .normal)
        button.setTitleColor(UIColor.systemBlue.withAlphaComponent(0.5), for: .highlighted)
        button.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        
        return button
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        
        return label
    }()
    
    weak var splashScreenDelegate: SplashScreenViewControllerDelegate?
    
    // MARK: Initalizers
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
    }
    
    private func setUpViews() {
        view.addSubview(containerView)
        
        containerView.addSubview(actionButton)
        containerView.addSubview(descriptionLabel)
        
        setUpConstraints()
    }
    
    private func setUpConstraints() {
        var constraints: [NSLayoutConstraint] = []
        
        constraints += createContainerViewConstraints()
        constraints += createActionButtonConstraints()
        constraints += createDescriptionLabelConstraints()
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func createContainerViewConstraints() -> [NSLayoutConstraint] {
        let leading = containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: .inset)
        let trailing = containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -.inset)
        let centerY = containerView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        
        return [leading, trailing, centerY]
    }
    
    private func createActionButtonConstraints() -> [NSLayoutConstraint] {
        let top = actionButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: .padding)
        let centerX = actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        
        return [top, centerX]
    }
    
    private func createDescriptionLabelConstraints() -> [NSLayoutConstraint] {
        let top = descriptionLabel.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: .padding)
        let bottom = descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -.padding)
        let leading = descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .padding)
        let trailing = descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.padding)
        
        return [top, bottom, leading, trailing]
    }
    
    // MARK: - Selectors
    
    @objc
    private func didTapActionButton() {
        splashScreenDelegate?.didSelectActionButton()
    }
}
