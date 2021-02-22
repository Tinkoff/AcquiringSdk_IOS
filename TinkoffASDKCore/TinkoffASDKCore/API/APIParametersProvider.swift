//
//
//  APIParametersProvider.swift
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

final class APIParametersProvider: NetworkRequestAdapter {
    
    private let customerKey: String
    private let terminalKey: String
    private let tokenBuilder: APITokenBuilder
    
    init(customerKey: String,
         terminalKey: String,
         tokenBuilder: APITokenBuilder) {
        self.customerKey = customerKey
        self.terminalKey = terminalKey
        self.tokenBuilder = tokenBuilder
    }
    
    func additionalParameters(for request: NetworkRequest) -> HTTPParameters {
        var commonParameters: HTTPParameters = [APIConstants.Keys.customerKey: customerKey,
                                                APIConstants.Keys.terminalKey: terminalKey]
        
        let token = tokenBuilder.buildToken(commonParameters: commonParameters,
                                            request: request as? TokenProvidableAPIRequest)
        commonParameters[APIConstants.Keys.token] = token
        
        return commonParameters
    }
}
