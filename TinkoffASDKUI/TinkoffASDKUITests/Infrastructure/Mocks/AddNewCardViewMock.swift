//
//  AddNewCardViewMock.swift
//  TinkoffASDKUI-Unit-Tests
//
//  Created by Ivan Glushko on 27.03.2023.
//

@testable import TinkoffASDKUI

final class AddNewCardViewMock: IAddNewCardView {

    // MARK: - reloadCollection

    var reloadCollectionCallsCount = 0
    var reloadCollectionReceivedArguments: [AddNewCardSection]?
    var reloadCollectionReceivedInvocations: [[AddNewCardSection]] = []

    func reloadCollection(sections: [AddNewCardSection]) {
        reloadCollectionCallsCount += 1
        let arguments = sections
        reloadCollectionReceivedArguments = arguments
        reloadCollectionReceivedInvocations.append(arguments)
    }

    // MARK: - showLoadingState

    var showLoadingStateCallsCount = 0

    func showLoadingState() {
        showLoadingStateCallsCount += 1
    }

    // MARK: - hideLoadingState

    var hideLoadingStateCallsCount = 0

    func hideLoadingState() {
        hideLoadingStateCallsCount += 1
    }

    // MARK: - closeScreen

    var closeScreenCallsCount = 0

    func closeScreen() {
        closeScreenCallsCount += 1
    }

    // MARK: - disableAddButton

    var disableAddButtonCallsCount = 0

    func disableAddButton() {
        disableAddButtonCallsCount += 1
    }

    // MARK: - enableAddButton

    var enableAddButtonCallsCount = 0

    func enableAddButton() {
        enableAddButtonCallsCount += 1
    }

    // MARK: - activateCardField

    var activateCardFieldCallsCount = 0

    func activateCardField() {
        activateCardFieldCallsCount += 1
    }

    // MARK: - showOkNativeAlert

    var showOkNativeAlertCallsCount = 0
    var showOkNativeAlertReceivedArguments: OkAlertData?
    var showOkNativeAlertReceivedInvocations: [OkAlertData] = []

    func showOkNativeAlert(data: OkAlertData) {
        showOkNativeAlertCallsCount += 1
        let arguments = data
        showOkNativeAlertReceivedArguments = arguments
        showOkNativeAlertReceivedInvocations.append(arguments)
    }
}