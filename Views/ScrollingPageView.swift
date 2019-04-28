//
//  ScrollingPageView.swift
//  ScrollingContainer
//
//  Created by Home on 24/04/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class ScrollingPageView: UIView, UIScrollViewDelegate {
	
	/// Function called when page changes (with new page number)
	var viewChangedCallback : ((Int)->Void)? = nil

	/// Return the type of the specified page
	func viewTypeForPage(_ page : Int)->Any? {
		guard page >= 0, page < views.count else { return nil }
		return views[page].1
	}
	
	private var scrollView : UIScrollView!
	private var stackView : UIStackView!
	private var views : [(UIView, Any?)] = []
	
	@discardableResult
	func addScrollingView(_ view : UIView, ofType: Any?, horizontal : Bool) -> UIView {
		if scrollView == nil {
			scrollView = createScrollView()
			stackView = createStackView(horizontal)
		}
		views.append((addView(view),ofType))
		return views.last!.0
	}
	
	private func createScrollView() -> UIScrollView {
		let scrollView = UIScrollView()
		self.addSubview(scrollView)
		
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			scrollView.topAnchor.constraint(equalTo: self.topAnchor),
			scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
			])
		scrollView.isPagingEnabled = true
		scrollView.delegate = self
		
		return scrollView
	}
	
	private func createStackView(_ horizontal : Bool) -> UIStackView {
		let stackView = UIStackView()
		stackView.axis = horizontal ? .horizontal : .vertical
		scrollView.addSubview(stackView)

		stackView.translatesAutoresizingMaskIntoConstraints = false
		
		let whConstraint = horizontal ? stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor) : stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
		
		NSLayoutConstraint.activate([
			stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
			stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
			stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
			stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
			whConstraint
			])
		
		return stackView
	}
	
	private func addView(_ view : UIView) -> UIView {
		stackView.addArrangedSubview(view)

		view.translatesAutoresizingMaskIntoConstraints = false
		
		if stackView.axis == .vertical {
			NSLayoutConstraint.activate([view.heightAnchor.constraint(equalTo: scrollView.heightAnchor)])
		} else {
			NSLayoutConstraint.activate([view.widthAnchor.constraint(equalTo: scrollView.widthAnchor)])
		}
		
		return view
	}
	
	
	// MARK: Scrollview delegate
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		viewChangedCallback?(Int(scrollView.contentOffset.y / scrollView.frame.size.height))
	}
	
}
