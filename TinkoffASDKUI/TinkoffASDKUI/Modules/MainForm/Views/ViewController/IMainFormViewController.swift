//
//  IMainFormViewController.swift
//  TinkoffASDKUI
//
//  Created by r.akhmadeev on 19.01.2023.
//

import Foundation

protocol IMainFormViewController: AnyObject {
    func reloadData()
    func insertRows(at indexPaths: [IndexPath])
    func deleteRows(at indexPaths: [IndexPath])
}

// MARK: - IMainFormViewController + Helpers

extension IMainFormViewController {
    func insertRow(at indexPath: IndexPath) {
        insertRows(at: [indexPath])
    }

    func deleteRow(at indexPath: IndexPath) {
        deleteRows(at: [indexPath])
    }
}