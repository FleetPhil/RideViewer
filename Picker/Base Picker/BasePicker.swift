//
//  BasePicker.swift
//  RideViewer
//
//  Created by West Hill Lodge on 19/08/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

open class BasePicker: NSObject {
    public typealias VoidHandlerType = (() -> Void)
    
    /// Name of the storyboard on which AbstractPopover is based
    let storyboardName: String
    
    /// Popover title
    var title: String?
    
    /// Base view controller
    private(set) weak var baseViewController: UIViewController?
    
    /// ViewController in charge of content in the popover
    private(set) weak var contentViewController: AnyObject?

    private(set) var isAllowedOutsideTappingDismissing: Bool?
    
    override public init() {
        //Get a string as storyboard name from this class name.
        storyboardName = String(describing: type(of: self))
    }
    
    open func setOutsideTapDismissing(allowed: Bool = true) -> Self {
        isAllowedOutsideTappingDismissing = allowed
        return self
    }
    
    // MARK: - Popover display
    
    /// Display the popover.
    ///
    /// - Parameter
    ///   - barButtonItem: Bar button item to be the origin point at where the popover appears.
    ///   - baseViewWhenOriginViewHasNoSuperview: SourceView of popoverPresentationController. Omissible. This view will be used instead of originView.superView when it is nil.
    ///   - baseViewController: Base viewController
    ///   - completion: Action to be performed after the popover appeared. Omissible.
    
    open func appear(barButtonItem: UIBarButtonItem, baseViewWhenOriginViewHasNoSuperview:  UIView? = nil, baseViewController: UIViewController, completion: VoidHandlerType? = nil) {
        guard let originView = barButtonItem.value(forKey: "view") as? UIView else {
            return
        }
        appear(originView: originView, baseViewWhenOriginViewHasNoSuperview: baseViewWhenOriginViewHasNoSuperview, baseViewController: baseViewController, completion: completion)
    }
    
    /// Display the popover.
    ///
    /// - Parameter
    ///   - originView: View to be the origin point at where the popover appears.
    ///   - baseViewWhenOriginViewHasNoSuperview: SourceView of popoverPresentationController. Omissible. This view will be used instead of originView.superView when it is nil.
    ///   - baseViewController: Base viewController
    ///   - completion: Action to be performed after the popover appeared. Omissible.
    
    open func appear(originView: UIView, baseViewWhenOriginViewHasNoSuperview: UIView? = nil, baseViewController: UIViewController, completion: VoidHandlerType? = nil) {
        // create navigationController
        guard let navigationController = configureNavigationController(storyboardName: storyboardName, originView: originView, baseViewWhenOriginViewHasNoSuperview: baseViewWhenOriginViewHasNoSuperview, baseViewController: baseViewController ) else {
            return
        }
        self.baseViewController = baseViewController
        
        // configure StringPickerPopoverViewController
        let contentVC = configureContentViewController(navigationController: navigationController)
        navigationController.popoverPresentationController?.delegate = contentVC
        
        // show popover
        baseViewController.present(navigationController, animated: true, completion: {
            completion?()
        })
    }
    
    /// Configure contentViewController of popover
    ///
    /// - Parameter navigationController: Source navigationController.
    /// - Returns: ContentViewController.
    open func configureContentViewController(navigationController: UINavigationController) -> BasePickerPopoverViewController? {
        if let contentViewController = navigationController.topViewController as? BasePickerPopoverViewController {
            contentViewController.anyPopover = self
            self.contentViewController = contentViewController
            return contentViewController
        }
        return nil
    }
    
    /// Close the popover
    ///
    /// - Parameter completion: Action to be performed after the popover disappeared. Omissible.
    open func disappear(completion: VoidHandlerType? = nil) {
        baseViewController?.dismiss(animated: false, completion: completion)
    }
    
    /// Configure navigationController
    ///
    /// - Parameters:
    ///   - storyboardName: Storyboard name
    ///   - originView: View to be the origin point at where the popover appears.
    ///   - baseViewWhenOriginViewHasNoSuperview: SourceView of popoverPresentationController. Omissible.
    ///   - baseViewController: Base viewController
    ///   - permittedArrowDirections: The default value is '.any'. Omissible.
    /// - Returns: The configured navigationController
    open func configureNavigationController(storyboardName: String, originView: UIView, baseViewWhenOriginViewHasNoSuperview: UIView? = nil, baseViewController: UIViewController) -> UINavigationController? {
        var bundle: Bundle
        if let _ = Bundle.main.path(forResource: storyboardName, ofType: "storyboardc"){
            bundle = Bundle.main
        } else {
            bundle = Bundle(for: BasePicker.self)
        }
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
        
        guard let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController else {
            return nil
        }
        
        return configureNavigationController(navigationController: navigationController, originView: originView, baseViewWhenOriginViewHasNoSuperview: baseViewWhenOriginViewHasNoSuperview, baseViewController: baseViewController)
    }
    
    /// Configure navigationController
    ///
    /// - Parameters:
    ///   - navigationController: Navigation controller
    ///   - originView: View to be the origin point at where the popover appears.
    ///   - baseViewWhenOriginViewHasNoSuperview: SourceView of popoverPresentationController. Omissible.
    ///   - baseViewController: Base viewController
    ///   - permittedArrowDirections: The default value is '.any'. Omissible.
    /// - Returns: The configured navigationController
    fileprivate func configureNavigationController(navigationController: UINavigationController, originView: UIView, baseViewWhenOriginViewHasNoSuperview: UIView? = nil, baseViewController: UIViewController) -> UINavigationController? {
        // define using popover
        navigationController.modalPresentationStyle = .popover
        
        // origin
        let presentationController = navigationController.popoverPresentationController
        presentationController?.sourceView = originView.superview ?? baseViewWhenOriginViewHasNoSuperview ?? baseViewController.view
        presentationController?.sourceRect = originView.frame
        
        return navigationController
    }
}


