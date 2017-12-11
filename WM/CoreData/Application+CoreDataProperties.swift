//
//  Application+CoreDataProperties.swift
//  WM
//
//  Created by Vasyl< on 30.11.17.
//  Copyright © 2017 Vasyl<. All rights reserved.
//
//

import Foundation
import CoreData


extension Application {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Application> {
        return NSFetchRequest<Application>(entityName: "Application")
    }

    @NSManaged public var descriptionArray: [String]
    @NSManaged public var historyArray: [String]
    @NSManaged public var contact: Wallet?

}
