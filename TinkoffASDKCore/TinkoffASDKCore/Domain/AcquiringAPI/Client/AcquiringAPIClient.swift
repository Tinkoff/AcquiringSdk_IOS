//
//
//  AcquiringAPIClient.swift
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

protocol IAcquiringAPIClient {
    func performRequest<Payload: Decodable>(
        _ request: AcquiringRequest,
        completion: @escaping (Result<Payload, Error>) -> Void
    ) -> Cancellable

    @available(*, deprecated, message: "Use performRequest(_:completion:) instead")
    func performDeprecatedRequest<Response: ResponseOperation>(
        _ request: AcquiringRequest,
        delegate: NetworkTransportResponseDelegate?,
        completion: @escaping (Result<Response, Error>) -> Void
    ) -> Cancellable
}

final class AcquiringAPIClient: IAcquiringAPIClient {
    private let requestAdapter: IAcquiringRequestAdapter
    private let networkClient: INetworkClient
    private let apiDecoder: IAPIDecoder
    private let deprecatedDecoder: IDeprecatedDecoder

    init(
        requestAdapter: IAcquiringRequestAdapter,
        networkClient: INetworkClient,
        apiDecoder: IAPIDecoder,
        deprecatedDecoder: IDeprecatedDecoder
    ) {
        self.requestAdapter = requestAdapter
        self.networkClient = networkClient
        self.apiDecoder = apiDecoder
        self.deprecatedDecoder = deprecatedDecoder
    }

    // MARK: API

    func performRequest<Payload: Decodable>(
        _ request: AcquiringRequest,
        completion: @escaping (Swift.Result<Payload, Error>) -> Void
    ) -> Cancellable {
        let outerCancellable = CancellableWrapper()

        requestAdapter.adapt(request: request) { [networkClient, apiDecoder] adaptingResult in
            guard !outerCancellable.isCancelled else { return }

            switch adaptingResult {
            case let .success(request):
                let networkCancellable = networkClient.performRequest(request) { networkResult in
                    guard !outerCancellable.isCancelled else { return }

                    let result = networkResult
                        .tryMap { response in
                            try apiDecoder.decode(Payload.self, from: response.data, with: request.decodingStrategy)
                        }
                        .mapError { error -> Error in
                            switch error {
                            case let error as APIFailureError:
                                return APIError.failure(error)
                            default:
                                return APIError.invalidResponse
                            }
                        }

                    completion(result)
                }
                outerCancellable.addCancellationHandler(networkCancellable.cancel)
            case let .failure(error):
                completion(.failure(error))
            }
        }

        return outerCancellable
    }

    @available(*, deprecated, message: "Use performRequest(_:completion:) instead")
    func performDeprecatedRequest<Response: ResponseOperation>(
        _ request: AcquiringRequest,
        delegate: NetworkTransportResponseDelegate?,
        completion: @escaping (Result<Response, Error>) -> Void
    ) -> Cancellable {

        networkClient.performRequest(request) { [deprecatedDecoder] networkResult in
            let result: Result<Response, Error> = networkResult.tryMap { response in
                if let delegate = delegate {
                    guard let delegatedResponse = try? delegate.networkTransport(
                        didCompleteRawTaskForRequest: response.urlRequest,
                        withData: response.data,
                        response: response.httpResponse,
                        error: nil
                    ) else {
                        throw HTTPResponseError(
                            body: response.data,
                            response: response.httpResponse,
                            kind: .invalidResponse
                        )
                    }
                    // swiftlint:disable:next force_cast
                    return delegatedResponse as! Response
                }

                return try deprecatedDecoder.decode(data: response.data, with: response.httpResponse)
            }

            completion(result)
        }
    }
}
