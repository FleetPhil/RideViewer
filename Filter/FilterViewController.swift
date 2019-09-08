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
            // Create an array of filters by [Section][Row]
            filterCells = twoDimensionalArray(filters, sameGroup: { $0.group == $1.group })
        }
    }
    
    // Delegate
    var delegate : FilterDelegate?
 
    // Private properties
    private var filterCells = [[Filter]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterTable.dataSource = self
        filterTable.delegate = self
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Flatten the array of filters and return to the delegate
        delegate?.newFilters(filterCells.flatMap({ $0 }))
    }
    
    // Reset all the filter values to the limits
    @IBAction func resetButtonPressed(_ sender: Any) {
        filters = filters.map { filter in
            Filter(name: filter.name,
                   group: filter.group,
                   property: filter.property,
                   comparison: filter.comparison,
                   filterValue: filter.filterLimit ?? filter.filterValue,
                   filterLimit: filter.filterLimit,
                   displayFormatter: filter.displayFormatter)
        }
        filterTable.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return filterCells.count            // Numer of top level groups
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterCells[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return filterCells[section][0].group
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = filterTable.dequeueReusableCell(withIdentifier: "FilterCell") {
            
            // Get the filter that needs to be shown in this row
            let filter = filterCells[indexPath.section][indexPath.row]

            switch filter.filterValue {
            case .dateValue(let value):
                cell.textLabel?.text        = filter.name
                cell.detailTextLabel?.text  = value.displayString(displayType: .dateOnly, timeZone: nil)
                
            case .rangeValue(let range):
                cell.textLabel?.text        = filter.name
                cell.detailTextLabel?.text  = filter.displayFormatter(range.from) + " - " + filter.displayFormatter(range.to)

            case .doubleValue(let value):
                cell.textLabel?.text        = filter.name
                cell.detailTextLabel?.text  = filter.displayFormatter(value)
                
            case .stringValue(let value):
                cell.textLabel?.text        = filter.name
                cell.detailTextLabel?.text  = value
            }
            return cell
        }
        fatalError("No cell")
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let filter = filterCells[indexPath.section][indexPath.row]

        switch filter.filterValue {
        case .dateValue(let value):
            let picker = DatePicker(title: "Date")
                .setSelectedDate(value)
                .setDoneButton(action: { (_, selectedDate) in
                    self.filterCells[indexPath.section][indexPath.row].filterValue = .dateValue(selectedDate)
                    tableView.reloadData()
                })
            
            picker.appear(originView: filterTable.cellForRow(at: indexPath)!, baseViewController: self)
        case .rangeValue(let range):
            guard case .rangeValue(let limit)? = filter.filterLimit else { fatalError("No limit for Range") }
            let picker = RangePicker(title: "Range")
                .setSelectedRange(RangePicker.PickerRange(lowValue: range.from, highValue: range.to))
                .setRangeLimit(RangePicker.PickerRange(lowValue: limit.from, highValue: limit.to))
                .setThumbTextFunction({ value in
                    return "\(Int(value))"
                })
                .setDoneButton(action: { (_, selectedRange) in
                    self.filterCells[indexPath.section][indexPath.row].filterValue = .rangeValue(RouteIndexRange(from: selectedRange.lowValue, to: selectedRange.highValue))
                    tableView.reloadData()
                })
            picker.appear(originView: filterTable.cellForRow(at: indexPath)!, baseViewController: self)
        case .doubleValue(let value):
            let picker = ValuePicker(title: "Value")
                .setSelectedValue(value)
                .setValueLimit(lowLimit: 0.0, highLimit: 100.0)
                .setDoneButton(action: { (_, selectedValue) in
                    self.filterCells[indexPath.section][indexPath.row].filterValue = .doubleValue(selectedValue)
                    tableView.reloadData()
                })
            picker.appear(originView: filterTable.cellForRow(at: indexPath)!, baseViewController: self)
        default:
            fatalError("Unknown row selected")
        }
    }

}
