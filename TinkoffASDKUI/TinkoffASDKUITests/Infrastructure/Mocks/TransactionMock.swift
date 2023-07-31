//
//  TransactionMock.swift
//  TinkoffASDKUI-Unit-Tests
//
//  Created by Ivan Glushko on 27.04.2023.
//

import TdsSdkIos
import ThreeDSWrapper
@testable import TinkoffASDKUI

final class TransactionMock: ITransaction {

    // MARK: - getAuthenticationRequestParameters

    var getAuthenticationRequestParametersThrowableError: Error?
    var getAuthenticationRequestParametersCallsCount = 0
    var getAuthenticationRequestParametersReturnValue: AuthenticationRequestParameters!

    func getAuthenticationRequestParameters() throws -> AuthenticationRequestParameters {
        if let error = getAuthenticationRequestParametersThrowableError {
            throw error
        }
        getAuthenticationRequestParametersCallsCount += 1
        return getAuthenticationRequestParametersReturnValue
    }

    // MARK: - doChallenge

    typealias DoChallengeArguments = (challengeParameters: ChallengeParameters, challengeStatusReceiver: ChallengeStatusReceiver, timeout: Int)

    var doChallengeCallsCount = 0
    var doChallengeReceivedArguments: DoChallengeArguments?
    var doChallengeReceivedInvocations: [DoChallengeArguments?] = []

    func doChallenge(challengeParameters: ChallengeParameters, challengeStatusReceiver: ChallengeStatusReceiver, timeout: Int) {
        doChallengeCallsCount += 1
        let arguments = (challengeParameters, challengeStatusReceiver, timeout)
        doChallengeReceivedArguments = arguments
        doChallengeReceivedInvocations.append(arguments)
    }

    // MARK: - getProgressView

    var getProgressViewCallsCount = 0
    var getProgressViewReturnValue: ProgressDialog!

    func getProgressView() -> ProgressDialog {
        getProgressViewCallsCount += 1
        return getProgressViewReturnValue
    }

    // MARK: - close

    var closeCallsCount = 0

    func close() {
        closeCallsCount += 1
    }
}

// MARK: - Resets

extension TransactionMock {
    func fullReset() {
        getAuthenticationRequestParametersThrowableError = nil
        getAuthenticationRequestParametersCallsCount = 0

        doChallengeCallsCount = 0
        doChallengeReceivedArguments = nil
        doChallengeReceivedInvocations = []

        getProgressViewCallsCount = 0

        closeCallsCount = 0
    }
}
