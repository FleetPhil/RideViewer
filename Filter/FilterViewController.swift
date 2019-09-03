//
//  FilterViewController.swift
//  RideViewer
//
//  Created by West Hill Lodge on 02/09/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var filterTable: UITableView!
    
    // Model - filter parameters
    var filters : [Filter]! {
        didSet {    // Will be set on segue before ViewDidLoad
            // Create a discionary mapping sections to filter groups
            itemsForSelection = Dictionary(grouping: filters, by: { $0.group })    // Section (aka group) : Items
            itemsForSelection.enumerated().forEach({ sectionTitle[$0.offset] = $0.element.key })
        }
    }
 
    // Private properties
    private var itemsForSelection : [String : [Filter]]!
    private var sectionTitle : [Int : String] = [:]

    private var filterCells : [[Filter]] = [[]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterTable.dataSource = self
        filterTable.delegate = self
        
        let sections = Dictionary(grouping: filters, by: { $0.group })
        sections.enumerated().forEach({ filterCells[$0.offset].append($0.element) })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return itemsForSelection.keys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsForSelection[sectionTitle[section]!]!.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitle[section]!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = filterTable.dequeueReusableCell(withIdentifier: "FilterCell") {
            
            // Get the filter that needs to be shown in this row
            let cellFilter = itemsForSelection[sectionTitle[indexPath.section]!]![indexPath.row]

            switch cellFilter.type {
            case .date(let (name, _, value)):
                cell.textLabel?.text        = name
                cell.detailTextLabel?.text  = value.displayString(displayType: .dateOnly, timeZone: nil)
                
            case .range(let (name, range)):
                cell.textLabel?.text        = name
                cell.detailTextLabel?.text  = "\(Int(range.from)) - \(Int(range.to))"

            case .value(let (name, _, value)):
                cell.textLabel?.text        = name
                cell.detailTextLabel?.text  = "\(Int(value))"
                
            case .string(let (name, value)):
                cell.textLabel?.text        = name
                cell.detailTextLabel?.text  = value
            }
            return cell
        }
        fatalError("No cell")
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let filter = itemsForSelection[sectionTitle[indexPath.section]!]![indexPath.row]

        switch filter.type {
        case .date(let (_, _, value)):
            let picker = DatePicker(title: "Date")
                .setSelectedDate(value)
                .setDoneButton(action: { (_, selectedDate) in
                    self.currentDate = selectedDate
                    tableView.reloadData()
                })
            
            picker.appear(originView: filterTable.cellForRow(at: indexPath)!, baseViewController: self)
        case 1:
            let picker = RangePicker(title: "Range")
                .setSelectedRange(currentRange)
                .setThumbTextFunction({ value in
                    return "\(Int(value))"
                })
                .setDoneButton(action: { (_, selectedRange) in
                    self.currentRange = selectedRange
                    tableView.reloadData()
                })
            picker.appear(originView: filterTable.cellForRow(at: indexPath)!, baseViewController: self)
        case 2:
            let picker = ValuePicker(title: "Value")
                .setSelectedValue(currentValue)
                .setValueLimit(lowLimit: 0.0, highLimit: 100.0)
                //                .setThumbTextFunction({ value in
                //                    return "\(Int(value))"
                //                })
                .setDoneButton(action: { (_, selectedValue) in
                    self.currentValue = selectedValue
                    tableView.reloadData()
                })
            picker.appear(originView: filterTable.cellForRow(at: indexPath)!, baseViewController: self)
        default:
            fatalError("Unknown row selected")
        }
    }


}
