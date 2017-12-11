//
//  Variables.swift
//  WM
//
//  Created by Vasyl< on 30.11.17.
//  Copyright © 2017 Vasyl<. All rights reserved.
//

import UIKit
import CoreData

// roundTo подвоює до двох десяткових знаків
extension Double {
    func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

class Variables: UIViewController {

    // CoreData підтримує цей масив навіть тоді, коли програма не працює
    static var walletArray = [Wallet]()
    static var applicationArray = [Application]()
    static var expensesArray = [Expenses]()
    static var incomesArray = [Incomes]()
    
    // Поточний індекс завжди ініціалізується на 0, коли відкривається програма
    static var currentIndex = 0
    
    // Ця функція виводить дані з CoreData
    class func getData() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        do {
            walletArray = try context.fetch(Wallet.fetchRequest())
            applicationArray = try context.fetch(Application.fetchRequest())
            expensesArray = try context.fetch(Expenses.fetchRequest())
            incomesArray = try context.fetch(Incomes.fetchRequest())
            
        }
        catch {
            print("Fetching Failed")
        }
    }
    
    // Перетворює в Double число і додає знак $/₴ на початок
    class func numFormat(myNum: Double) -> String {
        let largeNumber = Double(myNum)
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        return numberFormatter.string(from: NSNumber(value: largeNumber))!
    }
    
    // Якщо ім'я ще не існує, поверніть аргумент
    // Якщо ім'я існує додаємо (num ++) тобто (1) і т.д.
    class func createName(myName: String, myNum: Int) -> String {
        // Тимчасові змінні для тестування
        var testName = myName
        var testNum = myNum
        
        // Якщо testName вже існує, збільшимо значення testNum і повтороримо спробу з модифікованим іменем testName
        while nameExistsAlready(str: testName) == true {
            testNum += 1
            testName = myName + " (\(testNum))"
        }
        
        // Повертає назву тесту, коли ми знаємо, що він ще не існує
        return testName
    }
    
    // Повертає true, якщо ім'я вже існує
    class func nameExistsAlready(str: String) -> Bool {
        // Якщо масив не порожній
        if walletArray.isEmpty == false {
            for i in 0...(walletArray.count - 1) {
                if str == walletArray[i].name {
                    return true
                }
            }
        }
        
        // Якщо масив порожній, просто повернути false, не може бути повторюваного імені
        return false
    }
    
    // Повертає true, якщо журнал історії кожного гаманця порожній
    class func isAllHistoryEmpty() -> Bool {
        for i in 0...Variables.applicationArray.count - 1 {
            if Variables.applicationArray[i].historyArray.isEmpty == false {
                return false
            }
        }
        return true
    }
    
    // Отримуємо поточну дату в будь-якому форматі на основі аргументу
    class func todaysDate(format: String) -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    // Витягає за останні 7 днів чи 31 день масив рядків
    class func pastInterval(interval: String) -> [String] {
        var size = 7
        if (interval == "Month") {
            size = 31
        }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var dayIndex = cal.date(byAdding: .day, value: ((size - 1) * -1), to: today)
        var days = [String]()
        
        for _ in 1 ... size {
            let day = cal.component(.day, from: dayIndex!)
            let month = cal.component(.month, from: dayIndex!)
            let stringDate = String(month) + "/" + String(day)
            days.append(stringDate)
            dayIndex = cal.date(byAdding: .day, value: 1, to: dayIndex!)!
        }
        
        return days
    }
    
    //Захоплення останніх X місяців у масив String
    class func pastXMonths(X: Int) -> [String] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var monthIndex = cal.date(byAdding: .month, value: ((X - 1) * -1), to: today)
        var months = [String]()
        
        for _ in 1 ... X {
            let month = cal.component(.month, from: monthIndex!)
            var monthString = ""
            
            switch(month) {
            case 1:
                monthString = "Jan"
                break;
            case 2:
                monthString = "Feb"
                break;
            case 3:
                monthString = "Mar"
                break;
            case 4:
                monthString = "Apr"
                break;
            case 5:
                monthString = "May"
                break;
            case 6:
                monthString = "Jun"
                break;
            case 7:
                monthString = "Jul"
                break;
            case 8:
                monthString = "Aug"
                break;
            case 9:
                monthString = "Sep"
                break;
            case 10:
                monthString = "Oct"
                break;
            case 11:
                monthString = "Nov"
                break;
            case 12:
                monthString = "Dec"
                break;
            default:
                monthString = "Error"
                break;
            }
            
            months.append(monthString)
            monthIndex = cal.date(byAdding: .month, value: 1, to: monthIndex!)!
        }
        
        return months
    }
    
    // Витягає суму, витрачену протягом останніх 7 днів у подвійний масив
    class func amountSpentInThePast(interval: String) -> [Double] {
        var size = 7;
        if (interval == "Month") {
            size = 31
        }
        
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var startingPoint = cal.date(byAdding: .day, value: (size - 1) * -1, to: today)
        
        var amountExpensesArray = [Double]()
        
        for _ in 1 ... size {
            // Створення компонента дня
            let day = cal.component(.day, from: startingPoint!)
            var dayString = String(day)
            if dayString.count == 1 {
                dayString = "0" + dayString
            }
            
            // Створення компонента місяця
            let month = cal.component(.month, from: startingPoint!)
            var monthString = String(month)
            if monthString.count == 1 {
                monthString = "0" + monthString
            }
            
            // Створення компонента року
            let year = cal.component(.year, from: startingPoint!)
            let yearString = String(year)
            
            // Остаточний ключ використовується для пошуку суми, витраченої на певний день
            let key = monthString + "/" + dayString + "/" + yearString
            
            // Якщо витрачена сума порожня, встановимо її на цей день на 0.0
            if Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[key] == nil {
                Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[key] = 0.0
            }
            
            amountExpensesArray.append((Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[key])!)
            
            
            // Збільшимо відправну точку, додавши один день
            startingPoint = cal.date(byAdding: .day, value: 1, to: startingPoint!)!
        }
        
        return amountExpensesArray
    }
    
    // Витягає суму, витрачену за останні 12 місяців
    class func amountSpentInThePast12Months() -> [Double] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var startingPoint = cal.date(byAdding: .month, value: -11, to: today)
        
        var amountExpensesArray = [Double]()
        
        for _ in 1 ... 12 {
            // Створення компонентів місяця
            let month = cal.component(.month, from: startingPoint!)
            var monthString = String(month)
            if monthString.count == 1 {
                monthString = "0" + monthString
            }
            
            // Створення компонентів року
            let year = cal.component(.year, from: startingPoint!)
            let yearString = String(year)
            
            // Ключ використовується для пошуку суми, витраченої на певний місяць
            let key = monthString + "/" + yearString
            
            // Якщо витрачена сума порожня, встановіть її на цей день на 0.0
            if Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[key] == nil {
                Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[key] = 0.0
            }
            
            amountExpensesArray.append((Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[key])!)
            
            // Збільшимо відправну точку, додавши один місяць
            startingPoint = cal.date(byAdding: .month, value: 1, to: startingPoint!)!
        }
        
        return amountExpensesArray
    }
    
    // Введемо чисту суму Expense для сьогоднішніх витрат для кожного бюджету залежно від поточного індексу
    class func logTodaysSpendings(num: Double) {
        // Ключ утворюється сьогоднішньою датою
        let key = Variables.todaysDate(format: "MM/dd/YYYY")
        let monthKey = Variables.todaysDate(format: "MM/YYYY")
        
        // Якщо значення є нульовим, це означає, що сьогодні нічого не витрачено. Якщо так, ініціалізувати його на 0.0
        if Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[key] == nil {
            Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[key] = 0.0
        }
        
        if Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[monthKey] == nil {
            Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[monthKey] = 0.0
        }
        
        // Зберігає нову суму в словнику із ключовим словом, що є сьогоднішньою датою (MM / дд / рррр).
        let newAmount = (Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[key])! + num
        Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[key] = newAmount
        
        let newMonthAmount = (Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[monthKey])! + num
        Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[monthKey] = newMonthAmount
    }
    
    // Якщо є більше 5 гаманців, поверніть імена найпопулярніших гаманців у відсортованому порядку на основі їх key value,
    class func getWalletNames(map: [String : Double]) -> [String] {
        var keys = [String]()
        
        // Рядок масив всіх ключів (non-sorted)
        for (key, value) in map {
            if value > 0.0 {
                keys.append(key)
            }
        }
        
        //Сортуйте словник за його значенням
        if keys.count > 5 {
            keys.sort { (o1, o2) -> Bool in
                return map[o1]! > map[o2]!
            }
            
            var first4:[String] = Array(keys.prefix(4))
            first4.append("Other")
            keys = first4
        }
        
        return keys
    }
    
    // Приймає шістнадцятковий колір (IE: #ffffff) і повертає UIColor
    class func hexStringToUIColor(hex: String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    // Обчислює середнє значення масиву Double
    class func calculateAverage(nums: [Double]) -> Double {
        var total = 0.0
        for num in nums {
            total += num
        }
        return total/Double(nums.count)
    }
    
    // Повертає true, якщо масив заповнений усіма 0.0
    class func isAllZeros(array: [Double]) -> Bool {
        if array.isEmpty == true {
            return false
        }
        for num in array {
            if num != 0.0 {
                return false
            }
        }
        return true
    }
    
    // Отримайте повну дату для тексту опису
    class func getDateFromDescription(descripStr: String) -> String {
        let dateIndex = descripStr.index(descripStr.endIndex, offsetBy: -10)
        
        // Текст дати стає ММ/dd/РРРР
        return String(descripStr[dateIndex...]) //descripStr.substring(from: dateIndex)
    }
    
    // Створює частину масиву опису Detail
    class func getDetailFromDescription(descripStr: String) -> String {
        // Візьміемо лише Detail частину опису
        let detailIndex = descripStr.index(descripStr.endIndex, offsetBy: -14)
        
        return String(descripStr[..<detailIndex]) //descripStr.substring(to: detailIndex)
    }
    
    
    
    // Створює дату частини масиву amountExpensesOnDate
    class func createDateText(descripStr: String) -> String {
        // Отримайте дату з форматом: MМ/dd/YYYY
        var dateText = getDateFromDescription(descripStr: descripStr)
        
        // Текст дати стає MM/dd (позбувається року)
        let ddMMIndex = dateText.index(dateText.endIndex, offsetBy: -5)
        dateText = String(dateText[..<ddMMIndex]) //dateText.substring(to: ddMMIndex)
        
        // Слідкує за кількістю видалених нулів
        var numOfZerosRemoved = 0
        
        // Якщо перший символ є нулем, видалимо його
        let firstLeadingZeroIndex = dateText.index(dateText.startIndex, offsetBy: 0)
        if dateText[firstLeadingZeroIndex] == "0" {
            dateText.remove(at: firstLeadingZeroIndex)
            numOfZerosRemoved += 1
        }
        
        // Знаходить індекс символу відразу після "/"
        var count = 0
        for char in dateText {
            if char == "/" {
                break
            }
            count += 1
        }
        let firstSlashIndex = dateText.index(dateText.startIndex, offsetBy: count)
        let secondLeadingZeroIndex = dateText.index(after: firstSlashIndex)
        
        // Якщо символ відразу після "/" становить 0, видалимо його
        if dateText[secondLeadingZeroIndex] == "0" {
            dateText.remove(at: secondLeadingZeroIndex)
            numOfZerosRemoved += 1
        }
        
        //Змінна для інтервадів
        var blankSpace = ""
        
        // Виправлення інтервалу на основі кількості виданих нулів
        switch numOfZerosRemoved {
        case 0:
            blankSpace = "     "
        case 1:
            blankSpace = "        "
        case 2:
            blankSpace = "          "
        default:
            blankSpace = "     "
        }
        
        return blankSpace + dateText
    }
}
