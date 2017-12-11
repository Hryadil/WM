//
//  Incomes+CoreDataProperties.swift
//  WM
//
//  Created by Vasyl< on 30.11.17.
//  Copyright © 2017 Vasyl<. All rights reserved.
//
//

import Foundation
import CoreData


extension Incomes {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Incomes> {
        return NSFetchRequest<Incomes>(entityName: "Incomes")
    }

    @NSManaged public var totalAmountIncomes: Double
    @NSManaged public var contact: Wallet?

}
