//
//  MixFeedViewController.swift
//  HookahBoss
//
//  Created by Богдан Костюченко on 09.04.2021.
//

import UIKit

final class MixFeedViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: MixFeedViewModel

    // MARK: - Init
    init(viewModel: MixFeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
