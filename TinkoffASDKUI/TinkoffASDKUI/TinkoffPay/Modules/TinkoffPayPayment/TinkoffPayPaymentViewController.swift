//
//  TinkoffPayPaymentViewController.swift
//  TinkoffASDKUI
//
//  Created by Serebryaniy Grigoriy on 15.04.2022.
//

import UIKit
import TinkoffASDKCore

final class TinkoffPayPaymentViewController: UIViewController, PaymentPollingContent {
    var didStartLoading: ((String) -> Void)?
    var didStopLoading: (() -> Void)?
    var didUpdatePaymentStatusResponse: ((PaymentStatusResponse) -> Void)?
    var paymentStatusResponse: (() -> PaymentStatusResponse?)?
    var showAlert: ((String, String?, Error) -> Void)?
    var didStartPayment: (() -> Void)?
    
    var scrollView: UIScrollView { UIScrollView() }
    
    var contentHeight: CGFloat { 0 }
    
    var contentHeightDidChange: ((PullableContainerContent) -> Void)?
    
    private let acquiringPaymentStageConfiguration: AcquiringPaymentStageConfiguration
    private let paymentService: PaymentService
    private let tinkoffPayController: TinkoffPayController
    private let tinkoffPayVersion: GetTinkoffPayStatusResponse.Status.Version
    private let application: UIApplication
    
    init(acquiringPaymentStageConfiguration: AcquiringPaymentStageConfiguration,
         paymentService: PaymentService,
         tinkoffPayController: TinkoffPayController,
         tinkoffPayVersion: GetTinkoffPayStatusResponse.Status.Version,
         application: UIApplication) {
        self.acquiringPaymentStageConfiguration = acquiringPaymentStageConfiguration
        self.paymentService = paymentService
        self.tinkoffPayController = tinkoffPayController
        self.tinkoffPayVersion = tinkoffPayVersion
        self.application = application
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        start()
    }
}

private extension TinkoffPayPaymentViewController {
    func setup() {}
    
    func start() {
        didStartLoading?("")
        
        switch acquiringPaymentStageConfiguration.paymentStage {
        case let .finish(paymentId):
            paymentService.getPaymentStatus(paymentId: paymentId) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .failure(error):
                    self.handleError(error)
                case let .success(response):
                    self.didUpdatePaymentStatusResponse?(PaymentStatusResponse(
                        status: response.status,
                        paymentState: .init(paymentId: response.paymentId,
                                            amount: response.amount,
                                            orderId: response.orderId,
                                            status: response.status))
                    )
                    self.performTinkoffPayWith(paymentId: response.paymentId,
                                               version: self.tinkoffPayVersion)
                }
            }
        case let .`init`(paymentData):
            var tinkoffPayPaymentData = paymentData
            tinkoffPayPaymentData.addPaymentData(["TinkoffPayWeb": "true"])
            paymentService.initPaymentWith(paymentData: tinkoffPayPaymentData) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .failure(error):
                    self.handleError(error)
                case let .success(response):
                    let statusResponse = PaymentStatusResponse(status: .new,
                                                               paymentState: .init(paymentId: response.paymentId,
                                                                                   amount: response.amount,
                                                                                   orderId: response.orderId,
                                                                                   status: .new))
                    self.didUpdatePaymentStatusResponse?(statusResponse)
                    self.performTinkoffPayWith(paymentId: response.paymentId,
                                               version: self.tinkoffPayVersion)
                }
            }
        }
    }
    
    func performTinkoffPayWith(paymentId: PaymentId,
                               version: GetTinkoffPayStatusResponse.Status.Version) {
        _ = tinkoffPayController.getTinkoffPayLink(paymentId: paymentId,
                                                   version: version,
                                                   completion: { [weak self] result in
            switch result {
            case let .success(url):
                self?.openTinkoffPayDeeplink(url: url)
            case let .failure(error):
                self?.handleError(error)
            }
        })
    }
    
    func openTinkoffPayDeeplink(url: URL) {
        guard application.canOpenURL(url) else {
            handleTinkoffAppNotInstalled()
            return
        }
        
        application.open(url, options: [:]) { [weak self] result in
            self?.handleTinkoffApplicationOpen(result: result)
        }
    }
    
    func handleTinkoffApplicationOpen(result: Bool) {
        if result {
            didStartPayment?()
            didStartLoading?(AcqLoc.instance.localize("TP.LoadingStatus.Title"))
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func handleError(_ error: Error) {
        DispatchQueue.main.async {
            let alertTitle = AcqLoc.instance.localize("TP.Error.Title")
            let alertDescription = AcqLoc.instance.localize("TP.Error.Description")
            
            self.showAlert?(alertTitle, alertDescription, error)
        }
    }
    
    func handleTinkoffAppNotInstalled() {
        didStopLoading?()
        let alertController = UIAlertController(title: AcqLoc.instance.localize("TP.NoTinkoffBankApp.Title"),
                                                message: AcqLoc.instance.localize("TP.NoTinkoffBankApp.Description"),
                                                preferredStyle: .alert)
        let installAction = UIAlertAction(title: AcqLoc.instance.localize("TP.NoTinkoffBankApp.Button.Install"),
                                          style: .default) { [weak self] _ in
            self?.application.open(.tinkoffBankStoreURL)
            self?.dismiss(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: AcqLoc.instance.localize("TP.NoTinkoffBankApp.Button.Сancel"),
                                         style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        }
        
        alertController.addAction(installAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
}

private extension URL {
    static var tinkoffBankStoreURL: URL {
        URL(string: "https://apps.apple.com/ru/app/tinkoff-mobile-banking/id455652438")!
    }
}

