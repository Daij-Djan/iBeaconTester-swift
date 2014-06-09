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

    var editKnownRegion: ((CLBeaconRegion, CLBeaconRegion, Bool) -> Bool)?

    override func tableView(tableView: UITableView!, willDisplayCell cell: UITableViewCell!, forRowAtIndexPath indexPath: NSIndexPath!) {
        //set value
        if let r = region {
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
            textfield.textColor = self.titleEditable ? UIColor.blackColor() : UIColor.grayColor();
            textfield.enabled = self.titleEditable
        }
    }
}

