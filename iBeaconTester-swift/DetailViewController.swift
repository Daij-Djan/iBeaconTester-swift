//
//  DetailViewController.swift
//  a
//
//  Created by Dominik Pich on 05/06/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import UIKit
import CoreLocation

class DetailViewController: UITableViewController {
    var regionTitle : String?
    var regionUUIDString : String?
    var regionMajorNumber : NSNumber?
    var regionMinorNumber : NSNumber?

    var regionEnabled = false

    var titleEditable: Bool = false {
    didSet {
        // Update the view.
        self.tableView.reloadData()
    }
    }
    
    var region: CLBeaconRegion? {
    get {
        //parts to dict
        var dict = Dictionary<String, AnyObject>()
        if self.regionTitle {
            dict["identifier"] = self.regionTitle
        }
        if self.regionUUIDString {
            dict["uuid"] = self.regionUUIDString
        }
        if self.regionMajorNumber {
            dict["major"] = self.regionMajorNumber
        }
        if self.regionMinorNumber {
            dict["minor"] = self.regionMinorNumber
        }
        println(dict)
        return CLBeaconRegion.fromDictionary(dict)
    }
    set {
        if let r = newValue {
            self.regionTitle = r.identifier
            self.regionUUIDString = r.proximityUUID.UUIDString
            self.regionMajorNumber = r.major
            self.regionMinorNumber = r.minor
        }
        else {
            self.regionTitle = nil
            self.regionUUIDString = nil
            self.regionMajorNumber = nil
            self.regionMinorNumber = nil
        }
        
        // Update the view.
        self.tableView.reloadData()
    }
    }
    
    var enabled:Bool {
    get {
        return self.regionEnabled
    }
    set {
        self.regionEnabled = newValue
        
        // Update the view.
        self.tableView.reloadData()
    }
    }

    var dismissHandler: ((CLBeaconRegion, Bool) -> Void)?
    
    override func viewWillDisappear(animated: Bool) {
        if self.dismissHandler {
            let r = self.region
            assert(r, "region must be there")
            self.dismissHandler!(r!, self.enabled)
        }
    }
    override func tableView(tableView: UITableView!, willDisplayCell cell: UITableViewCell!, forRowAtIndexPath indexPath: NSIndexPath!) {
        //set value
        switch(cell.tag) {
        case 1:
            let textfield = cell.viewWithTag(10) as UITextField
            textfield.text = self.regionTitle ? self.regionTitle : ""
        case 2:
            let textfield = cell.viewWithTag(10) as UITextField
            textfield.text = self.regionUUIDString ? self.regionUUIDString : ""
        case 3:
            let textfield = cell.viewWithTag(10) as UITextField
            textfield.text = self.regionMajorNumber ? self.regionMajorNumber!.stringValue : "-1"
        case 4:
            let textfield = cell.viewWithTag(10) as UITextField
            textfield.text = self.regionMinorNumber ? self.regionMinorNumber!.stringValue : "-1"
        case 5:
            let uiswitch = cell.viewWithTag(10) as UISwitch
            uiswitch.on = self.regionEnabled
        default:
            println("unexpected")
        }
       
        //update readonly state
        if cell.tag == 1 {
            let textfield = cell.viewWithTag(10) as UITextField
            println(self.titleEditable)
            textfield.textColor = self.titleEditable ? UIColor.blackColor() : UIColor.grayColor()
            textfield.enabled = self.titleEditable
        }
        
        //update can monitor
        if cell.tag == 5 {
            let canMonitor = CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion)
            cell.backgroundColor = UIColor(white: canMonitor ? 1 : 0.9, alpha: 1)
        }
    }
    
    //#pragma mark: IB
    
    @IBAction func titleChanged(sender : AnyObject) {
        self.regionTitle = sender.text
    }
    @IBAction func enabledChanged(sender : UISwitch) {
        self.regionEnabled = sender.on
    }
    @IBAction func uuidChanged(sender : UITextField) {
        self.regionUUIDString = sender.text
    }
    @IBAction func majorChanged(sender : UITextField) {
        self.regionMajorNumber = nil
        if !sender.text.isEmpty {
            if(sender.text != "-1") {
                self.regionMajorNumber = NSNumber(int: sender.text.bridgeToObjectiveC().intValue)
            }
        }
    }
    @IBAction func minorChanged(sender : UITextField) {
        self.regionMinorNumber = nil
        if !sender.text.isEmpty {
            if(sender.text != "-1") {
                self.regionMinorNumber = NSNumber(int: sender.text.bridgeToObjectiveC().intValue)
            }
        }
    }
}

