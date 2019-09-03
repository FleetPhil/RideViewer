//
//  PopupChooser.swift
//  FlightLog2
//
//  Created by Home on 12/01/2018.
//  Copyright © 2018 Phil Diggens. All rights reserved.
//

import Foundation
import UIKit

enum PopupSelectionValue {
    case typeBool(bool: Bool)
    case typeRange(range: RouteIndexRange)
    case typeDate(date: Date)
    
}

enum PopupRetrievalCriteria {
    case sortCriteria(NSSortDescriptor)
    case filterCriteria(String)
}

struct PopupItem {
    var label: String
    var group: String?
    var value: PopupSelectionValue
    var criteria : PopupRetrievalCriteria
    
    var filterPredicate : NSPredicate? {
        switch self.criteria {
        case .filterCriteria(let filterString):
            switch self.value {
            case .typeBool(let singleValue as Any), .typeDate(let singleValue as Any):
                return NSPredicate(format: filterString, argumentArray: [singleValue])
            case .typeRange(let rangeValue):
                return NSPredicate(format: filterString, argumentArray: [rangeValue.from, rangeValue.to])
            }
       default:
            appLog.error("Called with unexpected PopupItem")
            return nil
        }
    }
    
    static func predicateForFilters(_ filters : [PopupItem]) -> NSCompoundPredicate {
        let filterItems = filters.filter({ if case .filterCriteria = $0.criteria { return true } else { return false }})
        let filterGroups = Dictionary(grouping: filterItems, by: { $0.group }).filter({ $0.key != nil })
        let predicates = filterGroups.map({ NSCompoundPredicate(orPredicateWithSubpredicates: $0.value.map({ $0.filterPredicate ?? NSPredicate(value: false) })) })
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    var sortDescriptor : NSSortDescriptor? {
        switch self.criteria {
        case .sortCriteria(let descriptor):
            return descriptor
        default:
            appLog.error("Called with unexpected PopupItem")
            return nil
        }
    }
    
    static func sortDescriptorForItems(_ items : [PopupItem]) -> NSSortDescriptor? {
        let sortItems = items.filter({ if case .sortCriteria = $0.criteria { return true } else { return false }})
        let trueItem =  sortItems.filter({ if case .typeBool(let boolValue) = $0.value { return boolValue } else { return false }}).first
        return trueItem?.sortDescriptor
    }
}

// Private protocol
fileprivate protocol PopupDelegate {
    func didSelectPaths(paths : [IndexPath])
    func didCancelSelection()
}

// Public interface
class PopupupChooser: NSObject, UIPopoverPresentationControllerDelegate, UITableViewDataSource, PopupDelegate {
    // Public interface
    private var title : String = "Title"
    private var multipleSelection : Bool = false
    
    // Private variables
    private var itemsForSelection : [String : [PopupItem]]!
	private var sectionNumbers : [Int : String] = [:]
	private var handler : (([PopupItem]?) -> Void)!
    private var sourceView : UIView!

    init(title : String) {
        self.title = title
    }
	
    func selectionPopup(items : [PopupItem], multipleSelection: Bool, sourceView : UIView, updateHandler : @escaping ([PopupItem]?) -> Void) -> UIViewController? {
		// If selection is empty do nothing
		if items.count == 0 {
			return nil
		}

        // Group the popup items and assign to the table sections
        itemsForSelection = Dictionary(grouping: items, by: { $0.group ?? ""})    // Section (aka group) : Items
        itemsForSelection.enumerated().forEach({ sectionNumbers[$0.offset] = $0.element.key })
		
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
	}
	
	// MARK: Table view functions
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return itemsForSelection.keys.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return itemsForSelection[sectionNumbers[section]!]!.count
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return sectionNumbers[section]! != "" ? sectionNumbers[section]! : nil
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get the item that needs to be shown in this row
        let cellValue = itemsForSelection[sectionNumbers[indexPath.section]!]![indexPath.row]
        
        // Switch on the type of cell to be shown for this item
        switch cellValue.value {
        case .typeBool(let valueIsTrue):
            let cell = tableView.dequeueReusableCell(withIdentifier: "BoolSelectionCell", for: indexPath) as! PopupBoolPickerCell
            cell.setValueForItem(cellValue)
            if valueIsTrue {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            return cell
 
        case .typeDate:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DateSelectionCell", for: indexPath) as! PopupDatePickerCell
            cell.setValueForItem(cellValue)
            return cell
            
        case .typeRange:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RangeSelectionCell", for: indexPath) as! PopupRangePickerCell
            cell.setValueForItem(cellValue)
            return cell

        }
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editDone(sender:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(editCancel(sender:)))
        
        tableView.allowsMultipleSelection = multipleSelection
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if multipleSelection == false {         //
            self.delegate.didSelectPaths(paths: [indexPath])
        } else {
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        }
    }
    
//    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//        tableView.cellForRow(at: indexPath)?.accessoryType = .none
//    }

    
    @objc func editDone(sender: UIBarButtonItem) {
        delegate.didSelectPaths(paths: tableView.indexPathsForSelectedRows ?? [])
    }
    
    @objc func editCancel(sender: UIBarButtonItem) {
        delegate.didCancelSelection()
    }
}

// Extension to support saving PopupSelectionValue to user defaults
extension PopupSelectionValue: Codable {
    private enum CodingKeys: String, CodingKey {
        case typeBool, typeDate, typeRange
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .typeDate(let value): try container.encode(value, forKey: .typeDate)
        case .typeBool(let value): try container.encode(value, forKey: .typeBool)
        case .typeRange(let value): try container.encode(value, forKey: .typeRange)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let value = try? container.decode(Bool.self, forKey: .typeBool) {
            self = .typeBool(bool: value)
            return
        }
        if let value = try? container.decode(Date.self, forKey: .typeDate) {
            self = .typeDate(date: value)
            return
        }
        if let value = try? container.decode(RouteIndexRange.self, forKey: .typeRange) {
            self = .typeRange(range: value)
            return
        }
        
        appLog.error("Failed to decode PopupSelectionValue \(container)")
        self = .typeBool(bool: false)
        return
    }
}


