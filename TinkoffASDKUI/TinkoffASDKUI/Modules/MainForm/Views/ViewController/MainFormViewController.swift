//
//  MainFormViewController.swift
//  TinkoffASDKUI
//
//  Created by r.akhmadeev on 19.01.2023.
//

import UIKit

final class MainFormViewController: UIViewController, PullableContainerScrollableContent {

    // MARK: PullableContainer Properties

    var scrollView: UIScrollView { tableView }
    var pullableContainerContentHeight: CGFloat { headerView.bounds.height }
    var pullableContainerContentHeightDidChange: ((PullableContainerContent) -> Void)?

    // MARK: Dependencies

    private let presenter: IMainFormPresenter

    // MARK: Subviews

    private lazy var headerView = MainFormHeaderView(delegate: self)
    private lazy var tableView: UITableView = {
        // Явное присваивание фрейма до того, как произошел цикл autolayout,
        // позволяет избавиться от логов с конфликтами констрейнтов в консоли при установке `tableHeaderView`
        let tableView = UITableView(frame: view.bounds)
        tableView.alwaysBounceVertical = false

        return tableView
    }()

    // MARK: Init

    init(presenter: IMainFormPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        presenter.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Хедер таблицы не изменяет свой размер во время лейаута.
        // Здесь принудительно выставляется высота на основе его констрейнтов
        headerView.frame.size = headerView.systemLayoutSizeFitting(
            CGSize(width: headerView.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

    // MARK: Initial Configuration

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.pinEdgesToSuperview()
        tableView.tableHeaderView = headerView
    }
}

// MARK: - IMainFormViewController

extension MainFormViewController: IMainFormViewController {
    func updateHeader(with viewModel: MainFormHeaderViewModel) {
        headerView.update(with: viewModel)
    }
}

// MARK: - MainFormHeaderViewDelegate

extension MainFormViewController: MainFormHeaderViewDelegate {
    func headerViewDidTapPrimaryButton() {
        presenter.viewDidTapPayButton()
    }
}

// MARK: - PullableContainerContent Methods

extension MainFormViewController {
    func pullableContainerWasClosed() {
        presenter.viewWasClosed()
    }
}
