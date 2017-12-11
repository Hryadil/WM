//
//  WalletViewController.swift
//  WM
//
//  Created by Vasyl< on 30.11.17.
//  Copyright © 2017 Vasyl<. All rights reserved.
//

import UIKit
import CoreData

class WalletViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    // sharedDelegate
    var sharedDelegate: AppDelegate!
    
    // IBOutlets
    @IBOutlet weak var addWalletButton: UIBarButtonItem!
    @IBOutlet var walletTable: UITableView!
    
    // Перше завантаження таблиці
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Заголовок
        title = NSLocalizedString("Wallets", comment: "Title")
        
        walletTable.dataSource = self
        walletTable.delegate = self
        
        // Щоб не створювати знову
        let shDelegate = UIApplication.shared.delegate as! AppDelegate
        sharedDelegate = shDelegate
        
        // Шукає один або кілька тапів.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // Очищаємо від порожніх рядків
        walletTable.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    // Завантажте дані таблиці кожного разу, коли ви заходите
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Отримання даних з CoreData
        Variables.getData()
        
        // Перезавантеження даних
        self.walletTable.reloadData()
    }
    
    //Викликає ф-н при виборі гаманця
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Змінна, щоб увімкнути та вимкнути кнопку підтвердження
    weak var confirmButton : UIAlertAction?
    
    // Функція, яка показує спливаюче сповіщення
    func showAlert() {
        let alert = UIAlertController(title: NSLocalizedString("Create a Wallet", comment: "Title for creating"), message: "", preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField(configurationHandler: {(textField: UITextField) in
            textField.placeholder = NSLocalizedString("Wallet Name", comment: "TextField Wallet Name")
            textField.delegate = self
            textField.autocapitalizationType = .words
        })
        
        alert.addTextField(configurationHandler: {(textField: UITextField) in
            textField.placeholder = NSLocalizedString("Amount of Wallet", comment: "TextField for amount")
            textField.keyboardType = .decimalPad
            textField.delegate = self
            textField.addTarget(self, action: #selector(self.inputAmountDidChange(_:)), for: .editingChanged)
        })
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: UIAlertActionStyle.cancel, handler: { (_) -> Void in
        })
        
        let create = UIAlertAction(title: NSLocalizedString("Create", comment: "Create button"), style: UIAlertActionStyle.default, handler: { (_) -> Void in
            var inputName = alert.textFields![0].text
            
            //Обрізати inputName спочатку
            inputName = inputName?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if let inputAmount = (Double(alert.textFields![1].text!))?.roundTo(places: 2) {
                if inputAmount >= 0 && inputAmount <= 1000000000 {
                    if inputName == "" {
                        inputName = NSLocalizedString("Untitled Wallet", comment: "Name of Wallet when textField ...")
                    }
                    
                    // Генерування правильного ім'я з урахуванням повторень
                    inputName = Variables.createName(myName: inputName!, myNum: 0)
                    
                    let context = self.sharedDelegate.persistentContainer.viewContext
                    let wallet = Wallet(context: context)
                    let appliation = Application(context: context)
                    let expenses = Expenses(context: context)
                    let incomes = Incomes(context: context)
                    
                    wallet.name = inputName
                    wallet.balance = inputAmount
                    appliation.descriptionArray = [String]()
                    appliation.historyArray = [String]()
                    expenses.totalAmountExpenses = 0.0
                    wallet.totalWalletAmount = inputAmount
                    incomes.totalAmountIncomes = 0.0
                    //wallet.barGraphColor = 0
                    
                    // Збережіти та отримайти дані CoreData
                    self.sharedDelegate.saveContext()
                    Variables.getData()
                    
                    // Встановимо новий поточний індекс і перезавантажимо таблицю
                    Variables.currentIndex = Variables.walletArray.count - 1
                    Variables.currentIndex = Variables.applicationArray.count - 1
                    Variables.currentIndex = Variables.expensesArray.count - 1
                    Variables.currentIndex = Variables.incomesArray.count - 1
                    self.walletTable.reloadData()
                }
            }
        })
        
        alert.addAction(create)
        alert.addAction(cancel)
        
        self.confirmButton = create
        create.isEnabled = false
        self.present(alert, animated: true, completion: nil)
    }
    
    // Ця функція обмежує максимальну кількість символів для кожного textField, та обмежує введення десяткових знаків до 2
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var maxLength = 0
        
        if textField.placeholder == "Amount of Wallet" || textField.placeholder == "Сума гаманця" {
            maxLength = 10
        }
        else if textField.placeholder == "Wallet Name" || textField.placeholder == "New Name" || textField.placeholder == "Ім'я Гаманця" || textField.placeholder == "Нове Ім'я" {
            maxLength = 18
        }
        
        let currentString = textField.text as NSString?
        let newString = currentString?.replacingCharacters(in: range, with: string)
        let isValidLength = newString!.count <= maxLength
        
        if textField.placeholder == "Amount of Wallet" || textField.placeholder == "Сума гаманця" {
            // Максимум 2 десяткових знаків
            let newText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            let regex = try! NSRegularExpression(pattern: "\\..{3,}", options: [])
            let matches = regex.matches(in: newText, options: [], range: NSMakeRange(0, newText.count))
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
    
    // Ця функція вимикає кнопку підтвердження, якщо кількість вхідних даних недійсна
    @objc func inputAmountDidChange(_ textField: UITextField) {
        // Перша обробка вводу
        let trimmedInput = (textField.text)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // Чи вхідне дані це число
        if let inputAmount = Double(trimmedInput!) {
            //Чи вхід також знаходиться між 0 і 1 міліард
            if inputAmount >= 0 && inputAmount <= 1000000000 {
                // Кнопка підтвердження включена
                self.confirmButton?.isEnabled = true
            }
            else {
                self.confirmButton?.isEnabled = false
            }
        }
        else {
            self.confirmButton?.isEnabled = false
        }
    }
    
    // Коли натиснута кнопка додати, відобразиться спливаюче сповіщення
    @IBAction func addWalletButtonWasPressed(_ sender: AnyObject) {
        // Спливаюче сповіщення
        showAlert()
    }
    
    //Якщо натиснути cell, перейдемо до відповідного бюджету
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewWallet" {
            // код для перегляду бюджету після натискання клітинки
        }
        
        // Визначаємо текст кнопки "Назад" для наступного перегляду
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
    }
    
    // Функції, які відповідають UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Показує кількість рядків, які повинна мати UITableView
        return Variables.walletArray.count + 1
    }
    
    // Встановлюємо назву та опис відповідної комірки
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let myCell: UITableViewCell = self.walletTable.dequeueReusableCell(withIdentifier: "clickableCell", for: indexPath)
        let count = Variables.walletArray.count
        
        // Якщо це останній елемент, налаштуйте повідомлення, зробіть його непридатним для вилучення та видаліть останній сепаратор
        if indexPath.row == count {
            myCell.textLabel?.textColor = UIColor.lightGray
            myCell.detailTextLabel?.textColor = UIColor.lightGray
            myCell.textLabel?.text = " "
            myCell.detailTextLabel?.text = " "
            myCell.selectionStyle = UITableViewCellSelectionStyle.none
            myCell.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, myCell.bounds.size.width)
        }
        else {
            myCell.textLabel?.textColor = UIColor.black
            myCell.detailTextLabel?.textColor = UIColor.black
            myCell.textLabel?.text = Variables.walletArray[indexPath.row].name
            let currentBalance = (Variables.walletArray[indexPath.row].balance).roundTo(places: 2)
            let currentBalanceString = Variables.numFormat(myNum: currentBalance)
            // let totalWalletAmt = lround((Variables.walletArray[indexPath.row].totalWalletAmount))
            // let totalWalletAmtString = String(totalWalletAmt)
            // myCell.detailTextLabel?.text = currentWalletString + " / $" + totalWalletAmtString
            myCell.detailTextLabel?.text = currentBalanceString
            myCell.selectionStyle = UITableViewCellSelectionStyle.default
            myCell.separatorInset = UIEdgeInsetsMake(0.0, 15.0, 0.0, 15.0)
        }
        
        return myCell
    }
    
    // Користувач не може видалити останню клітинку, яка містить інформацію
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Якщо це остання комірка, яка містить інформацію, користувач не може видалити цю комірку
        if indexPath.row == Variables.walletArray.count {
            return false
        }
        
        return true
    }
    
    //Коли обрано гаманець, при натисканні відбудеться перехід
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Якщо це не останній рядок, встановимо поточний індекс на рядок
        if indexPath.row != Variables.walletArray.count {
            Variables.currentIndex = indexPath.row
            performSegue(withIdentifier: "viewWallet", sender: nil)
        }
    }
    
    // Створює масив спеціальних кнопок, які з'являються після слайду вліво
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        // Заголовок - це функція кнопки
        let delete = UITableViewRowAction(style: .normal, title: NSLocalizedString("Delete", comment: "Button Delet in editAction")) { (action, indexPath) in
            let wallet = Variables.walletArray[indexPath.row]
            context.delete(wallet)
            self.sharedDelegate.saveContext()
            
            do {
                Variables.walletArray = try context.fetch(Wallet.fetchRequest())
                Variables.applicationArray = try context.fetch(Application.fetchRequest())
                Variables.expensesArray = try context.fetch(Expenses.fetchRequest())
                Variables.incomesArray = try context.fetch(Incomes.fetchRequest())
                
            }
            catch {
                print("Fetching Failed")
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            Variables.currentIndex = Variables.walletArray.count - 1
            Variables.currentIndex = Variables.applicationArray.count - 1
            Variables.currentIndex = Variables.expensesArray.count - 1
            Variables.currentIndex = Variables.incomesArray.count - 1
            
        }
        
        // Заголовок - це функція кнопки
        let rename = UITableViewRowAction(style: .normal, title: NSLocalizedString("Rename", comment: "Rename Delet in editAction")) { (action, indexPath) in
            self.showEditNameAlert(indexPath: indexPath)
        }
        
        // Змінимо кольора кнопок
        rename.backgroundColor = Variables.hexStringToUIColor(hex: "BBB7B0")
        delete.backgroundColor = Variables.hexStringToUIColor(hex: "E74C3C")
        
        return [delete, rename]
    }
    
    // Використаємо цю змінну, щоб увімкнути чи вимкнути кнопку "Зберегти"
    weak var nameSaveButton : UIAlertAction?
    
    // Показати спливаюче вікно редагування
    func showEditNameAlert(indexPath: IndexPath) {
        let editAlert = UIAlertController(title: NSLocalizedString("Rename Wallet", comment: "Title in showAlert"), message: "", preferredStyle: .alert)
        
        editAlert.addTextField(configurationHandler: {(textField: UITextField) in
            textField.placeholder = NSLocalizedString("New Name", comment: "New Name in showAlert")
            
            // Встановити початковий текст як ім'я гаманця вибраної рядка
            textField.text = Variables.walletArray[indexPath.row].name
            
            textField.delegate = self
            textField.autocapitalizationType = .words
            textField.addTarget(self, action: #selector(self.newNameTextFieldDidChange(_:)), for: .editingChanged)
        })
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Button Cancel in showAlert"), style: .cancel, handler: { (_) -> Void in
        })
        
        let save = UIAlertAction(title: NSLocalizedString("Save", comment: "Button Save in showAlert"), style: .default, handler: { (_) -> Void in
            var inputName = editAlert.textFields![0].text
            
            // Якщо ім'я введення не порожнє, це не стара назва
            if inputName != "" && inputName != Variables.walletArray[Variables.currentIndex].name {
                // Обрізати весь додатковий пробіл і нові рядки
                inputName = inputName?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                // Створіть ім'я з новою обробкою String
                inputName = Variables.createName(myName: inputName!, myNum: 0)
                Variables.walletArray[indexPath.row].name = inputName!
                self.walletTable.reloadRows(at: [indexPath], with: .right)
            }
            
            // Зберегти дані до CoreData
            self.sharedDelegate.saveContext()
            
            // Отримати дані
            Variables.getData()
        })
        
        editAlert.addAction(save)
        editAlert.addAction(cancel)
        
        self.nameSaveButton = save
        save.isEnabled = false
        self.present(editAlert, animated: true, completion: nil)
    }
    
    // Ця функція вимикає кнопку збереження, якщо ім'я вводу недійсне
    @objc func newNameTextFieldDidChange(_ textField: UITextField) {
        // Перша обробка вводу
        let input = (textField.text)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // Якщо вхід не пустий і він не існує, увімкнути кнопку «Зберегти»
        if input != "" && Variables.nameExistsAlready(str: input!) == false {
            self.nameSaveButton?.isEnabled = true
        }
        else {
            self.nameSaveButton?.isEnabled = false
        }
    }
}
