//
//  BarGraphViewController.swift
//  WM
//
//  Created by Vasyl< on 30.11.17.
//  Copyright © 2017 Vasyl<. All rights reserved.
//

import UIKit
import CoreData
import Charts

// Сюди додатємо графік за останні 7 днів
@objc(BarChartFormatterWeek)
public class BarChartFormatterWeek: NSObject, IAxisValueFormatter {
    // Витягаємо масив протягом семи днів
    var daysInWeek = Variables.pastInterval(interval: "Week")
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return daysInWeek[Int(value)]
    }
}
// Сюди додатємо графік за останні 31 день
@objc(BarChartFormatterMonth)
public class BarChartFormatterMonth: NSObject, IAxisValueFormatter {
    // Витягаємо масив протягом місяця
    var daysInMonth = Variables.pastInterval(interval: "Month")
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return daysInMonth[Int(value)]
    }
}
// Сюди додатємо графік за останній рік
@objc(BarChartFormatterYear)
public class BarChartFormatterYear: NSObject, IAxisValueFormatter {
    // Витягаємо масив протягом місяця
    var monthsInYear = Variables.pastXMonths(X: 12)
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return monthsInYear[Int(value)]
    }
}

class BarGraphViewController: UIViewController {
    
    var sharedDelegate: AppDelegate!
    
    // IB Outlets
    @IBOutlet var barGraphView: BarChartView!
    @IBOutlet weak var segmentedController: UISegmentedControl!
    //    @IBOutlet weak var pickerTextField: UITextField!
    
    
    // Масив кольорів графіка
    var color = [
        Variables.hexStringToUIColor(hex: "DCFAC0"),
        Variables.hexStringToUIColor(hex: "B1E1AE"),
        Variables.hexStringToUIColor(hex: "85C79C"),
        Variables.hexStringToUIColor(hex: "56AE8B"),
        Variables.hexStringToUIColor(hex: "00968B")
    ]
    
    // Days масив
    var days: [String]!
    
    // завантаження делегата
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let shDelegate = UIApplication.shared.delegate as! AppDelegate
        sharedDelegate = shDelegate
        
        // Якщо даних немає
        barGraphView.noDataText = NSLocalizedString("You must have at least one transaction.", comment: "")
    }
    
    
    // Завантажує графік перед тим, як виглядатиме зображення. Ми робимо це тут, оскільки дані можуть змінюватися
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Sync data
        self.sharedDelegate.saveContext()
        Variables.getData()
        // amoutExpense, витрачений на кожен день минулого тижня, у подвійному масиві
        let amountExpensePerWeek = Variables.amountSpentInThePast(interval: "Week")
        let amountExpensePerMonth = Variables.amountSpentInThePast(interval: "Month")
        let amountExpenseOverAYear = Variables.amountSpentInThePast12Months()
        // Індекс 0 - сюди можна вставити масив як тестовий приклад
        if (Variables.currentIndex == 0) {
            
        }
        // Якщо є значення для відображення, відображається граф
        if (segmentedController.selectedSegmentIndex == 0) {
            setBarGraphWeek(values: amountExpensePerWeek)
        }
        else if (segmentedController.selectedSegmentIndex == 1) {
            setBarGraphMonth(values: amountExpensePerMonth)
        }
        else {
            setBarGraphYear(values: amountExpenseOverAYear)
        }
    }
    
    
    // Викликає цю функцію, коли визначається тап.
    func dismissKeyboard() {
        // викликає view (або одне з його вбудованих текстових полів), щоб відмовитися від статусу першого респондента.
        view.endEditing(true)
    }
    
    
    // Встановлює граф на попередній тиждень
    func setBarGraphWeek(values: [Double]) {
        let barChartFormatter: BarChartFormatterWeek = BarChartFormatterWeek()
        let xAxis:XAxis = XAxis()
        
        var dataEntries: [BarChartDataEntry] = []
        
        for i in 0..<values.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: values[i])
            dataEntries.append(dataEntry)
            
            let _ = barChartFormatter.stringForValue(Double(i), axis: xAxis)
        }
        
        xAxis.valueFormatter = barChartFormatter
        barGraphView.xAxis.valueFormatter = xAxis.valueFormatter
        // Встановлює average лінію як середню суму, витрачену на цей тиждень
        let average = Variables.calculateAverage(nums: values)
        // Видаляє середню лінію з попереднього графіка
        barGraphView.rightAxis.removeAllLimitLines();
        // Додатє середню лінію, якщо на графіку є дані
        if average != 0.0 {
            let ll = ChartLimitLine(limit: average, label: NSLocalizedString("Average: ", comment: "") + Variables.numFormat(myNum: average))
            ll.lineColor = Variables.hexStringToUIColor(hex: "092140")
            ll.valueFont = UIFont.systemFont(ofSize: 12)
            ll.lineWidth = 2
            ll.labelPosition = .leftTop
            barGraphView.rightAxis.addLimitLine(ll)
        }
        // Встановлює позицію мітки x осі
        barGraphView.rightAxis.axisMinimum = 0
        barGraphView.xAxis.labelPosition = .bottom
        
        let chartDataSet = BarChartDataSet(values: dataEntries, label: NSLocalizedString("$ Spent Per Day", comment: ""))
        // Встановлює колірну схему
        chartDataSet.colors = color
        
        chartDataSet.axisDependency = .right
        let chartData = BarChartData(dataSet: chartDataSet)
        barGraphView.data = chartData
        // Розмір шрифту
        barGraphView.legend.font = UIFont.systemFont(ofSize: 13)
        barGraphView.legend.formSize = 8
        // за замовчуванням
        chartData.setDrawValues(true)
        barGraphView.rightAxis.drawLabelsEnabled = true
        
        if Variables.applicationArray[Variables.currentIndex].historyArray.isEmpty == true || Variables.isAllZeros(array: values) == true {
            chartData.setDrawValues(false)
            barGraphView.rightAxis.drawLabelsEnabled = false
        }
        // Встановлює, де починається вісь
        barGraphView.setScaleMinima(0, scaleY: 0.0)
        // Налаштування
        barGraphView.pinchZoomEnabled = false
        barGraphView.scaleXEnabled = false
        barGraphView.scaleYEnabled = false
        barGraphView.xAxis.drawGridLinesEnabled = false
        barGraphView.leftAxis.drawGridLinesEnabled = false
        barGraphView.rightAxis.drawGridLinesEnabled = false
        barGraphView.leftAxis.drawLabelsEnabled = false
        barGraphView.rightAxis.spaceBottom = 0
        barGraphView.leftAxis.spaceBottom = 0
        // Встановлює розмір шрифту
        chartData.setValueFont(UIFont.systemFont(ofSize: 12))
        
        let format = NumberFormatter()
        format.numberStyle = .currency
        let formatter = DefaultValueFormatter(formatter: format)
        chartData.setValueFormatter(formatter)
        
        // Встановлює шрифт Y Axis
        barGraphView.rightAxis.labelFont = UIFont.systemFont(ofSize: 11)
        // Встановлює шрифт X Axis
        barGraphView.xAxis.labelFont = UIFont.systemFont(ofSize: 13)
        // Закінчує всі 7 ярликів осі
        barGraphView.xAxis.setLabelCount(7, force: false)
        // Встановлює текст опису
        barGraphView.chartDescription?.text = ""
        
        // background color
        barGraphView.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        // Анімація діаграми
        barGraphView.animate(xAxisDuration: 0.0, yAxisDuration: 1.5)
    }
    
    // Встановлює графік на попередній місяць
    func setBarGraphMonth(values: [Double]) {
        // Залежно від розміру заданого масиву створює іншу X-осі
        let barChartFormatter:BarChartFormatterMonth = BarChartFormatterMonth()
        let xAxis:XAxis = XAxis()
        
        var dataEntries: [BarChartDataEntry] = []
        
        for i in 0..<values.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: values[i])
            dataEntries.append(dataEntry)
            
            let _ = barChartFormatter.stringForValue(Double(i), axis: xAxis)
        }
        
        xAxis.valueFormatter = barChartFormatter
        barGraphView.xAxis.valueFormatter = xAxis.valueFormatter
        // Встановлює ліміт лінії як середню суму, витрачену на цей місяць
        let average = Variables.calculateAverage(nums: values)
        // Видаляє середню лінію з попереднього графіка
        barGraphView.rightAxis.removeAllLimitLines();
        // Додає середню лінію, якщо на графіку є дані
        if average != 0.0 {
            let ll = ChartLimitLine(limit: average, label: NSLocalizedString("Average: ", comment: "") + Variables.numFormat(myNum: average))
            ll.lineColor = Variables.hexStringToUIColor(hex: "092140")
            ll.valueFont = UIFont.systemFont(ofSize: 12)
            ll.lineWidth = 2
            ll.labelPosition = .leftTop
            barGraphView.rightAxis.addLimitLine(ll)
        }
        // Встановлює позицію мітки x осі
        barGraphView.rightAxis.axisMinimum = 0
        barGraphView.xAxis.labelPosition = .bottom
        
        let chartDataSet = BarChartDataSet(values: dataEntries, label: NSLocalizedString("$ Spent Per Month", comment: ""))
        // Встановлює колірну схему
        chartDataSet.colors = color
        
        chartDataSet.axisDependency = .right
        let chartData = BarChartData(dataSet: chartDataSet)
        barGraphView.data = chartData
        // Розмір шрифту
        barGraphView.legend.font = UIFont.systemFont(ofSize: 13)
        barGraphView.legend.formSize = 8
        // за замовчуванням
        chartData.setDrawValues(true)
        barGraphView.rightAxis.drawLabelsEnabled = true
        
        if Variables.applicationArray[Variables.currentIndex].historyArray.isEmpty == true || Variables.isAllZeros(array: values) == true {
            chartDataSet.label = NSLocalizedString("You must spend to see data", comment: "")
            chartData.setDrawValues(false)
            barGraphView.rightAxis.drawLabelsEnabled = false
        }
        // Встановлює де починається вісь
        barGraphView.setScaleMinima(0, scaleY: 0.0)
        
        barGraphView.pinchZoomEnabled = false
        barGraphView.scaleXEnabled = false
        barGraphView.scaleYEnabled = false
        barGraphView.xAxis.drawGridLinesEnabled = false
        barGraphView.leftAxis.drawGridLinesEnabled = false
        barGraphView.rightAxis.drawGridLinesEnabled = false
        barGraphView.leftAxis.drawLabelsEnabled = false
        barGraphView.rightAxis.spaceBottom = 0
        barGraphView.leftAxis.spaceBottom = 0
        
        chartData.setValueFont(UIFont.systemFont(ofSize: 0))
        
        let format = NumberFormatter()
        format.numberStyle = .currency
        let formatter = DefaultValueFormatter(formatter: format)
        chartData.setValueFormatter(formatter)
        
        barGraphView.rightAxis.labelFont = UIFont.systemFont(ofSize: 11)
        
        barGraphView.xAxis.labelFont = UIFont.systemFont(ofSize: 13)
        
        barGraphView.xAxis.setLabelCount(6, force: false)
        
        barGraphView.chartDescription?.text = ""
        
        // background color
        barGraphView.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        
        barGraphView.animate(xAxisDuration: 0.0, yAxisDuration: 1.5)
    }
    
    // Встановлює діаграму за минулий рік
    func setBarGraphYear(values: [Double]) {
        let barChartFormatter:BarChartFormatterYear = BarChartFormatterYear()
        let xAxis:XAxis = XAxis()
        
        var dataEntries: [BarChartDataEntry] = []
        
        for i in 0..<values.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: values[i])
            dataEntries.append(dataEntry)
            
            let _ = barChartFormatter.stringForValue(Double(i), axis: xAxis)
        }
        
        xAxis.valueFormatter = barChartFormatter
        barGraphView.xAxis.valueFormatter = xAxis.valueFormatter
        
        let average = Variables.calculateAverage(nums: values)
        
        barGraphView.rightAxis.removeAllLimitLines();
        
        if average != 0.0 {
            let ll = ChartLimitLine(limit: average, label: NSLocalizedString("Average: ", comment: "") + Variables.numFormat(myNum: average))
            ll.lineColor = Variables.hexStringToUIColor(hex: "092140")
            ll.valueFont = UIFont.systemFont(ofSize: 12)
            ll.lineWidth = 2
            ll.labelPosition = .leftTop
            barGraphView.rightAxis.addLimitLine(ll)
        }
        
        barGraphView.rightAxis.axisMinimum = 0
        barGraphView.xAxis.labelPosition = .bottom
        
        let chartDataSet = BarChartDataSet(values: dataEntries, label: NSLocalizedString("$ Spent Per Year", comment: ""))
        
        chartDataSet.colors = color
        chartDataSet.axisDependency = .right
        let chartData = BarChartData(dataSet: chartDataSet)
        barGraphView.data = chartData
        
        barGraphView.legend.font = UIFont.systemFont(ofSize: 13)
        barGraphView.legend.formSize = 8
        
        chartData.setDrawValues(true)
        barGraphView.rightAxis.drawLabelsEnabled = true
        
        if Variables.applicationArray[Variables.currentIndex].historyArray.isEmpty == true || Variables.isAllZeros(array: values) == true {
            chartData.setDrawValues(false)
            barGraphView.rightAxis.drawLabelsEnabled = false
        }
        
        barGraphView.setScaleMinima(0, scaleY: 0.0)
        
        barGraphView.pinchZoomEnabled = false
        barGraphView.scaleXEnabled = false
        barGraphView.scaleYEnabled = false
        barGraphView.xAxis.drawGridLinesEnabled = false
        barGraphView.leftAxis.drawGridLinesEnabled = false
        barGraphView.rightAxis.drawGridLinesEnabled = false
        barGraphView.leftAxis.drawLabelsEnabled = false
        barGraphView.rightAxis.spaceBottom = 0
        barGraphView.leftAxis.spaceBottom = 0
        
        chartData.setValueFont(UIFont.systemFont(ofSize: 0))
        
        let format = NumberFormatter()
        format.numberStyle = .currency
        let formatter = DefaultValueFormatter(formatter: format)
        chartData.setValueFormatter(formatter)
        
        barGraphView.rightAxis.labelFont = UIFont.systemFont(ofSize: 11)
        
        barGraphView.xAxis.labelFont = UIFont.systemFont(ofSize: 12)
        
        barGraphView.xAxis.setLabelCount(12, force: false)
        
        barGraphView.chartDescription?.text = ""
        
        // background color
        barGraphView.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        
        barGraphView.animate(xAxisDuration: 0.0, yAxisDuration: 1.5)
    }
    // Оновити графік залежно від вибраного інтервалу часу
    func updateGraph() {
        // Якщо вибрано сегмент "Тиждень"
        if (segmentedController.selectedSegmentIndex == 0) {
            let amountSpentPerWeek = Variables.amountSpentInThePast(interval: "Week")
            // Індекс 0 - сюди можна вставити масив як тестовий приклад
            if (Variables.currentIndex == 0) {
               // amountSpentPerWeek = [20, 4.2, 6.89, 9.99, 60.80, 58.10, 35]
            }
            
            barGraphView.notifyDataSetChanged()
            setBarGraphWeek(values: amountSpentPerWeek)
        }
            // Якщо вибрано сегмент "Місяць"
        else if (segmentedController.selectedSegmentIndex == 1) {
            let amountSpentPerMonth = Variables.amountSpentInThePast(interval: "Month")
            // Індекс 0 - сюди можна вставити масив як тестовий приклад
            if (Variables.currentIndex == 0) {
                
               // amountSpentPerMonth = [65.20, 134.50, 120.65, 168.8, 186.58, 295.69, 275.67, 256.87, 186.42, 240.23, 200.67, 140.98, 65.20, 134.50, 120.65, 168.8, 186.58, 295.69, 275.67, 256.87, 186.42, 240.23, 200.67, 140.98, 65.20, 134.50, 120.65, 168.8, 186.58, 295.69, 275.67]
                
            }
            
            barGraphView.notifyDataSetChanged()
            setBarGraphMonth(values: amountSpentPerMonth)
        }
            // Якщо вибрано сегмент "Рік"
        else if (segmentedController.selectedSegmentIndex == 2) {
            let amountSpentOverAYear = Variables.amountSpentInThePast12Months()
            // Індекс 0 - сюди можна вставити масив як тестовий приклад
            if (Variables.currentIndex == 0) {
                
              //  amountSpentOverAYear = [65.20, 134.50, 120.65, 168.8, 186.58, 295.69, 275.67, 256.87, 186.42, 240.23, 200.67, 140.98]
                
            }
            
            barGraphView.notifyDataSetChanged()
            setBarGraphYear(values: amountSpentOverAYear)
        }
    }
    // Оновлення графа після зміни сегмента
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        updateGraph()
    }
    
}
