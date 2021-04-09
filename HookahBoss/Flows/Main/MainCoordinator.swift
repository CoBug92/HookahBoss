//
//  MainCoordinator.swift
//  HookahBoss
//
//  Created by Богдан Костюченко on 09.04.2021.
//

import Combine
import UIKit

final class MainCoordinator {

    // MARK: - Properties
    private let window: UIWindow
    private var childCoordinators: [Coordinator] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init/Deinit
    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let splashScreen = LaunchScreenViewController()
        splashScreen.didFinishLaunching
            .sink { [weak self] in self?.configsDidFinishLoading() }
            .store(in: &cancellables)
        window.rootViewController = splashScreen
        window.makeKeyAndVisible()
    }

    func configsDidFinishLoading() {
        let tabBarController = UITabBarController()
        let coordinators: [Coordinator] = [
            MixCoordinator()
        ]
        tabBarController.viewControllers = coordinators.map {
            childCoordinators.append($0)
            $0.start()
            return $0.navigationController
        }
        window.rootViewController = tabBarController
    }

}
