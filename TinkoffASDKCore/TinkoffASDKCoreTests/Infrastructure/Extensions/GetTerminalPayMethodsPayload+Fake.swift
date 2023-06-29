//
//  GetTerminalPayMethodsPayload+Fake.swift
//  TinkoffASDKYandexPay-Unit-Tests
//
//  Created by Ivan Glushko on 19.05.2023.
//

@testable import TinkoffASDKCore

extension GetTerminalPayMethodsPayload {

    static func fake(methods: [TerminalPayMethod], addCardScheme: Bool = false) -> Self {
        GetTerminalPayMethodsPayload(
            terminalInfo: TerminalInfo(
                payMethods: methods,
                addCardScheme: addCardScheme
            )
        )
    }
}
