//
//
//  GetPaymentStatePayload.swift
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


import Foundation

public struct GetPaymentStatePayload: Decodable {
    public let paymentId: PaymentId
    public let amount: Int64
    public let orderId: String
    public let status: PaymentStatus
    
    private enum CodingKeys: CodingKey {
        case amount
        case orderId
        case paymentId
        case status
        
        var stringValue: String {
            switch self {
            case .amount: return APIConstants.Keys.amount
            case .orderId: return APIConstants.Keys.orderId
            case .paymentId: return APIConstants.Keys.paymentId
            case .status: return APIConstants.Keys.status
            }
        }
    }
    
    public init(paymentId: PaymentId,
                amount: Int64,
                orderId: String,
                status: PaymentStatus) {
        self.paymentId = paymentId
        self.amount = amount
        self.orderId = orderId
        self.status = status
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        paymentId = try container.decode(PaymentId.self, forKey: .paymentId)
        amount = try container.decode(Int64.self, forKey: .amount)
        orderId = try container.decode(String.self, forKey: .orderId)
        status = try container.decodeIfPresent(PaymentStatus.self, forKey: .status) ?? .unknown
    }
}
