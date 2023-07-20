//
//
//  ThreeDSDeviceInfo.swift
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

/// Объект передающий информацию для проведения 3DS транзакции
///
/// Все поля начинающиеся с префикса:
/// - sdk - передаются для app based flow транзакции
/// - остальные - для browser flow транзакции
public struct ThreeDSDeviceInfo {
    /// Indicates whether the 3DS Method successfully completed.
    ///
    /// Y - Successfully completed.
    /// N - Did not run or did not successfully complete.
    /// U - Unavailable 3DS Method URL was not present in the PRes message data.
    public let threeDSCompInd: String

    /// Boolean in string format that represents the ability of the cardholder browser to execute Java.
    ///
    /// Values: true, false
    public let javaEnabled: String

    /// Value representing the bit depth of the colour palette for displaying images, in bits per pixel.
    ///
    /// Values accepted: 1–99
    public let colorDepth: Int

    /// Value representing the browser language
    public let language: String

    /// Time-zone offset in minutes
    public let timezone: Int

    /// Total height of the Cardholder’s screen
    public let screenHeight: Int

    /// Total width of the Cardholder’s screen
    public let screenWidth: Int

    /// Url that should be called once 3DS verification was succesfull
    public let cresCallbackUrl: String

    /// Universally unique ID created upon all installations of the 3DS Requestor App on a Consumer Device.
    /// This will be newly generated and stored by the 3DS SDK for each installation
    public let sdkAppID: String?

    /// Public key component of the ephemeral key pair generated by the 3DS SDK
    /// And used to establish session keys between the 3DS SDK and ACS
    public let sdkEphemPubKey: String?

    /// Identifies the vendor and version of the 3DS SDK that is utilised for a specific transaction.
    /// The value is assigned by EMVCo
    public let sdkReferenceNumber: String?

    /// Universally unique transaction identifier assigned by the 3DS SDK to identify a single transaction.
    public let sdkTransID: String?

    /// Indicates maximum amount of time (in minutes) for all exchanges
    ///
    /// Values accepted: Greater than or = 05
    public let sdkMaxTimeout: String?

    /// JWE Object (represented as a string) containing data encrypted by the 3DS SDK for the DS to decrypt
    public let sdkEncData: String?

    /// Lists all of the SDK Interface types that the device supports
    /// for displaying specific challenge user interfaces within the 3DS SDK
    ///
    /// Values accepted:
    /// - 01 = Native
    /// - 02 = HTML
    /// - 03 = Both
    public let sdkInterface: TdsSdkInterface

    /// Lists all UI types that the device supports for displaying
    /// specific challenge user interfaces within the 3DS SDK.
    ///
    /// Valid values for each Interface:
    /// - Native UI = 01–04
    /// - HTML UI = 01–05
    ///
    /// Values accepted:
    /// - 01 = Text
    /// - 02 = Single Select
    /// - 03 = Multi Select
    /// - 04 = OOB
    /// - 05 = HTML Other (valid only for HTML UI)
    public let sdkUiType: String

    // MARK: - Init

    public init(
        threeDSCompInd: String,
        javaEnabled: String,
        colorDepth: Int,
        language: String,
        timezone: Int,
        screenHeight: Int,
        screenWidth: Int,
        cresCallbackUrl: String,
        sdkAppID: String?,
        sdkEphemPubKey: String?,
        sdkReferenceNumber: String?,
        sdkTransID: String?,
        sdkMaxTimeout: String?,
        sdkEncData: String?,
        sdkInterface: TdsSdkInterface,
        sdkUiType: String
    ) {
        self.threeDSCompInd = threeDSCompInd
        self.javaEnabled = javaEnabled
        self.colorDepth = colorDepth
        self.language = language
        self.timezone = timezone
        self.screenHeight = screenHeight
        self.screenWidth = screenWidth
        self.cresCallbackUrl = cresCallbackUrl
        self.sdkAppID = sdkAppID
        self.sdkEphemPubKey = sdkEphemPubKey
        self.sdkReferenceNumber = sdkReferenceNumber
        self.sdkTransID = sdkTransID
        self.sdkMaxTimeout = sdkMaxTimeout
        self.sdkEncData = sdkEncData
        self.sdkInterface = sdkInterface
        self.sdkUiType = sdkUiType
    }
}

// MARK: - ThreeDSDeviceInfo + Encodable

extension ThreeDSDeviceInfo: Encodable {
    private enum CodingKeys: String, CodingKey {
        case threeDSCompInd
        case javaEnabled
        case colorDepth
        case language
        case timezone
        case screenHeight = "screen_height"
        case screenWidth = "screen_width"
        case cresCallbackUrl
        case sdkAppID
        case sdkEphemPubKey
        case sdkReferenceNumber
        case sdkTransID
        case sdkMaxTimeout
        case sdkEncData
        case sdkInterface
        case sdkUiType
    }
}
