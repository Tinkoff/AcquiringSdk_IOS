//
//  AddNewCardPresenter.swift
//  TinkoffASDKUI
//
//  Created by Ivan Glushko on 20.12.2022.
//

import Foundation
import enum TinkoffASDKCore.APIError

protocol IAddNewCardPresenter: AnyObject {
    func viewDidLoad()
    func viewDidAppear()
    func cardFieldViewAddCardTapped()
    func viewWasClosed()
    func cardFieldViewPresenter() -> ICardFieldViewOutput
}

final class AddNewCardPresenter {
    // MARK: Dependencies

    weak var view: IAddNewCardView?
    private let cardsController: ICardsController

    // MARK: Output

    private weak var output: IAddNewCardOutput?

    // MARK: Child presenters

    private lazy var cardFieldPresenter = CardFieldPresenter(output: self)

    // MARK: State

    private var moduleResult: AddCardResult = .cancelled

    // MARK: Init

    init(cardsController: ICardsController, output: IAddNewCardOutput?) {
        self.cardsController = cardsController
        self.output = output
    }
}

// MARK: - IAddNewCardPresenter

extension AddNewCardPresenter: IAddNewCardPresenter {
    func cardFieldViewAddCardTapped() {
        guard cardFieldPresenter.validateWholeForm().isValid else { return }

        let cardOptions = CardOptions(
            pan: cardFieldPresenter.cardNumber,
            validThru: cardFieldPresenter.expiration,
            cvc: cardFieldPresenter.cvc
        )

        addCard(options: cardOptions)
    }

    func viewDidLoad() {
        view?.reloadCollection(sections: [.cardField])
        view?.disableAddButton()
    }

    func viewDidAppear() {
        view?.activateCardField()
    }

    func viewWasClosed() {
        output?.addingNewCardCompleted(result: moduleResult)
    }

    func cardFieldViewPresenter() -> ICardFieldViewOutput {
        cardFieldPresenter
    }
}

extension AddNewCardPresenter: ICardFieldOutput {
    func cardFieldValidationResultDidChange(result: CardFieldValidationResult) {
        result.isValid ? view?.enableAddButton() : view?.disableAddButton()
    }
}

// MARK: - Private

extension AddNewCardPresenter {
    private func addCard(options: CardOptions) {
        view?.showLoadingState()

        cardsController.addCard(options: options) { [weak self] result in
            guard let self = self else { return }
            self.view?.hideLoadingState()
            self.moduleResult = result

            switch result {
            case .succeded:
                self.view?.closeScreen()
            case let .failed(error) where (error as NSError).code == 510:
                self.view?.showOkNativeAlert(data: .alreadyHasSuchCardError)
            case .failed:
                self.view?.showOkNativeAlert(data: .genericError)
            case .cancelled:
                self.view?.closeScreen()
            }
        }
    }
}

// MARK: - OkAlertData + Helpers

private extension OkAlertData {
    static var alreadyHasSuchCardError: Self {
        OkAlertData(
            title: Loc.CommonAlert.AddCard.title,
            buttonTitle: Loc.CommonAlert.button
        )
    }

    static var genericError: Self {
        OkAlertData(
            title: Loc.CommonAlert.SomeProblem.title,
            message: Loc.CommonAlert.SomeProblem.description,
            buttonTitle: Loc.CommonAlert.button
        )
    }
}
