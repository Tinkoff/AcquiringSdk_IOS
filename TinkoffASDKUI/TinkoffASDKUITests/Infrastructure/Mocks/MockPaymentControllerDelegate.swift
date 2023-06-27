//
//  MockPaymentControllerDelegate.swift
//  TinkoffASDKUI-Unit-Tests
//
//  Created by Ivan Glushko on 21.10.2022.
//

import TinkoffASDKCore
@testable import TinkoffASDKUI

final class MockPaymentControllerDelegate: PaymentControllerDelegate {
    // MARK: - paymentController

    struct DidFinishPaymentPassedArguments {
        let controller: IPaymentController
        let didFinishPayment: IPaymentProcess
        let state: GetPaymentStatePayload
        let cardId: String?
        let rebillId: String?
    }

    var paymentControllerDidFinishPaymentCallCounter = 0
    var paymentControllerDidFinishPaymentParameters: (data: DidFinishPaymentPassedArguments, Void)?
    var paymentControllerDidFinishPaymentReturnStub: (DidFinishPaymentPassedArguments) -> Void = { _ in }

    func paymentController(
        _ controller: IPaymentController,
        didFinishPayment: IPaymentProcess,
        with state: GetPaymentStatePayload,
        cardId: String?,
        rebillId: String?
    ) {
        paymentControllerDidFinishPaymentCallCounter += 1
        let args = DidFinishPaymentPassedArguments(
            controller: controller,
            didFinishPayment: didFinishPayment,
            state: state,
            cardId: cardId,
            rebillId: rebillId
        )
        paymentControllerDidFinishPaymentParameters = (args, ())
        paymentControllerDidFinishPaymentReturnStub(args)
    }

    // MARK: - paymentController

    struct WasCancelledPassedArguments {
        let controller: IPaymentController
        let paymentWasCancelled: IPaymentProcess
        let cardId: String?
        let rebillId: String?
    }

    var paymentControllerPaymentWasCancelledCallCounter = 0
    var paymentControllerPaymentWasCancelledParameters: (data: WasCancelledPassedArguments, Void)?
    var paymentControllerPaymentWasCancelledReturnStub: (WasCancelledPassedArguments) -> Void = { _ in }

    func paymentController(
        _ controller: IPaymentController,
        paymentWasCancelled: IPaymentProcess,
        cardId: String?,
        rebillId: String?
    ) {
        let data = WasCancelledPassedArguments(
            controller: controller,
            paymentWasCancelled: paymentWasCancelled,
            cardId: cardId,
            rebillId: rebillId
        )

        paymentControllerPaymentWasCancelledCallCounter += 1
        paymentControllerPaymentWasCancelledParameters = (data, ())
        paymentControllerPaymentWasCancelledReturnStub(data)
    }

    // MARK: - paymentController

    struct DidFailedPassedArguments {
        let controller: IPaymentController
        let didFailedError: Error
        let cardId: String?
        let rebillId: String?
    }

    var paymentControllerDidFailedCallCounter = 0
    var paymentControllerDidFailedParameters: (data: DidFailedPassedArguments, Void)?
    var paymentControllerDidFailedReturnStub: (DidFailedPassedArguments) -> Void = { _ in }

    func paymentController(
        _ controller: IPaymentController,
        didFailed error: Error,
        cardId: String?,
        rebillId: String?
    ) {
        let data = DidFailedPassedArguments(
            controller: controller,
            didFailedError: error,
            cardId: cardId,
            rebillId: rebillId
        )

        paymentControllerDidFailedCallCounter += 1
        paymentControllerDidFailedParameters = (data, ())
        paymentControllerDidFailedReturnStub(data)
    }
}
