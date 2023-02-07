//
//  UIWindow+Ext.swift
//  TinkoffASDKUI
//
//  Created by Ivan Glushko on 27.10.2022.
//

import UIKit

extension UIWindow {

    static var globalSafeAreaInsets: UIEdgeInsets {
        guard let window = Self.findKeyWindow() else { return .zero }
        return window.safeAreaInsets
    }

    static func findKeyWindow() -> UIWindow? {

        if #available(iOS 13.0, *) {
            return UIApplication
                .shared
                .connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication
                .shared
                .keyWindow
        }
    }
}
