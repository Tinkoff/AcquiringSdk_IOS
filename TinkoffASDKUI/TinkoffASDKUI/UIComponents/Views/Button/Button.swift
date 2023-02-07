//
//  Button.swift
//  ASDK
//
//  Created by Ivan Glushko on 15.11.2022.
//

import UIKit

final class Button: UIView {

    static var defaultHeight: CGFloat { 56 }
    override var intrinsicContentSize: CGSize { button.intrinsicContentSize }

    private let button = UIButton()

    // MARK: - State

    var isEnabled: Bool {
        get { button.isEnabled }
        set { button.isEnabled = newValue }
    }

    private(set) var configuration: Configuration?

    private(set) var activityIndicatorState: State = .normal {
        didSet { stateDidChange(state: activityIndicatorState) }
    }

    var state: UIControl.State { button.state }

    private var stateObservers: [NSKeyValueObservation] = []

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupObservers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: State Observing

    private func setupObservers() {
        let changeHandler: (UIButton, NSKeyValueObservedChange<Bool>) -> Void = { [weak self] button, _ in
            self?.setButtonBackground(controlState: button.state)
        }

        stateObservers = [
            button.observe(\.isHighlighted, changeHandler: changeHandler),
            button.observe(\.isEnabled, changeHandler: changeHandler),
        ]
    }

    // MARK: - Public

    func startLoading() {
        activityIndicatorState = .loading
    }

    func stopLoading() {
        activityIndicatorState = .normal
    }

    // MARK: - Private

    private func setupViews() {
        addSubview(button)
        button.makeEqualToSuperview()

        button.addTarget(
            self,
            action: #selector(didTapActionButton),
            for: .touchUpInside
        )
    }

    @objc private func didTapActionButton() {
        configuration?.data.onTapAction()
    }

    private func stateDidChange(state: State) {
        switch state {
        case .normal:
            hideActivityIndicator { [weak self] in
                guard let self = self else { return }
                if let configuration = self.configuration {
                    self.configure(configuration)
                }
            }

        case .loading:
            resetTitle()
            hideActivityIndicator()
            if let loaderStyle = configuration?.style.loaderStyle {
                showActivityIndicator(with: loaderStyle)
            }
        }
    }
}

extension Button {

    // MARK: - Configuration

    func configure(_ configuration: Configuration) {
        prepareForReuse()

        self.configuration = configuration
        configureButton(data: configuration.data)
        configureButton(style: configuration.style)
    }

    private func configureButton(data: Data) {
        if let text = data.text {
            switch text {
            case let .basic(normalText, higlightedText, disabledText):
                button.setTitle(normalText, for: .normal)
                button.setTitle(higlightedText ?? normalText, for: .highlighted)
                button.setTitle(disabledText ?? normalText, for: .disabled)
            }
        }
    }

    private func configureButton(style: Style) {
        button.contentEdgeInsets = style.contentEdgeInsets
        button.layer.cornerRadius = style.cornerRadius

        switch style.background {
        case .color:
            // backgroundColor
            setButtonBackground(controlState: button.state)

        case let .image(normal, highlighted, disabled):
            // setBackgroundImage
            button.setBackgroundImage(normal, for: .normal)
            button.setBackgroundImage(highlighted ?? normal, for: .highlighted)
            button.setBackgroundImage(disabled ?? normal, for: .disabled)
        }
        // titleColor
        let textStyleNormal = style.basicTextStyle?.normal
        button.setTitleColor(textStyleNormal, for: .normal)
        button.setTitleColor(
            style.basicTextStyle?.highlighted ?? textStyleNormal,
            for: .highlighted
        )

        button.setTitleColor(
            style.basicTextStyle?.disabled ?? textStyleNormal,
            for: .disabled
        )

        // text Font
        button.titleLabel?.font = style.basicTextStyle?.font ?? .systemFont(ofSize: 16)
    }

    private func setButtonBackground(controlState: UIControl.State) {
        guard let background = configuration?.style.background else {
            return
        }

        let animations: () -> Void = {
            switch background {
            case let .color(normal, highlighted, disabled):
                // backgroundColor
                switch controlState {
                case .disabled:
                    self.button.backgroundColor = disabled ?? normal
                case .highlighted:
                    self.button.backgroundColor = highlighted ?? normal
                default:
                    self.button.backgroundColor = normal
                }

            case .image:
                break
            }
        }

        UIView.animate(
            withDuration: 0.3,
            delay: .zero,
            options: .curveEaseInOut,
            animations: {
                animations()
            }
        )
    }

    private func resetTitle() {
        button.setTitle(nil, for: .normal)
        button.setTitle(nil, for: .highlighted)
        button.setTitle(nil, for: .disabled)
    }

    private func prepareForReuse() {
        configuration = nil
        // Data
        resetTitle()
        // Style
        button.backgroundColor = nil
        button.contentEdgeInsets = .zero
        // background image
        button.setBackgroundImage(nil, for: .normal)
        button.setBackgroundImage(nil, for: .highlighted)
        button.setBackgroundImage(nil, for: .disabled)
        // title color
        button.setTitleColor(nil, for: .normal)
        button.setTitleColor(nil, for: .highlighted)
        button.setTitleColor(nil, for: .disabled)
    }
}

// MARK: - Button + Indicator

private extension Button {

    func showActivityIndicator(with style: ActivityIndicatorView.Style) {
        let activityIndicatorView = ActivityIndicatorView(style: style)
        activityIndicatorView.transform = CGAffineTransform(scaleX: .zero, y: .zero)

        let container = ViewHolder(base: activityIndicatorView)

        addSubview(container)

        container.makeEqualToSuperview()
        UIView.animate(withDuration: .scaleDuration) {
            activityIndicatorView.transform = .identity
        }

        activityIndicatorView.startAnimation(animated: true)
    }

    /// Скрыть индикатор
    func hideActivityIndicator(completion: (() -> Void)?) {
        let container = subviews.compactMap { $0 as? ViewHolder<ActivityIndicatorView> }.first
        let indicatorView = container?.base
        UIView.animate(withDuration: .scaleDuration, animations: {
            indicatorView?.alpha = .zero
        }, completion: { _ in
            container?.removeFromSuperview()
            completion?()
        })
    }

    func hideActivityIndicator() {
        hideActivityIndicator(completion: nil)
    }
}

// MARK: - Button + Types

extension Button {

    struct Data {
        enum Text {
            case basic(
                normal: String?,
                highlighted: String?,
                disabled: String?
            )
        }

        let text: Text?
        let onTapAction: () -> Void
    }

    struct Configuration {
        let data: Data
        let style: Style

        static var empty: Self {
            Self(data: Button.Data(text: nil, onTapAction: {}), style: .destructive)
        }
    }

    enum State {
        case loading
        case normal
    }
}
