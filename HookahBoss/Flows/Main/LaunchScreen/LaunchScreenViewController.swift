//
//  LaunchScreenViewController.swift
//  HookahBoss
//
//  Created by Богдан Костюченко on 09.04.2021.
//

import Combine
import UIKit

final class LaunchScreenViewController: UIViewController {

    // MARK: - Properties
    private(set) var didFinishLaunching = PassthroughSubject<Void, Never>()

    // MARK: - Lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        didFinishLaunching.send()
    }

}
