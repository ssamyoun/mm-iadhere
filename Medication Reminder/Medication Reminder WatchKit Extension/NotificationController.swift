//
//  NotificationController.swift
//  Medication Reminder WatchKit Extension
//
//  Created by Abu Sayeed Mondol on 9/6/18.
//  Copyright © 2018 Sirat Samyoun. All rights reserved.
//

import WatchKit
import Foundation
import UserNotifications


class NotificationController: WKUserNotificationInterfaceController {

    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var subtitleLabel: WKInterfaceLabel!
    @IBOutlet var bodyLabel: WKInterfaceLabel!
    
    override init() {
        // Initialize variables here.
        super.init()
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    
    override func didReceive(_ notification: UNNotification, withCompletion completionHandler: @escaping (WKUserNotificationInterfaceType) -> Swift.Void) {
        let content = notification.request.content
        let dc = content.userInfo as NSDictionary
        let receivedReminderCopy = dc.mutableCopy() as! NSMutableDictionary
        //perform(#selector(afterSeconds), with: nil, afterDelay: 40)
        let iDelegate = WKExtension.shared().rootInterfaceController as! InterfaceController
        iDelegate.currentResponseResult = 1
        titleLabel.setText(content.title)
        subtitleLabel.setText(content.subtitle)
        bodyLabel.setText(content.body)
        completionHandler(.custom)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(40), execute: {
            var currentReminderId = 0
            if(iDelegate.currentReminder != nil){
                currentReminderId = (iDelegate.currentReminder?["ReminderId"] as? Int)! // click korle currentReminderId set hoye jeto
            }
            let receivedReminderId = (receivedReminderCopy["ReminderId"] as? Int)!
            print((receivedReminderCopy["ReminderId"] as? Int)!)
            print((receivedReminderCopy["med_name"] as? String)!)
            if((receivedReminderId != currentReminderId) || (iDelegate.currentResponseResult) < 2){ //ended at notified
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                iDelegate.sendSubjectResponseToServer(ReminderId: (receivedReminderCopy["ReminderId"] as! Int), ReminderIndex: HelperMethods.getReminderIndex(serialIdentifier: receivedReminderCopy["serialIdentifier"] as! String), ResponseResult: (iDelegate.currentResponseResult), Interaction: "", RemindedTime: receivedReminderCopy["time"] as! String, TimeGroup: receivedReminderCopy["TimeGroup"] as! Int)
                iDelegate.setMissedReminderAsPerSerialIdentifer(reminder: receivedReminderCopy) //this must be after prev line, otherwise serialid changes before going to server
            }
        })
    }
    //works for wake up screen in session
    //public var receivedReminderCopy: NSMutableDictionary = NSMutableDictionary()
    
//    @objc public func afterSeconds(){
//        let iDelegate = WKExtension.shared().rootInterfaceController as! InterfaceController
//        iDelegate.currentResponseResult = 1
//        let currentReminderId = (iDelegate.currentReminder!["ReminderId"] as? Int)!
//        let receivedReminderId = (receivedReminderCopy["ReminderId"] as? Int)!
//        if((receivedReminderId != currentReminderId) || (iDelegate.currentResponseResult) < 2){ //ended at notified
//            iDelegate.setMissedReminderAsPerSerialIdentifer(reminder: receivedReminderCopy)
//            iDelegate.sendSubjectResponseToServer(ReminderId: (receivedReminderCopy["ReminderId"] as! Int), ReminderIndex: HelperMethods.getReminderIndex(serialIdentifier: receivedReminderCopy["serialIdentifier"] as! String), ResponseResult: (iDelegate.currentResponseResult), Interaction: "")
//    }
    
//}

}
