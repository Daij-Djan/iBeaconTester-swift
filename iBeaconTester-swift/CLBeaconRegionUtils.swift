//
//  CLBeaconRegionUtils.swift
//  ibeacon-background-demo-swift
//
//  Created by Dominik Pich on 05/06/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import CoreLocation

extension CLBeaconRegion {
    class func fromDictionary(dictionary:Dictionary<String, AnyObject>) -> CLBeaconRegion? {
        if(!dictionary["uuid"]) {
            return nil;
        }
        
        //read dict
        var uuidString:String = dictionary["uuid"] as String!
        let identifier:String = dictionary["identifier"] as String!
        let major: Int? = dictionary["major"] ? dictionary["major"]!.integerValue : nil
        let minor: Int? = dictionary["minor"] ? dictionary["minor"]!.integerValue : nil
        
        let uuid : NSUUID? = NSUUID(UUIDString: uuidString)
        if(!uuid) {
            return nil
        }
        
        //make CLRegion
        var clRegion: CLBeaconRegion
        if let ma = major {
            if  let mi = minor {
                clRegion = CLBeaconRegion(proximityUUID: uuid,
                    major: CLBeaconMajorValue(ma),
                    minor: CLBeaconMinorValue(mi),
                    identifier: identifier)
            }
            else {
                clRegion = CLBeaconRegion(proximityUUID: uuid,
                    major: CLBeaconMajorValue(ma),
                    identifier: identifier)
            }
        }
        else {
            clRegion = CLBeaconRegion(proximityUUID: uuid,
                identifier: identifier)
        }
        
        return clRegion;
    }
}
