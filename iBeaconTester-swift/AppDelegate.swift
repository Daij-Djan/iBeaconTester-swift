//
//  AppDelegate.swift
//  ibeacon-background-demo-swift
//
//  Created by Dominik Pich on 02/06/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
                            
    var window: UIWindow?
    
    @lazy var ui: MasterViewController =  {
        let navi = self.window!.rootViewController as UINavigationController
        let table = navi.topViewController as MasterViewController
        return table
    }()
    @lazy var locationManager = CLLocationManager()
    var enteredRegions = Array<String>()
    var notifyOnEnter = false
    var notifyOnExit = false
    var rangeOnEnter = false
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        //register for local notifs
        let settings = UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert, categories: nil)
        application.registerUserNotificationSettings(settings)
        
        //give the UI two callbacks to use for managing regions
        self.ui.addNewRegion = self.addNewRegion
        self.ui.editKnownRegion = self.editKnownRegion
        self.ui.removeKnownRegion = self.removeKnownRegion
        self.ui.enableKnownRegion = self.enableKnownRegion
        
        //setup location manager
        self.locationManager.delegate = self
        
        //check options
        if let notifyOnEnter = NSBundle.mainBundle().infoDictionary["NotifyOnEnter"] as? NSNumber {
            self.notifyOnEnter = notifyOnEnter.boolValue
        }
        if let notifyOnExit = NSBundle.mainBundle().infoDictionary["NotifyOnExit"] as? NSNumber {
            self.notifyOnExit = notifyOnExit.boolValue
        }
        if let rangeOnEnter = NSBundle.mainBundle().infoDictionary["RangeOnEnter"] as? NSNumber {
            self.rangeOnEnter = rangeOnEnter.boolValue
        }
        
        //start it - wait for authDidChange delegate
        //self.startMonitoringIfAuthorized()
        
        return true
    }
    
    func application(application: UIApplication!, didReceiveLocalNotification notification: UILocalNotification!) {
        var alert = UIAlertController(title: "", message: notification.alertBody, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.window!.rootViewController.presentViewController(alert, animated: true, completion: nil)
    }

    func locationManager(manager: CLLocationManager!, didDetermineState state: CLRegionState, forRegion region: CLBeaconRegion!) {
        var txt: String?
        var showNotification = false
        var identifier: String = region.identifier
        
        if(state == CLRegionState.Inside) {
            if(!self.enteredRegions.contains(identifier)) {
                txt = "Entered \(region.identifier)"

                //see if we want a notification for this
                showNotification = self.notifyOnEnter
                
                //start ranging if wanted
                if(self.rangeOnEnter) {
                    manager.startRangingBeaconsInRegion(region as CLBeaconRegion)
                }
                
                self.enteredRegions.append(identifier)
            }
        }
        else if(state == CLRegionState.Outside) {
            if(self.enteredRegions.contains(identifier)) {
                txt = "Exited \(region.identifier)"

                //see if we want a notification for this
                showNotification = self.notifyOnExit
                
                manager.stopRangingBeaconsInRegion(region)

                if let index = self.enteredRegions.indexOf(identifier) {
                    self.enteredRegions.removeAtIndex(index)
                }
            }
        }
        else {
            txt = "Unknown state for \(identifier)"
        }

        if(txt) {
            println(txt!)

            if(showNotification) {
                let note = UILocalNotification()
                note.alertBody = txt!
                UIApplication.sharedApplication().presentLocalNotificationNow(note)
            }
        }
        
        //tell UI the enteredRegions -- im aware I could use KVO but ... I dont :D
        let navi = self.window!.rootViewController as UINavigationController
        let table = navi.topViewController as MasterViewController
        table.enteredRegionIdentifiers = self.enteredRegions
    }

    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: AnyObject[]!, inRegion region: CLBeaconRegion!) {
        if(beacons.count > 0) {
            //get strongest
            let beacon = beacons[0] as CLBeacon
            
            let txt = "Ranged \(region.identifier) and strongest: \(beacon.major), \(beacon.minor)"
            println(txt)

            let note = UILocalNotification()
            note.alertBody = txt
            UIApplication.sharedApplication().presentLocalNotificationNow(note)

            manager.stopRangingBeaconsInRegion(region)
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        self.startMonitoringIfAuthorized()
    }
    
    //#pragma mark region management

    var regionsToMonitor : Array<Dictionary<String,AnyObject>>? {
    get {
        //read what we have to monitor
        if let regionsToMonitorD: AnyObject! = NSUserDefaults.standardUserDefaults().objectForKey("Regions") {
            return regionsToMonitorD as Array<Dictionary<String,AnyObject>>!
        }
        
        if let regionsToMonitorB: AnyObject! = NSBundle.mainBundle().objectForInfoDictionaryKey("Regions") {
            return regionsToMonitorB as Array<Dictionary<String,AnyObject>>!
        }
        
        return nil
    }
    set {
        NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "Regions")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    }
    
    func startMonitoringIfAuthorized() {
        let authStatus = CLLocationManager.authorizationStatus()
        switch(authStatus) {
        case CLAuthorizationStatus.Denied:
            var alert = UIAlertController(title: "", message: "Not authorized to look for beacons. Please change in the settings app", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.window!.rootViewController.presentViewController(alert, animated: true, completion: nil)
        case CLAuthorizationStatus.Restricted:
            var alert = UIAlertController(title: "", message: "Access restricted. Not fully authorized to look for beacons. Please change in the settings app", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.window!.rootViewController.presentViewController(alert, animated: true, completion: nil)
        case CLAuthorizationStatus.AuthorizedWhenInUse:
            var alert = UIAlertController(title: "", message: "Only authorized to look for beacons while app is in use", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.window!.rootViewController.presentViewController(alert, animated: true, completion: nil)
            fallthrough
        case CLAuthorizationStatus.NotDetermined:
            //do
            fallthrough
        case CLAuthorizationStatus.Authorized:
            self.startMonitoringAllRegions()
        }
    }
    
    func startMonitoringAllRegions() {
        var knownRegions = Array<CLBeaconRegion>()
        
        //enumerate through
        let regions = self.regionsToMonitor;
        assert(regions, "we should have the RegionsToMonitor here");
        for regionToMonitor in regions! {
            //make CLRegion
            if let clRegion = CLBeaconRegion.fromDictionary(regionToMonitor) {
                //add it
                knownRegions.append(clRegion)

//                //dont monitor dupes
//                let monitoredRegionsSet = self.locationManager.monitoredRegions
//                let monitoredRegions = monitoredRegionsSet.allObjects as Array<CLBeaconRegion>
//                let identifiers = monitoredRegions.getKeyPath("identifier") as Array<String>
//                if(identifiers.contains(clRegion.identifier)) {
//                    continue
//                }
                
                clRegion.notifyEntryStateOnDisplay = true
                
                //monitor
                println("start monitoring \(clRegion.identifier) :: \(clRegion.proximityUUID.UUIDString) \(clRegion.major) \(clRegion.minor)")
                self.locationManager.startMonitoringForRegion(clRegion)
            }
        }
        
        //tell UI the initialy known regions
        self.ui.knownRegions = knownRegions
        
        //give it the monitored ones
        let monitoredRegionsSet = self.locationManager.monitoredRegions
        let monitoredRegions = monitoredRegionsSet.allObjects as Array<CLBeaconRegion>
        let identifiers = monitoredRegions.getKeyPath("identifier") as Array<String>
        self.ui.monitoredRegionIdentifiers = identifiers
    }
    
    //#pragma mark call backs left to do
    
    func addNewRegion(region: CLBeaconRegion, enabled: Bool) -> Bool {
        println(" \(region.toDictionary())")
        return true
    }
    
    func editKnownRegion(oldRegion: CLBeaconRegion, newRegion: CLBeaconRegion, enabled: Bool) -> Bool {
        println(" \(newRegion.toDictionary())")
        return true
    }

    func removeKnownRegion(region: CLBeaconRegion) -> Bool {
        println(" \(region.toDictionary())")
        return true
    }

    func enableKnownRegion(region: CLBeaconRegion, enabled: Bool) -> Bool {
        println(" \(region.toDictionary())")
        return true
    }
}