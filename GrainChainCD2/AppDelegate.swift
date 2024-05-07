//
//  AppDelegate.swift
//  GrainChainCD2
//
//  Created by Daniela Ciciliano on 06/05/24.
//

import Foundation
import UIKit
import GoogleMaps
import CoreData

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        GMSServices.provideAPIKey("AIzaSyAPkYznnCjNTvHrCmF2gPFEenQ0YcPv3I0")
        return true
        
    }
}
    
