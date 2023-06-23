//
//  CardsControllerTests.swift
//  Pods
//
//  Created by Ivan Glushko on 30.03.2023.
//

import XCTest

@testable import TinkoffASDKCore
@testable import TinkoffASDKUI

final class CardsControllerTests: BaseTestCase {

    var sut: CardsController!

    // Mocks

    var cardServiceMock: CardServiceMock!
    var addCardControllerMock: AddCardControllerMock!
    var dispatchQueueMock: DispatchQueueMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        cardServiceMock = CardServiceMock()
        addCardControllerMock = AddCardControllerMock()
        dispatchQueueMock = DispatchQueueMock()

        sut = CardsController(
            cardService: cardServiceMock,
            addCardController: addCardControllerMock,
            dispatchQueue: dispatchQueueMock
        )
    }

    override func tearDown() {
        cardServiceMock = nil
        addCardControllerMock = nil
        dispatchQueueMock = nil

        sut = nil

        DispatchQueueMock.resetPerformOnMain()

        super.tearDown()
    }

    // MARK: - Tests

    func test_GetCardList_invoked() {
        allureId(2397495, "Отправляем запрос v2/GetCardList в случае успешного ответа v2/GetAddCardState по 3ds v1 flow")
        allureId(2397497)
        allureId(2397510)
        allureId(2397532)

        // given
        cardServiceMock.getCardListReturnValue = CancellableMock()
        addCardControllerMock.underlyingCustomerKey = "key"
        addCardControllerMock.addCardCompletionStub = .succeded(.fake(status: .authorized))

        // when
        sut.addCard(options: CardOptions.fake(), completion: { _ in })

        // then
        XCTAssertEqual(cardServiceMock.getCardListCallsCount, 1)
    }

    func test_addCard_cancelled() {
        allureId(2397499, "Успешно обрабатываем отмену в случае статуса отмены web-view")

        // given
        addCardControllerMock.underlyingCustomerKey = "key"
        addCardControllerMock.addCardCompletionStub = .cancelled
        var mappedResultToCancelled = false

        DispatchQueueMock.performOnMainBlockClosureShouldCalls = true

        // when
        sut.addCard(options: CardOptions.fake(), completion: { result in
            guard case .cancelled = result else { return }
            mappedResultToCancelled = true
        })

        // then
        XCTAssertEqual(addCardControllerMock.addCardCallsCount, 1)
        XCTAssertTrue(mappedResultToCancelled)
    }

    func test_addCard_error() {
        allureId(2397521, "Успешно обрабатываем ошибку в случае ошибки запроса v2/GetAddCardState")
        allureId(2397515)

        // given
        addCardControllerMock.underlyingCustomerKey = "key"
        addCardControllerMock.addCardCompletionStub = .failed(TestsError.basic)
        var mappedResultToFailure = false

        DispatchQueueMock.performOnMainBlockClosureShouldCalls = true

        // when
        sut.addCard(options: CardOptions.fake(), completion: { result in
            guard case let .failed(error) = result, error is TestsError else { return }
            mappedResultToFailure = true
        })

        // then
        XCTAssertEqual(addCardControllerMock.addCardCallsCount, 1)
        XCTAssertTrue(mappedResultToFailure)
        XCTAssertEqual(cardServiceMock.getCardListCallsCount, .zero)
    }

    func test_addCard_success_GetCardList_error() {
        allureId(2397522, "Успешно обрабатываем ошибку в случае ошибки запроса v2/GetCardList")
        allureId(2397516)

        // given
        cardServiceMock.getCardListReturnValue = CancellableMock()
        cardServiceMock.getCardListCompletionClosureInput = .failure(TestsError.basic)
        addCardControllerMock.underlyingCustomerKey = "key"
        addCardControllerMock.addCardCompletionStub = .succeded(.fake(status: .authorized))
        var didReturnError = false

        DispatchQueueMock.performOnMainBlockClosureShouldCalls = true

        // when
        sut.addCard(options: CardOptions.fake(), completion: { result in
            if case let .failed(error) = result, error is TestsError {
                didReturnError = true
            }
        })

        // then
        XCTAssertEqual(cardServiceMock.getCardListCallsCount, 1)
        XCTAssertTrue(didReturnError)
    }

    func test_customerKey() {
        // given
        addCardControllerMock.underlyingCustomerKey = "some"

        // when
        let customerKey = sut.customerKey

        // then
        XCTAssertEqual(addCardControllerMock.customerKey, customerKey)
    }

    func test_removeCard_success() {
        // given
        let cardId = "213122412"
        let status = PaymentCardStatus.inactive
        let customerKey = "some key"

        DispatchQueueMock.performOnMainBlockClosureShouldCalls = true

        let payload = RemoveCardPayload(cardId: cardId, cardStatus: status)
        cardServiceMock.removeCardCompletionClosureInput = .success(payload)

        addCardControllerMock.underlyingCustomerKey = customerKey

        let expectedData = RemoveCardData(cardId: cardId, customerKey: customerKey)

        var successPayload: RemoveCardPayload?
        var faulireError: NSError?
        let completion: (Result<RemoveCardPayload, Error>) -> Void = { result in
            switch result {
            case let .success(payload):
                successPayload = payload
            case let .failure(error):
                faulireError = error as NSError
            }
        }

        // when
        sut.removeCard(cardId: cardId, completion: completion)

        // then
        XCTAssertEqual(cardServiceMock.removeCardCallsCount, 1)
        XCTAssertEqual(cardServiceMock.removeCardReceivedArguments?.data, expectedData)
        XCTAssertEqual(DispatchQueueMock.performOnMainCallsCount, 1)
        XCTAssertEqual(successPayload, payload)
        XCTAssertEqual(faulireError, nil)
    }

    func test_removeCard_failure() {
        // given
        let cardId = "213122412"
        let customerKey = "some key"
        let error = NSError(domain: "error", code: NSURLErrorNotConnectedToInternet)

        DispatchQueueMock.performOnMainBlockClosureShouldCalls = true

        cardServiceMock.removeCardCompletionClosureInput = .failure(error)

        addCardControllerMock.underlyingCustomerKey = customerKey

        let expectedData = RemoveCardData(cardId: cardId, customerKey: customerKey)

        var successPayload: RemoveCardPayload?
        var faulireError: NSError?
        let completion: (Result<RemoveCardPayload, Error>) -> Void = { result in
            switch result {
            case let .success(payload):
                successPayload = payload
            case let .failure(error):
                faulireError = error as NSError
            }
        }

        // when
        sut.removeCard(cardId: cardId, completion: completion)

        // then
        XCTAssertEqual(cardServiceMock.removeCardCallsCount, 1)
        XCTAssertEqual(cardServiceMock.removeCardReceivedArguments?.data, expectedData)
        XCTAssertEqual(DispatchQueueMock.performOnMainCallsCount, 1)
        XCTAssertEqual(successPayload, nil)
        XCTAssertEqual(faulireError, error)
    }

    func test_getActiveCards_success() {
        // given
        let customerKey = "some key"

        let cards: [PaymentCard] = [.fakeInactive()]
        cardServiceMock.getCardListCompletionClosureInput = .success(cards)

        DispatchQueueMock.performOnMainBlockClosureShouldCalls = true

        addCardControllerMock.underlyingCustomerKey = customerKey

        let expectedData = GetCardListData(customerKey: customerKey)

        var successCards: [PaymentCard]?
        var faulireError: NSError?
        let completion: (Result<[PaymentCard], Error>) -> Void = { result in
            switch result {
            case let .success(cards):
                successCards = cards
            case let .failure(error):
                faulireError = error as NSError
            }
        }

        // when
        sut.getActiveCards(completion: completion)

        // then
        XCTAssertEqual(cardServiceMock.getCardListCallsCount, 1)
        XCTAssertEqual(cardServiceMock.getCardListReceivedArguments?.data, expectedData)
        XCTAssertEqual(DispatchQueueMock.performOnMainCallsCount, 1)
        XCTAssertEqual(successCards, [])
        XCTAssertEqual(faulireError, nil)
    }

    func test_getActiveCards_failure() {
        // given
        let customerKey = "some key"

        let error = NSError(domain: "error", code: NSURLErrorNotConnectedToInternet)
        cardServiceMock.getCardListCompletionClosureInput = .failure(error)

        DispatchQueueMock.performOnMainBlockClosureShouldCalls = true

        addCardControllerMock.underlyingCustomerKey = customerKey

        let expectedData = GetCardListData(customerKey: customerKey)

        var successCards: [PaymentCard]?
        var faulireError: NSError?
        let completion: (Result<[PaymentCard], Error>) -> Void = { result in
            switch result {
            case let .success(cards):
                successCards = cards
            case let .failure(error):
                faulireError = error as NSError
            }
        }

        // when
        sut.getActiveCards(completion: completion)

        // then
        XCTAssertEqual(cardServiceMock.getCardListCallsCount, 1)
        XCTAssertEqual(cardServiceMock.getCardListReceivedArguments?.data, expectedData)
        XCTAssertEqual(DispatchQueueMock.performOnMainCallsCount, 1)
        XCTAssertEqual(successCards, nil)
        XCTAssertEqual(faulireError, error)
    }
}
