//
//  Wallet+CoreDataProperties.swift
//  WM
//
//  Created by Vasyl< on 30.11.17.
//  Copyright © 2017 Vasyl<. All rights reserved.
//
//

import Foundation
import CoreData


extension Wallet {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Wallet> {
        return NSFetchRequest<Wallet>(entityName: "Wallet")
    }

    @NSManaged public var balance: Double
    @NSManaged public var name: String?
    @NSManaged public var totalWalletAmount: Double
    @NSManaged public var expensesContact: Expenses?
    @NSManaged public var applicationContact: Application?
    @NSManaged public var incomesContact: Incomes?

}
