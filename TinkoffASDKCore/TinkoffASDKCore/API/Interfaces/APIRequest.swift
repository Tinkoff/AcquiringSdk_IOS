//
//
//  APIRequest.swift
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

enum APIRequestDecodeStrategy {
    case standart
    case clipped
}

protocol APIRequest: NetworkRequest {
    associatedtype Payload: Decodable
    var decodeStrategy: APIRequestDecodeStrategy { get }
    
    var requestPath: [String] { get }
    var apiVersion: APIVersion { get }
}

extension APIRequest {
    var decodeStrategy: APIRequestDecodeStrategy { .standart }
    var apiVersion: APIVersion { .v2 }
    var path: [String] { [apiVersion.path] + requestPath }
}

protocol TokenProvidableAPIRequest: NetworkRequest {
    var parametersForToken: HTTPParameters { get }
    var tokenParameterKeysToIgnore: Set<String> { get }
    var commonTokenParameterKeysToIgnore: Set<String> { get }
}

extension TokenProvidableAPIRequest {
    var commonTokenParameterKeysToIgnore: Set<String> {
        return [APIConstants.Keys.data,
                APIConstants.Keys.receipt,
                APIConstants.Keys.receipts,
                APIConstants.Keys.shops]
    }
    
    var tokenParameterKeysToIgnore: Set<String> { [] }
    var parametersForToken: HTTPParameters {
        parameters.filter { !commonTokenParameterKeysToIgnore.union(tokenParameterKeysToIgnore).contains($0.key) }
    }
}
