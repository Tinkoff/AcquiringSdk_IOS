//
//  CardListPresenterTests.swift
//  TinkoffASDKUI-Unit-Tests
//
//  Created by Ivan Glushko on 19.12.2022.
//

import Foundation

@testable import TinkoffASDKCore
@testable import TinkoffASDKUI

import Foundation
import XCTest

final class CardListPresenterTests: BaseTestCase {

    // Dependencies
    var sutAsProtocol: ICardListViewOutput! { sut }

    var sut: CardListPresenter!
    var paymentSystemImageResolverMock: PaymentSystemImageResolverMock!
    var bankResolverMock: BankResolverMock!
    var paymentSystemResolverMock: PaymentSystemResolverMock!
    var viewMock: MockCardListViewInput!
    var cardsControllerMock: CardsControllerMock!
    var router: CardListRouterMock!
    var output: CardListPresenterOutputMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        paymentSystemImageResolverMock = PaymentSystemImageResolverMock()
        bankResolverMock = BankResolverMock()
        paymentSystemResolverMock = PaymentSystemResolverMock()
        viewMock = MockCardListViewInput()
        cardsControllerMock = CardsControllerMock()
        router = CardListRouterMock()
        output = CardListPresenterOutputMock()
    }

    override func tearDown() {
        sut = nil
        paymentSystemImageResolverMock = nil
        bankResolverMock = nil
        paymentSystemResolverMock = nil
        viewMock = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_viewDidLoad() throws {
        allureId(2401647, "Инициализируем шиммер при инициализации экрана Списка Карт")
        allureId(2397505, "Отправляем запрос получения списка при инициализации SDK")

        // given
        prepareSut()

        // when
        sutAsProtocol.viewDidLoad()

        // then
        XCTAssertEqual(viewMock.showShimmerCallCounter, 1)
        XCTAssertEqual(cardsControllerMock.getActiveCardsCallsCount, 1)
        XCTAssertEqual(viewMock.hideShimmerCallCounter, 1)
    }

    func test_viewDidTapEditButton_when_showingCards() throws {
        allureId(2397530, "Переход в состояние редактирования списка карт")

        // given
        prepareSut()
        sutAsProtocol.viewDidHideShimmer(fetchCardsResult: .success(buildActiveCardsCache()))

        // when
        sutAsProtocol.viewDidTapEditButton()

        // then
        let addCardSection = viewMock.reloadCallArguments?.first(where: {
            if case CardListSection.addCard = $0 { return true }
            return false
        })

        XCTAssertEqual(viewMock.hideStubCallCounter, 2)
        XCTAssertEqual(viewMock.showDoneEditingButtonCallCounter, 2)
        XCTAssertEqual(viewMock.reloadCallCounter, 2)
        XCTAssertNil(addCardSection)
    }

    func test_viewDidTapEditButton_when_editingCards() throws {
        // given
        prepareSut()

        // when
        sutAsProtocol.viewDidTapEditButton()

        // then
        XCTAssertEqual(viewMock.hideStubCallCounter, 0)
        XCTAssertEqual(viewMock.showDoneEditingButtonCallCounter, 0)
        XCTAssertEqual(viewMock.reloadCallCounter, 0)
    }

    func test_viewDidTapDoneEditingButton() throws {
        // given
        prepareSut()

        // when
        sutAsProtocol.viewDidTapDoneEditingButton()

        // then
        XCTAssertEqual(viewMock.showEditButtonCallCounter, 2)
        XCTAssertEqual(viewMock.hideStubCallCounter, 1)
        XCTAssertEqual(viewMock.reloadCallCounter, 1)
    }

    func test_viewDidHideLoadingSnackbar_deactivateCard_success() throws {
        // given
        prepareSut()
        sutAsProtocol.view(didTapDeleteOn: buildCardListCard())

        // when
        sutAsProtocol.viewDidHideRemovingCardSnackBar()

        // then
        XCTAssertEqual(viewMock.enableViewUserInteractionCallCounter, 1)
        XCTAssertEqual(cardsControllerMock.getActiveCardsCallsCount, 0)
    }

    func test_viewUpdatesSelectedCard() throws {
        // given
        prepareSut()
        let fakeCard = PaymentCard.fake()
        let cardList = buildCardListCard()
        sutAsProtocol.view(didTapDeleteOn: cardList)
        cardsControllerMock.removeCardStub = { _, completion in
            completion(.success(.init(cardId: cardList.id, cardStatus: .active)))
        }
        sut.addNewCardDidReceive(result: .succeded(fakeCard))

        // when
        sutAsProtocol.viewDidHideRemovingCardSnackBar()

        // then
        let arg = try XCTUnwrap(viewMock.reloadCallArguments?.first)
        if case let .cards(data) = arg {
            XCTAssertEqual(data.first?.id, fakeCard.cardId)
        } else {
            XCTFail()
        }
    }

    func test_viewDidHideLoadingSnackbar_deactivateCard_failure() throws {
        allureId(2397534, "Инициализируем событие алерта при ошибке удаление")
        // given
        prepareSut()
        let cards = buildActiveCardsCache()
        cardsControllerMock.removeCardStub = { _, completion in
            completion(.failure(TestsError.basic))
        }
        sutAsProtocol.viewDidHideShimmer(fetchCardsResult: .success(cards))
        sutAsProtocol.view(didTapDeleteOn: buildCardListCard())
        viewMock.reloadCallCounter = .zero

        // when
        sutAsProtocol.viewDidHideRemovingCardSnackBar()

        // then
        XCTAssertEqual(viewMock.enableViewUserInteractionCallCounter, 2)
        XCTAssertEqual(viewMock.showNativeAlertCallCounter, 1)
        XCTAssertEqual(viewMock.reloadCallCounter, .zero)
    }

    func test_view_didTapDeleteOn_success() throws {
        // given
        prepareSut()
        let cardListCard = buildCardListCard()
        let expectation = expectation(description: #function)

        cardsControllerMock.removeCardStub = { _, completion in
            completion(.success(RemoveCardPayload(cardId: "2", cardStatus: .deleted)))
            expectation.fulfill()
        }

        // when
        sutAsProtocol.view(didTapDeleteOn: cardListCard)
        wait(for: [expectation], timeout: 1)

        // then
        XCTAssertEqual(viewMock.disableViewUserInteractionCallCounter, 1)
        XCTAssertEqual(viewMock.showRemovingCardSnackBarCallCounter, 1)
        XCTAssertEqual(cardsControllerMock.removeCardCallsCount, 1)
        XCTAssertEqual(viewMock.hideLoadingSnackbarCallCounter, 1)
    }

    func test_view_didTapDeleteOn_failure() throws {
        // given
        prepareSut()
        let cardListCard = buildCardListCard()
        let expectation = expectation(description: #function)

        cardsControllerMock.removeCardStub = { _, completion in
            completion(.failure(TestsError.basic))
            expectation.fulfill()
        }

        // when
        sutAsProtocol.view(didTapDeleteOn: cardListCard)
        wait(for: [expectation], timeout: 1)

        // then
        XCTAssertEqual(viewMock.disableViewUserInteractionCallCounter, 1)
        XCTAssertEqual(viewMock.showRemovingCardSnackBarCallCounter, 1)
        XCTAssertEqual(cardsControllerMock.removeCardCallsCount, 1)
        XCTAssertEqual(viewMock.hideLoadingSnackbarCallCounter, 1)
    }

    func test_viewDidHideShimmer_failure_shouldShow_serverErrorStub() throws {
        allureId(2397506, "Инициализируем заглушку в случае ошибки получения списка карт")

        // given
        var serverErrorModeStubShown = false

        prepareSut()
        viewMock.showStubStub = { mode in
            if case StubMode.serverError = mode {
                serverErrorModeStubShown = true
            }
        }

        // when
        sutAsProtocol.viewDidHideShimmer(fetchCardsResult: .failure(TestsError.basic))

        // then
        XCTAssertEqual(viewMock.showStubCallCounter, 1)
        XCTAssertEqual(viewMock.hideRightBarButtonCalCounter, 1)
        XCTAssertTrue(serverErrorModeStubShown, "should show no cards stub")
    }

    func test_viewDidHideShimmer_failure_shouldCloseScreen() {
        // given
        prepareSut()

        // when
        sutAsProtocol.viewDidHideShimmer(fetchCardsResult: .failure(TestsError.basic))
        if case let .serverError(action) = viewMock.showStubCallArguments {
            action()
        }

        // then
        XCTAssertEqual(viewMock.closeScreenCounter, 1)
    }

    func test_viewDidHideShimmer_network_failure_shouldHideShimmer() {
        // given
        prepareSut()

        // when
        sutAsProtocol.viewDidHideShimmer(
            fetchCardsResult: .failure(NSError(domain: "", code: NSURLErrorNotConnectedToInternet))
        )
        if case let .noNetwork(action) = viewMock.showStubCallArguments {
            action()
        }

        // then
        XCTAssertEqual(viewMock.hideShimmerCallCounter, 1)
    }

    func test_viewDidHideShimmer_network_failure_shouldShow_noNetworkStub() throws {
        allureId(2397506, "Инициализируем заглушку в случае ошибки получения списка карт")

        // given
        var noNetworkStubShown = false

        prepareSut()
        viewMock.showStubStub = { mode in
            if case StubMode.noNetwork = mode {
                noNetworkStubShown = true
            }
        }

        // when
        sutAsProtocol.viewDidHideShimmer(
            fetchCardsResult: .failure(NSError(domain: "", code: NSURLErrorNotConnectedToInternet))
        )

        // then
        XCTAssertEqual(viewMock.showStubCallCounter, 1)
        XCTAssertEqual(viewMock.hideRightBarButtonCalCounter, 1)
        XCTAssertTrue(noNetworkStubShown, "should show no cards stub")
    }

    func test_viewDidHideShimmer_success_emptyCards_shouldShowNoCardsStub() throws {
        allureId(2397506, "Инициализируем заглушку в случае ошибки получения списка карт")
        allureId(2397501, "Инициализируем заглушку в случае получения пустого списка карт")

        // given
        var isNoCardsMode = false

        prepareSut()
        viewMock.showStubStub = { mode in
            if case StubMode.noCardsInCardList = mode {
                isNoCardsMode = true
            }
        }

        // when
        sutAsProtocol.viewDidHideShimmer(fetchCardsResult: .success([]))

        // then
        XCTAssertEqual(viewMock.reloadCallCounter, 2)
        XCTAssertEqual(viewMock.hideStubCallCounter, 2)
        XCTAssertEqual(viewMock.showStubCallCounter, 1)
        XCTAssertEqual(viewMock.hideRightBarButtonCalCounter, 1)
        XCTAssertTrue(isNoCardsMode, "should show no cards stub")
    }

    func test_viewDidHideShimmer_success_shouldShowCards() throws {
        allureId(2397526, "Меняем состояние экрана карт на отображение полученного списка карт")
        allureId(2397528, "Определение ПС и банка-эмитента перед отображением карт")

        // given
        prepareSut()

        // when
        sutAsProtocol.viewDidHideShimmer(fetchCardsResult: .success(buildActiveCardsCache()))

        // then
        XCTAssertEqual(viewMock.reloadCallCounter, 1)
        XCTAssertEqual(viewMock.hideStubCallCounter, 1)
        XCTAssertEqual(viewMock.showEditButtonCallCounter, 1)
        XCTAssertEqual(viewMock.reloadCallArguments?.isEmpty, false)
        XCTAssertEqual(bankResolverMock.resolveCallsCount, 1)
        XCTAssertEqual(paymentSystemResolverMock.resolveCallsCount, 1)
    }

    func test_viewDidTapCard_withCardListUseCase_shouldDoNothing() throws {
        // given
        prepareSut()
        let cards = buildActiveCardsCache()
        sutAsProtocol.viewDidHideShimmer(fetchCardsResult: .success(cards))

        // when
        sutAsProtocol.viewDidTapCard(cardIndex: 0)

        // then
        XCTAssertEqual(output.cardListWillCloseAfterSelectingCalls.count, 0)
        XCTAssertEqual(viewMock.dismissCallCounter, 0)
    }

    func test_viewDidTapCard_withCardListUseCase_shouldCloseScreen() {
        // given
        prepareSut(useCase: .cardPaymentList)
        let cards = buildActiveCardsCache()
        sutAsProtocol.viewDidHideShimmer(fetchCardsResult: .success(cards))
        cards.forEach { sut.addNewCardDidReceive(result: .succeded($0)) }

        // when
        sutAsProtocol.viewDidTapCard(cardIndex: 0)

        // then
        XCTAssertEqual(output.cardListWillCloseAfterSelectingCalls.count, 1)
        XCTAssertEqual(output.cardListWillCloseAfterSelectingCalls, cards)
        XCTAssertEqual(viewMock.closeScreenCounter, 1)
        XCTAssertEqual(viewMock.dismissCallCounter, 0)
    }

    func test_viewDidTapAddCardCell_shouldOpenAddNewCard() throws {
        allureId(2397529, "Переход на экран добавления карты")

        // given
        prepareSut()

        // when
        sutAsProtocol.viewDidTapAddCardCell()

        // then
        XCTAssertEqual(router.openAddNewCardsCallsCount, 1)
    }

    func test_viewDidTapAddCardCell_shouldOpenCardPayment() throws {
        // given
        prepareSut(useCase: .cardPaymentList)

        // when
        sutAsProtocol.viewDidTapAddCardCell()

        // then
        XCTAssertEqual(router.openCardPaymentCallsCount, 1)
    }

    func test_getCardList_unknownCustomer_error_when_configurationIsCardList() {
        // given
        prepareSut()
        let noSuchCustomerErrorCode = 7
        var didShowNoCardsStub = false
        viewMock.showStubStub = { stubMode in
            if case StubMode.noCardsInCardList = stubMode {
                didShowNoCardsStub = true
            }
        }

        // when
        sutAsProtocol.viewDidHideShimmer(
            fetchCardsResult: .failure(APIFailureError(errorCode: noSuchCustomerErrorCode))
        )
        if case let .noCardsInCardList(action) = viewMock.showStubCallArguments {
            action()
        }

        // then
        XCTAssertEqual(viewMock.showStubCallCounter, 1)
        XCTAssertTrue(didShowNoCardsStub)
        XCTAssertEqual(router.openAddNewCardsCallsCount, 1)
    }

    func test_getCardList_unkownCustomer_error_when_configurationIsCardPaymentList() {
        // given
        prepareSut(useCase: .cardPaymentList)
        let noSuchCustomerErrorCode = 7

        // when
        sutAsProtocol.viewDidHideShimmer(
            fetchCardsResult: .failure(APIFailureError(errorCode: noSuchCustomerErrorCode))
        )
        if case let .noCardsInCardPaymentList(action) = viewMock.showStubCallArguments {
            action()
        }

        // then
        XCTAssertEqual(viewMock.showStubCallCounter, 1)
        XCTAssertEqual(router.openCardPaymentCallsCount, 1)
    }

    func test_viewDidTapDelete() throws {
        allureId(2397531, "Отправляем запрос удаления карты при тапе на кнопку")
        allureId(2397536, "Уменьшение списка карт при успешном удаление карты")
        allureId(2397533, "Инициализируем заглушку в случае удаления последней карты")
        allureId(2397540, "Выход из состояния редактирования списка карт")
        allureId(2397539, "Промежуточное состояние при удалении карты")

        // given
        prepareSut()
        let cards = buildActiveCardsCache()
        let card = try XCTUnwrap(cards.first)
        let cardListCardToDelete = CardList.Card(from: card)
        var passedCardId = ""
        var didDeleteCardFromView = false
        var didShowNoCardsStub = false

        viewMock.reloadStub = { sections in
            let cardList = sections.getCardListFromCardsSection()
            didDeleteCardFromView = cardList.count == (cards.count - 1) &&
                !cardList.contains { $0.id == card.cardId }
        }

        viewMock.showStubStub = {
            if case StubMode.noCardsInCardList = $0 {
                didShowNoCardsStub = true
            }
        }

        cardsControllerMock.removeCardStub = { cardId, completion in
            passedCardId = cardId
            completion(.success(RemoveCardPayload(cardId: cardId, cardStatus: .deleted)))
        }

        sut.viewDidHideShimmer(fetchCardsResult: .success(cards))
        sut.viewDidTapEditButton()

        // when
        sut.view(didTapDeleteOn: cardListCardToDelete)
        sut.viewDidHideRemovingCardSnackBar()

        // then
        XCTAssertEqual(viewMock.showRemovingCardSnackBarCallCounter, 1)
        XCTAssertEqual(viewMock.disableViewUserInteractionCallCounter, 1)
        XCTAssertEqual(cardsControllerMock.removeCardCallsCount, 1)
        XCTAssertEqual(passedCardId, card.cardId)
        XCTAssertEqual(viewMock.hideLoadingSnackbarCallCounter, 1)
        XCTAssertTrue(didDeleteCardFromView)
        XCTAssertTrue(didShowNoCardsStub)
        XCTAssertEqual(viewMock.hideRightBarButtonCalCounter, 1)
    }

    func test_addNewCardDidReceive() {
        allureId(2397518, "Отображение нового списка карт в случае успешного добавления без прохождения 3ds")
        allureId(2397502)
        // given
        prepareSut()
        let cards = buildActiveCardsCache()
        let paymentCard = PaymentCard.fake()
        sutAsProtocol.viewDidHideShimmer(fetchCardsResult: .success(cards))

        // when
        sut.addNewCardDidReceive(result: .succeded(paymentCard))

        // then
        XCTAssertEqual(viewMock.showAddedCardSnackbarCallCounter, 1)
    }

    func test_viewDidShowAddedCardSnackbar() {
        allureId(2397518, "Отображение нового списка карт в случае успешного добавления без прохождения 3ds")
        allureId(2397502)
        // given
        prepareSut()

        // when
        sut.viewDidShowAddedCardSnackbar()

        // then
        let counter = viewMock.showDoneEditingButtonCallCounter + viewMock.showEditButtonCallCounter
        XCTAssertTrue(counter > 0)
        XCTAssertEqual(viewMock.hideStubCallCounter, 1)
        XCTAssertEqual(viewMock.reloadCallCounter, 1)
    }

    func test_viewDidShowAddedCardSnackbar_shows_doneEditingButton() {
        // given
        prepareSut()
        sut.viewDidHideShimmer(fetchCardsResult: .success(buildActiveCardsCache()))
        // setting screenState to .editingCards
        sut.viewDidTapEditButton()

        // resetting calls state
        viewMock.showDoneEditingButtonCallCounter = .zero
        viewMock.hideStubCallCounter = .zero
        viewMock.reloadCallCounter = .zero

        // when
        sut.viewDidShowAddedCardSnackbar()

        // then
        XCTAssertEqual(viewMock.showDoneEditingButtonCallCounter, 1)
        XCTAssertEqual(viewMock.hideStubCallCounter, 1)
        XCTAssertEqual(viewMock.reloadCallCounter, 1)
    }

    func test_viewDidShowAddedCardSnackbar_shows_editButton() {
        // given
        prepareSut()

        // when
        sut.viewDidShowAddedCardSnackbar()

        // then
        XCTAssertEqual(viewMock.showEditButtonCallCounter, 1)
        XCTAssertEqual(viewMock.hideStubCallCounter, 1)
        XCTAssertEqual(viewMock.reloadCallCounter, 1)
    }

    func test_viewDoesNotShowCards_whenAddCardResultIsCancelled() {
        // given
        prepareSut()

        // when
        sut.addNewCardDidReceive(result: .cancelled)

        // then
        XCTAssertEqual(viewMock.showAddedCardSnackbarCallCounter, 0)
    }

    func test_viewDoesNotShowCards_whenAddCardResultIsFailed() {
        // given
        prepareSut()

        // when
        sut.addNewCardDidReceive(result: .failed(ErrorStub()))

        // then
        XCTAssertEqual(viewMock.showAddedCardSnackbarCallCounter, 0)
    }

    func test_viewHideShimmer_whenCardsAreNotEmpty() {
        // given
        prepareSut()
        sut.addNewCardDidReceive(result: .succeded(.fake()))

        // when
        sut.viewDidLoad()

        // then
        XCTAssertEqual(viewMock.hideShimmerCallCounter, 1)
    }

    // MARK: Private

    private func prepareSut(useCase: CardListScreenConfiguration.UseCase = .cardList) {
        sut = CardListPresenter(
            screenConfiguration: buildScreenConfiguration(useCase: useCase),
            cardsController: cardsControllerMock,
            router: router,
            imageResolver: paymentSystemImageResolverMock,
            bankResolver: bankResolverMock,
            paymentSystemResolver: paymentSystemResolverMock,
            output: output
        )

        sut.view = viewMock
    }
}

// MARK: - Helpers

extension CardListPresenterTests {

    func buildActiveCardsCache() -> [PaymentCard] {
        [
            PaymentCard(
                pan: "220138******0104",
                cardId: "458542919",
                status: .active,
                parentPaymentId: nil,
                expDate: "1129"
            ),
        ]
    }

    func buildCardListCard() -> CardList.Card {
        CardList.Card(
            id: "",
            pan: "",
            cardModel: DynamicIconCardView.Model(data: DynamicIconCardView.Data()),
            bankNameText: "",
            cardNumberText: "",
            isInEditingMode: true,
            hasCheckmarkInNormalMode: false
        )
    }

    func buildScreenConfiguration(useCase: CardListScreenConfiguration.UseCase = .cardList) -> CardListScreenConfiguration {
        CardListScreenConfiguration(
            useCase: useCase,
            selectedCardId: nil
        )
    }
}

extension Array where Element == CardListSection {

    func getCardListFromCardsSection() -> [CardList.Card] {
        for section in self {
            if case let .cards(cardList) = section {
                return cardList
            }
        }

        return []
    }
}
