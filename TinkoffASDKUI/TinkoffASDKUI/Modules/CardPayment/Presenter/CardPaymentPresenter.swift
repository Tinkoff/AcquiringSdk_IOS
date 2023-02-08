//
//  CardPaymentPresenter.swift
//  TinkoffASDKUI
//
//  Created by Aleksandr Pravosudov on 20.01.2023.
//

import Foundation
import TinkoffASDKCore

final class CardPaymentPresenter: ICardPaymentViewControllerOutput {

    // MARK: Dependencies

    weak var view: ICardPaymentViewControllerInput?
    private let router: ICardPaymentRouter
    private weak var output: ICardPaymentPresenterModuleOutput?

    private let moneyFormatter: IMoneyFormatter

    // MARK: Properties

    private var cellTypes = [CardPaymentCellType]()
    private var savedCardPresenter: SavedCardPresenter?
    private lazy var cardFieldPresenter = createCardFieldViewPresenter()
    private lazy var receiptSwitchViewPresenter = createReceiptSwitchViewPresenter()
    private lazy var emailPresenter = createEmailViewPresenter()

    private var isCardFieldValid = false

    private let activeCards: [PaymentCard]
    private let paymentFlow: PaymentFlow
    private let amount: Int
    private let customerEmail: String

    // MARK: Initialization

    init(
        router: ICardPaymentRouter,
        output: ICardPaymentPresenterModuleOutput?,
        moneyFormatter: IMoneyFormatter,
        activeCards: [PaymentCard],
        paymentFlow: PaymentFlow,
        amount: Int
    ) {
        self.router = router
        self.output = output
        self.moneyFormatter = moneyFormatter
        self.activeCards = Int.random(in: 0 ... 100) % 2 == 0 ? activeCards : []
        self.paymentFlow = paymentFlow
        self.amount = amount

        customerEmail = Int.random(in: 0 ... 100) % 2 == 0 ? paymentFlow.customerOptions?.email ?? "" : ""
    }
}

// MARK: - ICardPaymentViewControllerOutput

extension CardPaymentPresenter {
    func viewDidLoad() {
        createSavedCardViewPresenterIfNeeded()

        viewSetupPayButton()
        setupCellTypes()
        view?.reloadTableView()
    }

    func closeButtonPressed() {
        router.closeScreen()
    }

    func payButtonPressed() {
        view?.hideKeyboard()
        view?.startLoadingPayButton()

        output?.cardPaymentPayButtonDidPressed(cardData: cardFieldPresenter.cardData, email: emailPresenter.currentEmail)
    }

    func numberOfRows() -> Int {
        cellTypes.count
    }

    func cellType(for row: Int) -> CardPaymentCellType {
        cellTypes[row]
    }
}

// MARK: - ICardFieldOutput

extension CardPaymentPresenter: ICardFieldOutput {
    func cardFieldValidationResultDidChange(result: CardFieldValidationResult) {
        isCardFieldValid = result.isValid
        activatePayButtonIfNeeded()
    }
}

// MARK: - IEmailViewPresenterOutput

extension CardPaymentPresenter: IEmailViewPresenterOutput {
    func emailTextFieldDidBeginEditing(_ presenter: EmailViewPresenter) {
        cardFieldPresenter.validateWholeForm()
    }

    func emailTextField(_ presenter: EmailViewPresenter, didChangeEmail email: String, isValid: Bool) {
        activatePayButtonIfNeeded()
    }

    func emailTextFieldDidPressReturn(_ presenter: EmailViewPresenter) {
        cardFieldPresenter.validateWholeForm()
    }
}

// MARK: - ISavedCardPresenterOutput

extension CardPaymentPresenter: ISavedCardPresenterOutput {
    func savedCardPresenter(_ presenter: SavedCardPresenter, didRequestReplacementFor paymentCard: PaymentCard) {
        // логика открытия экрана со спиком карт
    }

    func savedCardPresenter(_ presenter: SavedCardPresenter, didUpdateCVC cvc: String, isValid: Bool) {
        activatePayButtonIfNeeded()
    }
}

// MARK: - Private

extension CardPaymentPresenter {
    private func createSavedCardViewPresenterIfNeeded() {
        guard let activeCard = activeCards.first else { return }

        let hasAnotherCards = activeCards.count > 1
        savedCardPresenter = SavedCardPresenter(output: self)
        savedCardPresenter?.presentationState = .selected(card: activeCard, hasAnotherCards: hasAnotherCards)
    }

    private func createCardFieldViewPresenter() -> CardFieldPresenter {
        CardFieldPresenter(output: self)
    }

    private func createReceiptSwitchViewPresenter() -> SwitchViewPresenter {
        SwitchViewPresenter(title: Loc.Acquiring.EmailField.switchButton, isOn: !customerEmail.isEmpty, actionBlock: { [weak self] isOn in
            guard let self = self else { return }

            if isOn {
                let getReceiptIndex = self.cellTypes.firstIndex(of: .getReceipt(self.receiptSwitchViewPresenter)) ?? 0
                let emailIndex = getReceiptIndex + 1
                self.cellTypes.insert(.emailField(self.emailPresenter), at: emailIndex)
                self.view?.insert(row: emailIndex)
            } else if let emailIndex = self.cellTypes.firstIndex(of: .emailField(self.emailPresenter)) {
                self.cellTypes.remove(at: emailIndex)
                self.view?.delete(row: emailIndex)
            }

            self.activatePayButtonIfNeeded()
            self.view?.hideKeyboard()
            self.cardFieldPresenter.validateWholeForm()
        })
    }

    private func createEmailViewPresenter() -> EmailViewPresenter {
        EmailViewPresenter(customerEmail: customerEmail, output: self)
    }

    private func viewSetupPayButton() {
        let stringAmount = moneyFormatter.formatAmount(amount)
        view?.setPayButton(title: "\(Loc.Acquiring.PaymentNewCard.paymentButton) \(stringAmount)")
        view?.setPayButton(isEnabled: false)
    }

    private func setupCellTypes() {
        activeCards.isEmpty ? cellTypes.append(.cardField(cardFieldPresenter)) : cellTypes.append(.savedCard(savedCardPresenter))

        if customerEmail.isEmpty {
            cellTypes.append(.getReceipt(receiptSwitchViewPresenter))
        } else {
            cellTypes.append(.getReceipt(receiptSwitchViewPresenter))
            cellTypes.append(.emailField(emailPresenter))
        }

        cellTypes.append(.payButton)
    }

    private func activatePayButtonIfNeeded() {
        let isSavedCardValid = savedCardPresenter?.isValid ?? false
        let isSavedCardExist = !activeCards.isEmpty
        let isCardValid = isSavedCardExist ? isSavedCardValid : isCardFieldValid

        let isEmailFieldOn = receiptSwitchViewPresenter.isOn
        let isEmailFieldValid = emailPresenter.isEmailValid
        let isEmailValid = isEmailFieldOn ? isEmailFieldValid : true

        let isPayButtonEnabled = isCardValid && isEmailValid
        view?.setPayButton(isEnabled: isPayButtonEnabled)
    }
}
