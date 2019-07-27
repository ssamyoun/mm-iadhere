//
//  PrescriptionsViewController.swift
//  Medication Reminder WatchKit Extension
//
//  Created by Abu Sayeed Mondol on 6/29/19.
//  Copyright © 2019 Sirat Samyoun. All rights reserved.
//

import Foundation
import WatchKit

class PrescriptionInterfaceController: WKInterfaceController {
    
//    @IBOutlet var PrescriptionsTable: WKInterfaceTable!
//    var remindersDictionary : [Int : NSMutableDictionary]?
//    var currentReminder: NSMutableDictionary?
    
    override init() {
        super.init()
        //loadRemindersinTable()
    }
    
//    func currentTimeToMinutes() -> Int {
//        let date = Date()
//        let hour = Calendar.current.component(.hour, from: date)
//        let mins = Calendar.current.component(.minute, from: date)
//        let totalmins = hour * 60 + mins
//        return totalmins
//    }
//
//    func convertToMinutes(str:String) -> Int{
//        let arrayTimes = [str]
//        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//        for (_,time) in arrayTimes.enumerated() {
//            dateFormatter.dateFormat = "HH:mm:ss"
//            if let inDate = dateFormatter.date(from: time) {
//                let hour = Calendar.current.component(.hour, from: inDate)
//                let mins = Calendar.current.component(.minute, from: inDate)
//                let totalmins = hour * 60 + mins
//                return totalmins
//            }
//        }
//        return 0
//    }
//
//    func loadRemindersinTable(){
//        let iDelegate = WKExtension.shared().rootInterfaceController as? InterfaceController
//        currentReminder = iDelegate?.currentReminder
//        remindersDictionary = iDelegate?.remindersDictionary
//
//        PrescriptionsTable.setNumberOfRows(remindersDictionary!.count, withRowType: "PrescriptionList")
//        var index: Int = 0
//        let sortRem = remindersDictionary!.sorted(by:{ $0.key < $1.key })
//
//
//        for prescription in sortRem{
//            let prescripMins = convertToMinutes(str: prescription.value["time"] as! String)
//            let currentMins = currentTimeToMinutes()
//            if(currentMins < prescripMins){
//                //set reminder 0
//                prescription.value["Taken"] = 0
//            }
//
//            var time: String = "\(prescription.value["time"])"
//            time = String(time.dropFirst(9))
//            time = String(time.dropLast(4))
//            var check:Int = Int(String(time.dropLast(3))) ?? 0
//
//            if check > 12 {
//                check = check - 12
//                time = String(time.dropFirst(2))
//                time = String(check) + time + " PM"
//            }else if check == 12 {
//                time = time + " PM"
//            }else if check == 0 {
//                time = String(time.dropFirst(2))
//                time = String(12) + time + " AM"
//            }else{
//                time = time + " AM"
//            }
//
//            var text: String = "\(prescription.value["display_text"])"
//            text = String(text.dropFirst(9))
//            text = String(text.dropLast(1))
//            let row = PrescriptionsTable.rowController(at: index) as! PrescriptionList
//            row.PrescriptionLbl.setText(time+"\n"+text)
//            index = index+1
//
//            //let t: Int = prescription.value["Taken"] as! Int
//
//            //if t == 1{
//            //    row.PrescriptionLbl.setTextColor(UIColor(red: 0.8588, green: 0.1137, blue: 0, alpha: 1.0) )
//            //}else if t == 2{
//                row.PrescriptionLbl.setTextColor(UIColor(red: 0.2431, green: 0.5882, blue: 0, alpha: 1.0) )
//           // }
//
//        }
//    }
}
