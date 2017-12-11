//
//  Expenses+CoreDataProperties.swift
//  WM
//
//  Created by Vasyl< on 30.11.17.
//  Copyright © 2017 Vasyl<. All rights reserved.
//
//

import Foundation
import CoreData


extension Expenses {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expenses> {
        return NSFetchRequest<Expenses>(entityName: "Expenses")
    }

    @NSManaged public var amountExpensesOnDate: [String : Double]
    @NSManaged public var totalAmountExpenses: Double
    @NSManaged public var contact: Wallet?

}
