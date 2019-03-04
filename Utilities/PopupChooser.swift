//
//  PopupChooser.swift
//  FlightLog2
//
//  Created by Home on 12/01/2018.
//  Copyright © 2018 Phil Diggens. All rights reserved.
//

import Foundation
import UIKit

protocol PopupSelectable : Equatable {
	var displayString : String { get }
    var sortDefaultAscending : Bool { get }
	var filterGroup : String { get }
}

// Provide defaults
extension PopupSelectable {
	var sortDefaultAscending : Bool {
		return false
	}
	var filterGroup : String {
		return ""
	}
}

extension String : PopupSelectable {
	var displayString : String { return self }
}

fileprivate protocol PopupDelegate {
    func didSelectPaths(paths : [IndexPath])
    func didCancelSelection()
}

class PopupupChooser<T: PopupSelectable> : NSObject, UIPopoverPresentationControllerDelegate, UITableViewDataSource, PopupDelegate {
	private var itemsForSelection : [String : [T]]!
	private var sectionNumbers : [Int : String] = [:]
	private var handler : (([T]?) -> Void)!
    private var sourceView : UIView!

    public var title : String!
    public var multipleSelection : Bool = false
	public var selectedItems : [T] = []
	
	func showSelectionPopup(items : [T], sourceView : UIView, updateHandler : @escaping ([T]?) -> Void) -> UIViewController? {
		itemsForSelection = Dictionary(grouping: items, by: { $0.filterGroup })	// Section (aka group) : Items
		var i = 0
		for key in itemsForSelection.keys {
			sectionNumbers[i] = key
			i += 1
		}
		
		handler = updateHandler
        self.sourceView = sourceView
		
		guard let popoverContent = UIStoryboard(name: "PopupChooser", bundle: nil).instantiateViewController(withIdentifier: "MappingSelection") as? ItemSelectionViewController else {
			return nil
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

		return navigationController

//		self.sourceView.owningViewController()?.present(navigationController, animated: true, completion: nil)
	}
	
	// MARK: Table view functions
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return itemsForSelection.keys.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return itemsForSelection[sectionNumbers[section]!]!.count
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let x = sectionNumbers[section]! != "" ? sectionNumbers[section]! : nil
		return x
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DataTypeSelectionCell", for: indexPath)
		let cellValue = itemsForSelection[sectionNumbers[indexPath.section]!]![indexPath.row]
		
		cell.textLabel!.text = cellValue.displayString
        cell.selectionStyle = .none
		
		if selectedItems.contains(cellValue) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

		return cell
	}
	
	// MARK: return functions
    fileprivate func didSelectPaths(paths : [IndexPath]) {
    	self.handler(paths.map { self.itemsForSelection[self.sectionNumbers[$0.section]!]![$0.row] })
    }
    
    fileprivate func didCancelSelection() {
        self.handler(nil)
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
            self.delegate.didSelectPaths(paths: [indexPath])
        } else {
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if multipleSelection {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editDone(sender:)))
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(editCancel(sender:)))
        }

        tableView.allowsMultipleSelection = multipleSelection
    }
    
    @objc func editDone(sender: UIBarButtonItem) {
        delegate.didSelectPaths(paths: tableView.indexPathsForSelectedRows ?? [])
    }
    
    @objc func editCancel(sender: UIBarButtonItem) {
        delegate.didCancelSelection()
    }
}


