//
//  AppDelegate.swift
//  HookahBoss
//
//  Created by Богдан Костюченко on 09.04.2021.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Properties
    var window: UIWindow?
    private var coordinator: MainCoordinator!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        coordinator = MainCoordinator(window: window)
        coordinator.start()

        return true
    }

}
