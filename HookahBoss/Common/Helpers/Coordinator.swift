//
//  Coordinator.swift
//  HookahBoss
//
//  Created by Богдан Костюченко on 09.04.2021.
//

import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get }

    /// Start the flow.
    func start()
}

extension Coordinator {
    /// Removes a child coordinator when its flow is complete.
    /// - Parameter child: A type of the child coordinator.
    func childDidFinish<T: Coordinator>(_ child: T.Type) {
        for (index, coordinator) in childCoordinators.enumerated() {
            if coordinator is T {
                childCoordinators.remove(at: index)
                break
            }
        }
    }
}

enum CoordinatorPresentationStyle {
    case modal(UIViewController)
    case push(UINavigationController)
}

final class PresentationControllerDismissAction: NSObject, UIAdaptivePresentationControllerDelegate {
    private var action: ((UIPresentationController) -> Void)?

    init(_ action: @escaping (UIPresentationController) -> Void) {
        super.init()
        self.action = {
            action($0)
            _ = self // Caprture self to prevent deinit
            self.action = nil // Release self after firing the action
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        action?(presentationController)
    }
}
