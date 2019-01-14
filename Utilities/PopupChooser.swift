//
//  PopupChooser.swift
//  FlightLog2
//
//  Created by Home on 12/01/2018.
//  Copyright © 2018 Phil Diggens. All rights reserved.
//

import Foundation
import UIKit

protocol PopupSelectable {
	var displayString : String { get }
}

extension String : PopupSelectable {
	var displayString : String { return self }
}

fileprivate protocol PopupDelegate {
    func didSelectPaths(paths : [IndexPath])
    func didCancelSelection()
}

class PopupupChooser<T: PopupSelectable> : NSObject, UIPopoverPresentationControllerDelegate, UITableViewDataSource, PopupDelegate {
	private var itemsForSelection : [T]!
	private var handler : (([T]) -> Void)!
    private var sourceView : UIView!
    
    public var title : String!
    public var multipleSelection : Bool = false
    var selectedItems : [Int] = []
	
	func showSelectionPopup(items : [T], sourceView : UIView, updateHandler : @escaping ([T]) -> Void) {
		itemsForSelection = items
		handler = updateHandler
        self.sourceView = sourceView
		
		guard let popoverContent = UIStoryboard(name: "PopupChooser", bundle: nil).instantiateViewController(withIdentifier: "MappingSelection") as? ItemSelectionViewController else {
			return
		}
        popoverContent.multipleSelection = multipleSelection
        
		let navigationController = UINavigationController(rootViewController: popoverContent)
		navigationController.modalPresentationStyle = UIModalPresentationStyle.popover
        
		let popover = navigationController.popoverPresentationController!
		popoverContent.preferredContentSize = CGSize(width: 300, height: 400)
		popover.delegate = self
		
		popover.sourceView = sourceView
		popover.sourceRect = CGRect(x: sourceView.bounds.maxX, y: sourceView.bounds.midY, width: 1, height: 1)
		popoverContent.navigationItem.title = title
		popoverContent.delegate = self
		
		self.sourceView.owningViewController()?.present(navigationController, animated: true, completion: nil)
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return itemsForSelection.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DataTypeSelectionCell", for: indexPath)
		
		cell.textLabel!.text = itemsForSelection[indexPath.row].displayString
        cell.selectionStyle = .none
        if selectedItems.contains(indexPath.row) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

		return cell
	}
    
    func didSelectPaths(paths : [IndexPath]) {
        self.sourceView.owningViewController()?.dismiss(animated: true, completion: nil)
        handler(paths.map { itemsForSelection[$0.row] })
    }
    
    func didCancelSelection() {
        self.sourceView.owningViewController()?.dismiss(animated: true, completion: nil)
    }
}

class ItemSelectionViewController : UIViewController, UITableViewDelegate   {
	fileprivate var delegate : (UITableViewDataSource & PopupDelegate)!
    fileprivate var multipleSelection : Bool!
	
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.dataSource 	= delegate
			tableView.delegate		= self
		}
	}

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if multipleSelection == false {         // If single item dismiss the view controller with this selection
            delegate.didSelectPaths(paths: [indexPath])
            tableView.owningViewController()?.dismiss(animated: true, completion: nil)
        } else {
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editDone(sender:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(editCancel(sender:)))

        tableView.allowsMultipleSelection = multipleSelection
    }
    
    @objc func editDone(sender: UIBarButtonItem) {
        delegate.didSelectPaths(paths: tableView.indexPathsForSelectedRows ?? [])
    }
    
    @objc func editCancel(sender: UIBarButtonItem) {
        delegate.didCancelSelection()
    }
}

extension UIResponder {
	func owningViewController() -> UIViewController? {
		var nextResponser = self
		while let next = nextResponser.next {
			nextResponser = next
			if let vc = nextResponser as? UIViewController {
				return vc
			}
		}
		return nil
	}
}
