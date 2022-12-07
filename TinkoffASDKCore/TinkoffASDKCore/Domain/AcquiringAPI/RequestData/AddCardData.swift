//
//
//  AddCardData.swift
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

public struct AddCardData {
    /// Метод проверки при привязке карты
    public let checkType: PaymentCardCheckType
    /// Идентификатор клиента в системе продавца
    public let customerKey: String

    public init(with checkType: PaymentCardCheckType, customerKey: String) {
        self.checkType = checkType
        self.customerKey = customerKey
    }
}

// MARK: - AddCardData + Encodable

extension AddCardData: Encodable {
    private enum CodingKeys: CodingKey {
        case checkType
        case customerKey

        var stringValue: String {
            switch self {
            case .checkType: return Constants.Keys.checkType
            case .customerKey: return Constants.Keys.customerKey
            }
        }
    }
}
