//
//  MasterViewController.swift
//  a
//
//  Created by Dominik Pich on 04/06/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import UIKit
import CoreLocation

class MasterViewController: UITableViewController {
    var knownRegions:Array<CLBeaconRegion> = Array<CLBeaconRegion>() {
    didSet {
        self.tableView.reloadData()
    }
    }
    
    var monitoredRegionIdentifiers: Array<String> = Array<String>() {
    didSet {
        self.tableView.reloadData()
    }
    }
    
    var enteredRegionIdentifiers: Array<String> = Array<String>() {
    didSet {
        self.tableView.reloadData()
    }
    }
    
    //i'd do this as a protocol but I wanted to try out function pointers
    var addNewRegion: ((CLBeaconRegion, Bool) -> Bool)?
    var editKnownRegion: ((CLBeaconRegion, CLBeaconRegion, Bool) -> Bool)?
    var removeKnownRegion: ((CLBeaconRegion) -> Bool)?
    var enableKnownRegion: ((CLBeaconRegion, Bool) -> Bool)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject")
        self.navigationItem.rightBarButtonItem = addButton
    }
    
    func insertNewObject() {
        self.performSegueWithIdentifier("InsertRegion", sender: self)
    }

    // #pragma mark - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EditRegion" {
            let indexPath = self.tableView.indexPathForSelectedRow()
            let region = self.knownRegions[indexPath.row]
            let identifier: String = region.identifier
            let isMonitored = self.monitoredRegionIdentifiers.contains(identifier)

            let detailVC = segue.destinationViewController as DetailViewController
            detailVC.region = region
            detailVC.enabled = isMonitored
            detailVC.dismissHandler = self.regionEdited(region)
        }
        else if segue.identifier == "InsertRegion" {
            let sel: Selector = Selector("dismiss")
            var doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action:sel)
            let naviVC = segue.destinationViewController as UINavigationController
            let detailVC = naviVC.topViewController as DetailViewController
            detailVC.navigationItem.title = "New Region"
            detailVC.navigationItem.rightBarButtonItem = doneButton
            detailVC.titleEditable = true
            detailVC.enabled = true
            detailVC.dismissHandler = self.regionAdded;
        }
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // #pragma mark - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.knownRegions.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let region = self.knownRegions[indexPath.row]
        
        var cellName = "Cell"
        if(region.major) {
            if(region.minor) {
                cellName = "CellWithMajorMinor"
            }
            else {
                cellName = "CellWithMajor"
            }
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellName, forIndexPath: indexPath) as UITableViewCell

        let lregion = cell.viewWithTag(1) as UILabel
        let luuid = cell.viewWithTag(2) as UILabel
        lregion.text = region.identifier
        luuid.text = region.proximityUUID.UUIDString

        if(region.major) {
            let lmajor = cell.viewWithTag(3) as UILabel
            lmajor.text = region.major ? region.major.description : ""

            if(region.minor) {
                let lminor = cell.viewWithTag(4) as UILabel
                lminor.text = region.minor ? region.minor.description : ""
            }
        }
        
        return cell
    }

    override func tableView(tableView: UITableView!, willDisplayCell cell: UITableViewCell!, forRowAtIndexPath indexPath: NSIndexPath!) {
        let region = self.knownRegions[indexPath.row]
        let identifier: String = region.identifier
        
        //check it if it is monitored
        let isMonitored = self.monitoredRegionIdentifiers.contains(identifier)
        cell.accessoryType = isMonitored ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
        
        cell.backgroundColor = UIColor(white: 0.9, alpha: 1);
        if(isMonitored) {
            //make it green if entered
            let isEntered = self.enteredRegionIdentifiers.contains(identifier)
            cell.backgroundColor = isEntered ? UIColor.greenColor().colorWithAlphaComponent(0.5) : UIColor.whiteColor()
        }
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let region = self.knownRegions[indexPath.row]
        if editingStyle == .Delete {
            //let callback do it all
            assert(self.removeKnownRegion, "self.removeKnownRegion must be non-nil")
            self.removeKnownRegion!(region)
        }
    }

    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
//        if(tableView.editing) {
            self.performSegueWithIdentifier("EditRegion", sender: self)
//        }
//        else {
//            let region = self.knownRegions[indexPath.row]
//            let identifier: String = region.identifier
//            let isMonitored = self.monitoredRegionIdentifiers.contains(identifier)
//            let callback do it all
//            assert(self.enableKnownRegion, "self.enableKnownRegion must be non-nil")
//            self.enableKnownRegion!(region, !isMonitored)
//        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    //#pragma mark callbacks

    func regionAdded(newRegion:CLBeaconRegion, enabled:Bool) -> Void {
        self.addNewRegion!(newRegion, enabled)
    }

    func regionEdited(oldRegion:CLBeaconRegion) -> (CLBeaconRegion, Bool) -> Void {
        func callback(newRegion:CLBeaconRegion, enabled:Bool) -> Void {
            //let callback do it all
            assert(self.editKnownRegion, "self.editKnownRegion must be non-nil")
            self.editKnownRegion!(oldRegion, newRegion, enabled)
        }
        
        return callback
    }
}

