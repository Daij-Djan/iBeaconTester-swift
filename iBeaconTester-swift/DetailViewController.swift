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
    var titleEditable: Bool = false {
    didSet {
        // Update the view.
        self.tableView.reloadData()
    }
    }
    var region: CLBeaconRegion? {
    didSet {
        // Update the view.
        self.tableView.reloadData()
    }
    }
    var enabled:Bool = false {
    didSet {
        // Update the view.
        self.tableView.reloadData()
    }
    }

    var dismissHandler: ((CLBeaconRegion, Bool) -> Void)?
    
    override func viewDidDisappear(animated: Bool) {
        if self.dismissHandler {
            let r = self.region
            assert(r, "region must be there")
            self.dismissHandler!(r!, self.enabled)
        }
    }
    override func tableView(tableView: UITableView!, willDisplayCell cell: UITableViewCell!, forRowAtIndexPath indexPath: NSIndexPath!) {
        //set value
        if let r = self.region {
            switch(cell.tag) {
            case 1:
                let textfield = cell.viewWithTag(10) as UITextField
                textfield.text = r.identifier
            case 2:
                let textfield = cell.viewWithTag(10) as UITextField
                textfield.text = r.proximityUUID.UUIDString
            case 3:
                let textfield = cell.viewWithTag(10) as UITextField
                textfield.text = r.major ? r.major.stringValue : "-1"
            case 4:
                let textfield = cell.viewWithTag(10) as UITextField
                textfield.text = r.minor ? r.minor.stringValue : "-1"
            case 5:
                let uiswitch = cell.viewWithTag(10) as UISwitch
                uiswitch.on = self.enabled
            default:
                println("unexpected")
            }
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
        var dict = self.region ? self.region!.toDictionary() : Dictionary<String, AnyObject>()
        var string = sender.text
        if(!string) {
            string = ""
        }
        dict["identifier"] = string
        self.region = CLBeaconRegion.fromDictionary(dict)
    }
    @IBAction func enabledChanged(sender : UISwitch) {
        self.enabled = sender.on
    }
    @IBAction func uuidChanged(sender : UITextField) {
        var dict = self.region ? self.region!.toDictionary() : Dictionary<String, AnyObject>()
        let string = sender.text
        let uuid = NSUUID(UUIDString: sender.text)
        dict["identifier"] = uuid
        self.region = CLBeaconRegion.fromDictionary(dict)
    }
    @IBAction func majorChanged(sender : UITextField) {
        var dict = self.region ? self.region!.toDictionary() : Dictionary<String, AnyObject>()
        var string = sender.text
        if(!string) {
            string = ""
        }
        if(!string.isEmpty && string.toInt() >= 0) {
            dict["major"] = NSNumber(integer: string.toInt()!)
        }
        self.region = CLBeaconRegion.fromDictionary(dict)
    }
    @IBAction func minorChanged(sender : UITextField) {
        var dict = self.region ? self.region!.toDictionary() : Dictionary<String, AnyObject>()
        var string = sender.text
        if(!string) {
            string = ""
        }
        if(!string.isEmpty && string.toInt() >= 0) {
            dict["minor"] = NSNumber(integer: string.toInt()!)
        }
        self.region = CLBeaconRegion.fromDictionary(dict)
    }
}

