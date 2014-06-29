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

    var knownRegionDicts : Array<Dictionary<String,AnyObject>>? {
    get {
        //read what we have to monitor
        if let knownRegionDictsD: AnyObject! = NSUserDefaults.standardUserDefaults().objectForKey("Regions") {
            assert(self.monitoredRegionIdentifiers, "when regions are there, monitoredIdentifiers should be too")
            return knownRegionDictsD as Array<Dictionary<String,AnyObject>>!
        }
        
        if let knownRegionDictsB: AnyObject! = NSBundle.mainBundle().objectForInfoDictionaryKey("Regions") {
            return knownRegionDictsB as Array<Dictionary<String,AnyObject>>!
        }
        
        return nil
    }
    set {
        NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "Regions")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    }
    
    var monitoredRegionIdentifiers : Array<String>? {
    get {
        if let monitoredRegionIdentifiersD: AnyObject! = NSUserDefaults.standardUserDefaults().objectForKey("MonitoredIDs") {
            println("\(monitoredRegionIdentifiersD)")
            return monitoredRegionIdentifiersD as Array<String>!
        }
        
        return nil
    }
    set {
        println(newValue)
        NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "MonitoredIDs")
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
        var monitoredIdentifiers = self.monitoredRegionIdentifiers
        
        //enumerate through
        let regions = self.knownRegionDicts;
        assert(regions, "we should have the knownRegionDicts here");
        for regionToMonitor in regions! {
            //make CLRegion
            if let clRegion = CLBeaconRegion.fromDictionary(regionToMonitor) {
                //add it
                knownRegions.append(clRegion)
                
                //skip turned off
                if monitoredRegionIdentifiers && !monitoredRegionIdentifiers!.contains(clRegion.identifier) {
                    var uuidString:AnyObject! = regionToMonitor["uuid"]
                    println("skip region \(uuidString) as it isnt enabled")
                    continue;
                }
                
                clRegion.notifyEntryStateOnDisplay = true
                
                //monitor
                println("start monitoring \(clRegion.identifier) :: \(clRegion.proximityUUID.UUIDString) \(clRegion.major) \(clRegion.minor)")
                self.locationManager.startMonitoringForRegion(clRegion)
            }
        }
        
        //tell UI the initialy known regions
        self.ui.knownRegions = knownRegions
        
        //give it the monitored ones
        if(!monitoredIdentifiers) {
            let helpIdentifiers = knownRegions.getKeyPath("identifier") as Array<String>
            self.ui.monitoredRegionIdentifiers = helpIdentifiers
        }
        else {
            self.ui.monitoredRegionIdentifiers = monitoredIdentifiers!
        }
    }
}

//MARK: UIApplicationDelegate
extension AppDelegate {
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
    
    func applicationWillTerminate(application: UIApplication!) {
        
    }
}

//MARK: CLLocationManagerDelegate
extension AppDelegate {
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
    
}

//MARK: callbacks from UI
extension AppDelegate {
    func addNewRegion(region: CLBeaconRegion, enabled: Bool) -> Bool {
        //update the UI with the now known regions
        var knownRegions = self.ui.knownRegions
        knownRegions.append(region)
        self.ui.knownRegions = knownRegions
        
        //update the settings
        let knownRegionsDicts = knownRegions.getKeyPath("toDictionary") as Array<Dictionary<String, AnyObject>>
        self.knownRegionDicts = knownRegionsDicts
        
        //update its state
        self.enableKnownRegion(region, enabled: enabled)
        
        return true
    }
    
    func editKnownRegion(oldRegion: CLBeaconRegion, newRegion: CLBeaconRegion, enabled: Bool) -> Bool {
        //disable old
        self.locationManager.stopMonitoringForRegion(oldRegion)
        
        //update the UI with the now known regions
        var knownRegions = self.ui.knownRegions
        let index = knownRegions.indexOf(oldRegion)
        assert(index, "oldRegion must be in array")
        knownRegions[index!] = newRegion
        self.ui.knownRegions = knownRegions
        
        //update the settings
        let knownRegionsDicts = knownRegions.getKeyPath("toDictionary") as Array<Dictionary<String, AnyObject>>
        self.knownRegionDicts = knownRegionsDicts
        
        //update its state
        self.enableKnownRegion(newRegion, enabled: enabled)
        
        return true
    }

    func removeKnownRegion(region: CLBeaconRegion) -> Bool {
        //update its state
        self.enableKnownRegion(region, enabled: false)

        //update the UI with the now known regions
        var knownRegions = self.ui.knownRegions
        let index = knownRegions.indexOf(region)
        assert(index, "region must be in array")
        knownRegions.removeAtIndex(index!)
        self.ui.knownRegions = knownRegions
        
        //update the settings
        let knownRegionsDicts = knownRegions.getKeyPath("toDictionary") as Array<Dictionary<String, AnyObject>>
        self.knownRegionDicts = knownRegionsDicts
        
        return true
    }

    func enableKnownRegion(region: CLBeaconRegion, enabled: Bool) -> Bool {
        //monitor it or stop it as needed
        self.locationManager.stopMonitoringForRegion(region)
        if enabled {
            println("start monitoring \(region.identifier) :: \(region.proximityUUID.UUIDString) \(region.major) \(region.minor)")
            self.locationManager.startMonitoringForRegion(region)
        }

        //update the UI with the now monitored ids
        var identifiers = self.ui.monitoredRegionIdentifiers
        println("\(identifiers)")
        if enabled {
            if !identifiers.contains(region.identifier) {
                identifiers.append(region.identifier)
            }
        }
        else {
            if identifiers.contains(region.identifier) {
                let idx = identifiers.indexOf(region.identifier)
                identifiers.removeAtIndex(idx!)
            }
        }
        self.ui.monitoredRegionIdentifiers = identifiers
        
        //update the settings
        self.monitoredRegionIdentifiers = identifiers

        return true
    }
}