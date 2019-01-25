//
//  ImageScrollView.swift
//
//  Created by Phil Diggens on 08/03/2018.
//  Copyright © 2018 Phil Diggens. All rights reserved.
//

import UIKit

protocol ScrollingPhotoViewDelegate : class {
	func photoDidChangeToIndex(_ index : Int)
}

class ScrollingPhotoView : UIView, UIScrollViewDelegate {
	private var scrollView : UIScrollView!
	private var pageControl : UIPageControl!
	
	// MARK: Delegate
	weak var delegate : ScrollingPhotoViewDelegate?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupView()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setupView()
	}
	
	private func setupView() {
		scrollView = UIScrollView()
		scrollView.isPagingEnabled = true
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.delegate = self
		self.addSubview(scrollView)
		
		pageControl = UIPageControl()
		pageControl.frame = CGRect(x: 0, y: self.bounds.height - 20, width: self.bounds.width, height: 10)
		self.addSubview(pageControl)
	}
	
	private var imageDict : [String:Int] = [:]			// Identifier, index
	
	func addImage(image : UIImage?, identifier : String) {
		var atIndex : Int? = imageDict[identifier]
		
		guard image != nil else { return }

		if atIndex == nil {			// No index for the supplied identifier
			imageDict[identifier] = imageDict.count
			atIndex = imageDict[identifier]
			scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
			scrollView.contentSize = CGSize(width: CGFloat(imageDict.count) * self.frame.width, height: self.frame.height)
		}
		
		// Retrieve a photo view
		if let photoView = Bundle.main.loadNibNamed("PhotoView", owner: self, options: nil)?.first as? PhotoView {
			photoView.photoImage.image = image!
			photoView.contentMode = .scaleAspectFit
			photoView.frame = CGRect(x: self.frame.width * CGFloat(atIndex!), y: 0, width: self.frame.width, height: self.frame.height)
			scrollView.addSubview(photoView)
			
			pageControl.numberOfPages = imageDict.count
			pageControl.currentPage = 0
			pageControl.frame = CGRect(x: 0, y: self.bounds.height - 20, width: self.bounds.width, height: 10)
			self.bringSubviewToFront(pageControl)
		}
		
		// If this is the first image set the current image index
		if imageDict.count == 1 {		// First image
			self.delegate?.photoDidChangeToIndex(0)
		}
	}
	
	// MARK: Scrollview delegate
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let pageIndex = Int(round(scrollView.contentOffset.x / self.frame.width))
		if pageIndex != pageControl.currentPage {	// page has changed
			pageControl.currentPage = pageIndex
			self.delegate?.photoDidChangeToIndex(pageIndex)
		}
	}
}


class PhotoView : UIView {
	@IBOutlet weak var photoImage: UIImageView!
}

