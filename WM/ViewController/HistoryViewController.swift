//
//  HistoryViewController.swift
//  WM
//
//  Created by Vasyl< on 30.11.17.
//  Copyright © 2017 Vasyl<. All rights reserved.
//

import UIKit
import CoreData

class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    var sharedDelegate: AppDelegate!
    
    // IBOutlet for components
    @IBOutlet var historyTable: UITableView!
    @IBOutlet weak var clearHistoryButton: UIBarButtonItem!
    
    //Завантаження table view
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString("History", comment: "")
        
        //Встановлюємо колір навігації
        let color = UIColor.white
        self.navigationController?.navigationBar.tintColor = color
        
        //створюємо делегати
        historyTable.dataSource = self
        historyTable.delegate = self
        
        // Якщо історії немає, вимикаємо кнопку очищення історії
        if Variables.applicationArray[Variables.currentIndex].historyArray.isEmpty == true {
            clearHistoryButton.isEnabled = false
        }
        else {
            clearHistoryButton.isEnabled = true
        }
        
        //sharedDelegate
        let shDelegate = UIApplication.shared.delegate as! AppDelegate
        sharedDelegate = shDelegate
        
        // Пошук для одного або кількох тапів.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // Очищаємо від порожніх рядків
        historyTable.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    //Викликає цю функцію коли тапнути
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Функція працює щоразу, коли з'являється екран
    override func viewWillAppear(_ animated: Bool) {
        // Переконаємося, що таблиця оновлена
        super.viewWillAppear(animated)
        //Отримуємо дані з БД
        Variables.getData()
        
        // Перезавантажуємо таблицб
        self.historyTable.reloadData()
    }
    
    // Після натискання кнопки очищення історії очистітиться історію та вимкнеться кнопка
    @IBAction func clearHistoryButtonWasPressed(_ sender: Any)
    {
        // Видалити масив
        Variables.applicationArray[Variables.currentIndex].historyArray.removeAll()
        Variables.applicationArray[Variables.currentIndex].descriptionArray.removeAll()
        
        // Повертає баланс до початкового значення та скидає змінні
        let totalAmtIncome = Variables.incomesArray[Variables.currentIndex].totalAmountIncomes
        let totalAmtExpense = Variables.expensesArray[Variables.currentIndex].totalAmountExpenses
        let myBalance = Variables.walletArray[Variables.currentIndex].balance
        let newBalanceAndWalletAmount = myBalance - totalAmtIncome + totalAmtExpense
        Variables.walletArray[Variables.currentIndex].balance = newBalanceAndWalletAmount
        Variables.walletArray[Variables.currentIndex].totalWalletAmount = newBalanceAndWalletAmount
        Variables.incomesArray[Variables.currentIndex].totalAmountIncomes = 0.0
        Variables.expensesArray[Variables.currentIndex].totalAmountExpenses = 0.0
        Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate.removeAll()
        
        //Зберігаємо оновлення та отримуємо дані з БД
        self.sharedDelegate.saveContext()
        Variables.getData()
        
        // Перезавантажуємо таблицю та вимикаємо кнопку
        self.historyTable.reloadData()
        clearHistoryButton.isEnabled = false
    }
    
    // Функція, що відповідає UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Показує кількість рядків, які повинна мати UITableView
        return Variables.applicationArray[Variables.currentIndex].historyArray.count + 1
    }
    
    // Визначає, які дані йдуть в якій комірці
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let myCell: UITableViewCell = historyTable.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath)
        let count = Variables.applicationArray[Variables.currentIndex].historyArray.count
        // Якщо це останній елемент, створимо повідомлення повідомлення
        if indexPath.row == count {
            myCell.textLabel?.textColor = UIColor.lightGray
            myCell.detailTextLabel?.textColor = UIColor.lightGray
            myCell.textLabel?.text = NSLocalizedString("Swipe to edit", comment: "")
            myCell.textLabel?.font = UIFont.systemFont(ofSize: 12)
            myCell.detailTextLabel?.text = ""
            myCell.selectionStyle = UITableViewCellSelectionStyle.none
        }
        else {
            myCell.textLabel?.textColor = UIColor.black
            myCell.detailTextLabel?.textColor = UIColor.black
            
            let str = Variables.applicationArray[Variables.currentIndex].historyArray[indexPath.row]
            let index = str.index(str.startIndex, offsetBy: 0)
            
            if str[index] == "+" || str[index] == "+" {
                myCell.textLabel?.textColor = Variables.hexStringToUIColor(hex: "00B22C")
            }
            
            if str[index] == "–"  || str[index] == "-"{
                myCell.textLabel?.textColor = Variables.hexStringToUIColor(hex: "FF0212")
            }
            
            myCell.textLabel?.text = Variables.applicationArray[Variables.currentIndex].historyArray[indexPath.row]
            
            // рядок опису
            let descripStr = Variables.applicationArray[Variables.currentIndex].descriptionArray[indexPath.row]
            // Створимо текст для Detail
            let detailText = Variables.getDetailFromDescription(descripStr: descripStr)
            // Створення тексту дати
            let dateText = Variables.createDateText(descripStr: descripStr)
            // Відображає текст вище
            let displayText = detailText + dateText
            myCell.detailTextLabel?.text = displayText
            myCell.selectionStyle = UITableViewCellSelectionStyle.default
        }
        // Індивідуальні вставки для розділювача
        myCell.separatorInset = UIEdgeInsetsMake(0.0, 15.0, 0.0, 15.0)
        
        return myCell
    }
    // Користувач не може видалити останню клітинку, в якій міститься заголовки
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Якщо це остання комірка, користувач не може видалити цю комірку
        if indexPath.row == Variables.applicationArray[Variables.currentIndex].historyArray.count {
            return false
        }
        
        let historyStr = Variables.applicationArray[Variables.currentIndex].historyArray[indexPath.row]
        let index1 = historyStr.index(historyStr.startIndex, offsetBy: 0)
        
        let index2 = historyStr.index(historyStr.startIndex, offsetBy: 3)
        let amountSpent = Double(String(historyStr[index2...])) //historyStr.substring(from: index2))
        
        // Якщо після видалення новий залишок становить більше 1 М, користувач не може видалити цю комірку
        if historyStr[index1] == "–" || historyStr[index1] == "-" {
            let newBalance = Variables.walletArray[Variables.currentIndex].balance + amountSpent!
            if newBalance > 1_000_000_000 {
                return false
            }
        }
        else if historyStr[index1] == "+" || historyStr[index1] == "+"  {
            let newBalance = Variables.walletArray[Variables.currentIndex].balance - amountSpent!
            if newBalance < 0 {
                return false
            }
        }
        
        return true
    }
    
    // Створює масив спеціальних кнопок, які з'являються після слайду вліво
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // заголовок - це текст кнопки
        let undo = UITableViewRowAction(style: .normal, title: NSLocalizedString("Undo", comment: "")) { (action, indexPath) in
            
            // Витягнемо ключ в форматі "MM / дд / РРРР" у дату змінної
            let noteStr = Variables.applicationArray[Variables.currentIndex].descriptionArray[indexPath.row]
            let dateIndex = noteStr.index(noteStr.endIndex, offsetBy: -10)
            let date = String(noteStr[dateIndex...])
            
            // Витягнемо місяць і рік з опису, щоб ми могли відмінити, скільки ми витрачаємо на місяць
            let monthBegin = noteStr.index(noteStr.endIndex, offsetBy: -10)
            let monthEnd = noteStr.index(noteStr.endIndex, offsetBy: -9)
            let monthString = noteStr[monthBegin...monthEnd]
            let yearBegin = noteStr.index(noteStr.endIndex, offsetBy: -4)
            let yearString = String(noteStr[yearBegin...])
            let monthKey = monthString + "/" + yearString
            
            // Витягніть суму, витрачену для цієї конкретної транзакції, на змінну amountExpense
            let historyStr = Variables.applicationArray[Variables.currentIndex].historyArray[indexPath.row]
            let index1 = historyStr.index(historyStr.startIndex, offsetBy: 0)
            let index2 = historyStr.index(historyStr.startIndex, offsetBy: 3)
            let historyValue = Double(String(historyStr[index2...]))
            
            // Якщо ця конкретна частина історії ввійшла в дію "Витрати", то після видалення загальна сума витрат має зменшитися
            if historyStr[index1] == "–" || historyStr[index1] == "-" {
                let newAmtSpentOnDate = Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[date]! - historyValue!
                Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[date] = newAmtSpentOnDate
                let newAmtSpentInMonth = Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[monthKey]! - historyValue!
                Variables.expensesArray[Variables.currentIndex].amountExpensesOnDate[monthKey] = newAmtSpentInMonth
                let newTotalAmountSpent = Variables.expensesArray[Variables.currentIndex].totalAmountExpenses - historyValue!
                Variables.expensesArray[Variables.currentIndex].totalAmountExpenses = newTotalAmountSpent
                let newBalance = (Variables.walletArray[Variables.currentIndex].balance) + historyValue!
                Variables.walletArray[Variables.currentIndex].balance = newBalance
            }
                
                // Якщо ця дія була Income
            else if historyStr[index1] == "+" || historyStr[index1] == "+" {
                let newTotalAmountAdded = Variables.incomesArray[Variables.currentIndex].totalAmountIncomes - historyValue!
                Variables.incomesArray[Variables.currentIndex].totalAmountIncomes = newTotalAmountAdded
                let newBalance = (Variables.walletArray[Variables.currentIndex].balance) - historyValue!
                Variables.walletArray[Variables.currentIndex].balance = newBalance
                let newBudgetAmount = (Variables.walletArray[Variables.currentIndex].totalWalletAmount) - historyValue!
                Variables.walletArray[Variables.currentIndex].totalWalletAmount = newBudgetAmount
            }
            // Видалимо рядок
            Variables.applicationArray[Variables.currentIndex].historyArray.remove(at: indexPath.row)
            Variables.applicationArray[Variables.currentIndex].descriptionArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.sharedDelegate.saveContext()
            Variables.getData()
            
            // Вимкнути кнопку очищення історії, якщо був останній елемент
            if Variables.applicationArray[Variables.currentIndex].historyArray.isEmpty == true {
                self.clearHistoryButton.isEnabled = false
            }
            else {
                self.clearHistoryButton.isEnabled = true
            }
        }
        // Зміна кольору кнопки undo
        undo.backgroundColor = Variables.hexStringToUIColor(hex: "E74C3C")
        // Редагувати елемент в комірці
        let edit = UITableViewRowAction(style: .normal, title: NSLocalizedString("Edit", comment: "")) { (action, indexPath) in
            // Якщо це не останній рядок
            if indexPath.row != Variables.applicationArray[Variables.currentIndex].historyArray.count {
                let descripStr = Variables.applicationArray[Variables.currentIndex].descriptionArray[indexPath.row]
                let index = descripStr.index(descripStr.endIndex, offsetBy: -14)
                self.oldDescription = String(descripStr[..<index])
                self.showEditDescriptionAlert(indexPath: indexPath)
            }
        }
        // Зміна кольору кнопки edit
        edit.backgroundColor = Variables.hexStringToUIColor(hex: "BBB7B0")
        
        return [undo, edit]
    }
    
    
    // Змінна, щоб увімкнути та вимкнути кнопку "Зберегти"
    weak var saveButton : UIAlertAction?
    
    
    // показує спливаюче сповіщення
    func showEditDescriptionAlert(indexPath: IndexPath) {
        let alert = UIAlertController(title: NSLocalizedString("Edit Description", comment: ""), message: "", preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField(configurationHandler: {(textField: UITextField) in
            textField.placeholder = NSLocalizedString("New Description", comment: "")
            
            //Візьмемо старий опис та помістимо його в textField
            let oldDescription = Variables.applicationArray[Variables.currentIndex].descriptionArray[indexPath.row]
            textField.text = Variables.getDetailFromDescription(descripStr: oldDescription)
            
            textField.delegate = self
            textField.autocapitalizationType = .sentences
            textField.addTarget(self, action: #selector(self.inputDescriptionDidChange(_:)), for: .editingChanged)
        })
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: { (_) -> Void in
        })
        
        let save = UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: UIAlertActionStyle.default, handler: { (_) -> Void in
            var inputDescription = alert.textFields![0].text
            // Перша обробка вводу Ім'я
            inputDescription = inputDescription?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            // Отримуємо стартй опис
            let oldDescription = Variables.applicationArray[Variables.currentIndex].descriptionArray[indexPath.row]
            // Змінюємо поточний опис
            let date = Variables.getDateFromDescription(descripStr: oldDescription)
            Variables.applicationArray[Variables.currentIndex].descriptionArray[indexPath.row] = inputDescription! + "    " + date
            self.historyTable.reloadRows(at: [indexPath], with: .fade)
            //Зберігаємо оновлення та отримуємо дані з БД
            self.sharedDelegate.saveContext()
            Variables.getData()
            //Перезавантаження таблиці
            self.historyTable.reloadData()
            
        })
        
        alert.addAction(save)
        alert.addAction(cancel)
        
        self.saveButton = save
        save.isEnabled = false
        self.present(alert, animated: true, completion: nil)
    }
    
    // Утримує старий опис клітинки, при натисненні на клітинку
    var oldDescription: String = ""
    
    // Вмикає кнопку збереження, якщо опис не відповідає поточному опису
    @objc func inputDescriptionDidChange(_ textField: UITextField) {
        let inputDescription = textField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if inputDescription != self.oldDescription {
            self.saveButton?.isEnabled = true
        }
        else {
            self.saveButton?.isEnabled = false
        }
    }
    // Ця функція обмежує максимальну кількість символів для textField
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var maxLength = 0
        
        if textField.placeholder == "New Description" || textField.placeholder == "Новий опис" {
            maxLength = 22
        }
        
        let currentString = textField.text as NSString?
        let newString = currentString?.replacingCharacters(in: range, with: string)
        return newString!.count <= maxLength
    }

}
