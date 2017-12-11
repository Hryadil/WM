//
//  ExpensesViewController.swift
//  WM
//
//  Created by Vasyl< on 30.11.17.
//  Copyright © 2017 Vasyl<. All rights reserved.
//

import UIKit
import CoreData

class ExpensesViewController: UIViewController, UITextFieldDelegate {

    // sharedDelegate
    var sharedDelegate: AppDelegate!
    
    // IB Outlets
    @IBOutlet weak var expensesButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var totalBalance: UILabel!
    @IBOutlet weak var inputAmount: UITextField!
    @IBOutlet weak var descriptionText: UITextField!
    
    // Кнопки спочатку вмикаються чи вимикаються на основі умов
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Щоб не вводити знову
        let shDelegate = UIApplication.shared.delegate as! AppDelegate
        sharedDelegate = shDelegate
        
        // Встановлюємо Navbar Color
        let color = UIColor.white
        self.navigationController?.navigationBar.tintColor = color
        self.navigationItem.title = Variables.walletArray[Variables.currentIndex].name
        
        // Встановлюємо собі делегат textField
        inputAmount.delegate = self
        descriptionText.delegate = self
        
        // Встановлюємо заповнювач тексту для textfield
        inputAmount.placeholder = NSLocalizedString("$0.00", comment: "")
        inputAmount.keyboardType = .decimalPad
        descriptionText.placeholder = NSLocalizedString("What's it for?", comment: "")
        
        // Шукає одиночні або кілька тапів.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    // Синхронізує мітки з глобальними змінами
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Зберегти контекст і отримати дані
        self.sharedDelegate.saveContext()
        Variables.getData()
        
        // Оновити загальну мітку балансу, якщо в іншому представленні змінено змінні балансу
        totalBalance.text = Variables.numFormat(myNum: Variables.walletArray[Variables.currentIndex].balance)
        
        // Скидання текстових полів та вимкнення кнопок
        inputAmount.text = ""
        descriptionText.text = ""
        expensesButton.isEnabled = false
        addButton.isEnabled = false
    }
    
    //Викликає цю функцію коли визначений tap
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Ця функція обмежує максимальну кількість символів для textField та обмежує введення десяткових знаків до 2
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var maxLength = 0
        
        if textField.placeholder == "$0.00" || textField.placeholder == "₴0.00" {
            maxLength = 10
        }
        else if textField.placeholder == "What's it for?" || textField.placeholder == "Для чого це?" {
            maxLength = 22
        }
        
        let currentString = textField.text as NSString?
        let newString = currentString?.replacingCharacters(in: range, with: string)
        let isValidLength = newString!.count <= maxLength
        
        if textField.placeholder == "$0.00" || textField.placeholder == "₴0.00" {
            let newText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            let regex = try! NSRegularExpression(pattern: "\\..{3,}", options: [])
            let matches = regex.matches(in: newText, options:[], range:NSMakeRange(0, newText.count))
            guard matches.count == 0 else { return false }
            
            switch string {
            case "0","1","2","3","4","5","6","7","8","9":
                if isValidLength == true {
                    return true
                }
            case ".":
                let array = textField.text?.map { String($0) }
                var decimalCount = 0
                for character in array! {
                    if character == "." {
                        decimalCount += 1
                    }
                }
                if decimalCount == 1 {
                    return false
                }
                else if isValidLength == true {
                    return true
                }
            default:
                let array = string.map { String($0) }
                if array.count == 0 {
                    return true
                }
                return false
            }
        }
        
        // Для будь-якого іншого текстового поля поверніть значення true, якщо довжина дійсна
        if isValidLength == true {
            return true
        }
        else {
            return false
        }
    }
    
    // Ця функція викликається, коли натискається кнопка "Expenses"
    @IBAction func expenseButtonPressed(_ sender: Any) {
        // Отримати поточну дату, додати її до масиву історії
        let date = Variables.todaysDate(format: "MM/dd/YYYY")
        
        // Перше вставте вхід
        let trimmedInput = (inputAmount.text)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // Якщо сума вводу - це число, оберіть введення до двох десяткових знаків, перш ніж робити подальші розрахунки
        if let input = (Double(trimmedInput!))?.roundTo(places: 2) {
            Variables.walletArray[Variables.currentIndex].balance -= input
            totalBalance.text = Variables.numFormat(myNum: Variables.walletArray[Variables.currentIndex].balance)
            Variables.applicationArray[Variables.currentIndex].historyArray.append(NSLocalizedString("– $", comment: "") + String(format: "%.2f", input))
            
            // Обробіть текст опису перед додаванням
            let note = (descriptionText.text)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            Variables.applicationArray[Variables.currentIndex].descriptionArray.append(note! + "    " + date)
            
            //Введіть суму, вилучену за сьогоднішні витрати для цього конкретного бюджету
            Variables.logTodaysSpendings(num: input)
            
            // Введіть загальну суму, витрачену на цей бюджет
            Variables.expensesArray[Variables.currentIndex].totalAmountExpenses += input
            
            if Variables.walletArray[Variables.currentIndex].balance - input < 0 {
                expensesButton.isEnabled = false
            }
        }
        else {
            // Наша amountEnteredChanged повинна враховувати всі випадки, що не є числом
            totalBalance.text = NSLocalizedString("If this message is seen check func amountEnteredChanged", comment: "")
        }
        
        self.sharedDelegate.saveContext()
        Variables.getData()
    }
    
    // Ця функція викликається, коли натискається кнопка "Income"
    @IBAction func addButtonPressed(_ sender: Any) {
        // Отримати поточну дату, додати до масиву історії
        let date = Variables.todaysDate(format: "MM/dd/YYYY")
        
        // Обрізати суму введення
        let trimmedInput = (inputAmount.text)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if let input = (Double(trimmedInput!))?.roundTo(places: 2) {
            Variables.walletArray[Variables.currentIndex].balance += input
            totalBalance.text = Variables.numFormat(myNum: Variables.walletArray[Variables.currentIndex].balance)
            Variables.applicationArray[Variables.currentIndex].historyArray.append(NSLocalizedString("+ $", comment: "") + String(format: "%.2f", input))
            
            // Обробіть текст опису перед додаванням
            let description = (descriptionText.text)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            Variables.applicationArray[Variables.currentIndex].descriptionArray.append(description! + "    " + date)
            
            // Увійдіть в масиви історії та опису, а потім оновіть totalIncomesAmount і totalWalletAmount
            Variables.incomesArray[Variables.currentIndex].totalAmountIncomes += input
            Variables.walletArray[Variables.currentIndex].totalWalletAmount += input
            
            if Variables.walletArray[Variables.currentIndex].balance + input > 1000000000 {
                addButton.isEnabled = false
            }
        }
        
        // Зберегти дані в CoreData
        self.sharedDelegate.saveContext()
        
        // Отримати дані
        Variables.getData()
    }
    
    // Ця функція динамічно налаштовує наявність кнопок залежно від вводу
    @IBAction func amountEnteredChanged(_ sender: AnyObject) {
        // Перше вставте вхід
        let trimmedInput = (inputAmount.text)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // Якщо вхід порожній або період, показати поточний баланс і відключити кнопки
        if trimmedInput == "" || trimmedInput == "." {
            totalBalance.text = Variables.numFormat(myNum: Variables.walletArray[Variables.currentIndex].balance)
            expensesButton.isEnabled = false
            addButton.isEnabled = false
        }
            
            // В іншому випадку, якщо вхід є позитивним числом, увімкніть або вимкніть кнопки на основі вхідного значення
        else if let input = (Double(trimmedInput!))?.roundTo(places: 2) {
            // Показує помилку, якщо вхід перевищує 1 міліард
            if input > 1000000000 {
                totalBalance.text = NSLocalizedString("Must be under $1Miliard", comment: "")
                expensesButton.isEnabled = false
                addButton.isEnabled = false
            }
            else {
                totalBalance.text = Variables.numFormat(myNum: Variables.walletArray[Variables.currentIndex].balance)
                
                // Якщо вхід дорівнює 0, вимкніть обидві кнопки
                if input == 0 {
                    expensesButton.isEnabled = false
                    addButton.isEnabled = false
                }
                else {
                    // Якщо вхід може бути витрачений і як і раніше призводить до дійсного балансу, увімкніть кнопку "Expense"
                    if Variables.walletArray[Variables.currentIndex].balance - input < 0 {
                        expensesButton.isEnabled = false
                    }
                    else {
                        expensesButton.isEnabled = true
                    }
                    
                    // Якщо вхідний файл може бути доданий і досі дає дійсний баланс, увімкніть кнопку додати
                    if Variables.walletArray[Variables.currentIndex].balance + input > 1000000000 {
                        addButton.isEnabled = false
                    }
                    else {
                        addButton.isEnabled = true
                    }
                }
            }
        }
    }
    
    // Кнопка Історія
    @IBAction func historyButtonPressed(_ sender: Any) {
        // Зберегти контекст і отримати дані
        self.sharedDelegate.saveContext()
        Variables.getData()
        
        //Перегляд контролера з історією
        performSegue(withIdentifier: "showHistory", sender: nil)
    }
    
    // Кнопка Графіка
    @IBAction func graphsButtonPressed(_ sender: Any) {
        // Зберегти контекст і отримати дані
        self.sharedDelegate.saveContext()
        Variables.getData()
        performSegue(withIdentifier: "showGraphs", sender: nil)
    }
    
    // Підготовка до сегменту
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Якщо ми йдемо до перегляду стовпчикової графіки, встановлює текст кнопки порожнім
        if segue.identifier == "showGraphs" {
            
        }
            //Якщо ми переходимо до перегляду історії, встановлює текст кнопки як назву бюджету
        else if (segue.identifier == "showHistory") {
            
        }
        
        // Визначає текст кнопки "Назад" для наступного перегляду
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
    }

}
