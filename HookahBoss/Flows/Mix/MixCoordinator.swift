//
//  MixCoordinator.swift
//  HookahBoss
//
//  Created by Богдан Костюченко on 09.04.2021.
//

import Combine
import UIKit

/// Координатор доставок
final class MixCoordinator: Coordinator {

    // MARK: - Proeprties
    let navigationController = UINavigationController()
    var childCoordinators: [Coordinator] = []

    func start() {
        let viewModel = MixFeedViewModel()
        let viewController = MixFeedViewController(viewModel: viewModel)
        navigationController.viewControllers = [viewController]
        navigationController.tabBarItem = UITabBarItem(
            title: Localizations.mixes,
            image: Images.TabBar.mixFeed.image,
            selectedImage: nil
        )
    }

}
