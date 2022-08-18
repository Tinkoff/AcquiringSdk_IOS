//
//
//  AcquiringAPIIntegrationTests.swift
//
//  Copyright (c) 2021 Tinkoff Bank
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


@testable import TinkoffASDKCore
import XCTest

final class AcquiringAPIIntegrationTests: XCTestCase {
    
    private let expectationTimeout: TimeInterval = 5
    
    let customerKey = "CustomerKey"
    let terminalKey = "TerminalKey"
    
    let networkClient = MockNetworkClient()
    
    let apiResponseDecoder = AcquiringAPIResponseDecoder(decoder: JSONDecoder())
    lazy var api = AcquiringAPI(networkClient: networkClient,
                                apiResponseDecoder: apiResponseDecoder)

    func testCorrectPayloadIfCorrectResponseWithStandartFormat() {
        let amount: Int64 = 320
        let orderId = "12345"
        let paymentId: PaymentId = "999"
        let status = PaymentStatus.new
        
        let responseString =
        """
            {
                "\(APIConstants.Keys.success)": true,
                "\(APIConstants.Keys.amount)": \(amount),
                "\(APIConstants.Keys.orderId)": "\(orderId)",
                "\(APIConstants.Keys.paymentId)": "\(paymentId)",
                "\(APIConstants.Keys.status)": "\(status.rawValue)",
                "\(APIConstants.Keys.errorCode)": "0"
            }
        """
        let responseData = responseString.data(using: .utf8)
        networkClient.data = responseData
        
        var request = MockAPIRequest<InitPayload>()
        request.httpMethod = .post
        request.decodeStrategy = .standart
        
        let expectedPayload = InitPayload(amount: amount,
                                          orderId: orderId,
                                          paymentId: paymentId,
                                          status: status)
        
        let apiRequestExpectation = XCTestExpectation()
        api.performRequest(request) { result in
            do {
                let payload = try result.get()
                XCTAssertEqual(payload, expectedPayload)
            } catch {
                XCTFail()
            }
            apiRequestExpectation.fulfill()
        }
        
        wait(for: [apiRequestExpectation], timeout: expectationTimeout)
    }
    
    func testCorrectPayloadIfCorrectResponseWithClippedFormat() {
        let amount: Int64 = 320
        let orderId = "12345"
        let paymentId: PaymentId = "999"
        let status = PaymentStatus.new
        
        let responseString =
        """
        [
            {
                "\(APIConstants.Keys.amount)": \(amount),
                "\(APIConstants.Keys.orderId)": "\(orderId)",
                "\(APIConstants.Keys.paymentId)": "\(paymentId)",
                "\(APIConstants.Keys.status)": "\(status.rawValue)"
            },
            {
                "\(APIConstants.Keys.amount)": \(amount),
                "\(APIConstants.Keys.orderId)": "\(orderId)",
                "\(APIConstants.Keys.paymentId)": "\(paymentId)",
                "\(APIConstants.Keys.status)": "\(status.rawValue)"
            }
        ]
        """
        let responseData = responseString.data(using: .utf8)
        networkClient.data = responseData
        
        var request = MockAPIRequest<[InitPayload]>()
        request.httpMethod = .post
        request.decodeStrategy = .clipped
        
        let expectedPayload = Array(repeating: InitPayload(amount: amount,
                                                           orderId: orderId,
                                                           paymentId: paymentId,
                                                           status: status),
                                    count: 2)
        
        let apiRequestExpectation = XCTestExpectation()
        api.performRequest(request) { result in
            do {
                let payload = try result.get()
                XCTAssertEqual(payload, expectedPayload)
            } catch {
                XCTFail()
            }
            apiRequestExpectation.fulfill()
        }
        
        wait(for: [apiRequestExpectation], timeout: expectationTimeout)
    }
    
    func testAPIFailureErrorForStandartDecodeStrategy() {
        testAPIFailureErrorFor(decodeStrategy: .standart)
    }
    
    func testAPIFailureErrorForClippedDecodeStrategy() {
        testAPIFailureErrorFor(decodeStrategy: .clipped)
    }
    
    func testAPIFailureErrorFor(decodeStrategy: APIRequestDecodeStrategy) {
        let errorCode = 20
        let errorMessage = "error message"
        let errorDetails = "error details"
        let terminalKey = "TestSDK"
        let status = "REJECTED"
        let orderId = "order id"
        let paymentId = "payment id"
        let amount = 10

        let responseString =
        """
        {
            "\(APIConstants.Keys.success)": false,
            "\(APIConstants.Keys.errorCode)": "\(errorCode)",
            "\(APIConstants.Keys.errorMessage)": "\(errorMessage)",
            "\(APIConstants.Keys.errorDetails)": "\(errorDetails)",
            "\(APIConstants.Keys.terminalKey)": "\(terminalKey)",
            "\(APIConstants.Keys.status)": "\(status)",
            "\(APIConstants.Keys.orderId)": "\(orderId)",
            "\(APIConstants.Keys.paymentId)": "\(paymentId)",
            "\(APIConstants.Keys.amount)": \(amount)
        }
        """
        
        let responseData = responseString.data(using: .utf8)
        networkClient.data = responseData
        
        var request = MockAPIRequest<InitPayload>()
        request.httpMethod = .post
        request.decodeStrategy = decodeStrategy
        
        let apiRequestExpectation = XCTestExpectation()
        api.performRequest(request) { result in
            do {
                let _ = try result.get()
                XCTFail()
            } catch APIError.failure(let apiFailureError) {
                XCTAssertEqual(apiFailureError.errorMessage, errorMessage)
                XCTAssertEqual(apiFailureError.errorDetails, errorDetails)
                XCTAssertEqual(apiFailureError.errorCode, errorCode)
                XCTAssertEqual(apiFailureError.terminalKey, terminalKey)
                XCTAssertEqual(apiFailureError.status, status)
                XCTAssertEqual(apiFailureError.orderId, orderId)
                XCTAssertEqual(apiFailureError.paymentId, paymentId)
                XCTAssertEqual(apiFailureError.amount, amount)
            } catch {
                XCTFail()
            }
            apiRequestExpectation.fulfill()
        }
        
        wait(for: [apiRequestExpectation], timeout: expectationTimeout)
    }
    
    func testInvalidResponseError() {
        let errorCode = 20
        
        let responseString =
        """
        {
            "\(APIConstants.Keys.errorCode)": \(errorCode)
        }
        """
        
        let responseData = responseString.data(using: .utf8)
        networkClient.data = responseData
        
        var request = MockAPIRequest<InitPayload>()
        request.httpMethod = .post
        request.decodeStrategy = .standart
        
        let apiRequestExpectation = XCTestExpectation()
        api.performRequest(request) { result in
            do {
                let _ = try result.get()
                XCTFail()
            } catch APIError.invalidResponse {
                
            } catch {
                XCTFail()
            }
            apiRequestExpectation.fulfill()
        }
        
        wait(for: [apiRequestExpectation], timeout: expectationTimeout)
    }
}
