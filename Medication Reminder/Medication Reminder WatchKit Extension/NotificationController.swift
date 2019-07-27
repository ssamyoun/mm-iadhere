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
        let currentReminderCopy: NSMutableDictionary = dc.mutableCopy() as! NSMutableDictionary
        //let remindedCount = (currentReminderCopy["reminded"] as? Int)!
        let rId = (currentReminderCopy["ReminderId"] as? Int)!
        //print(String((currentReminder["ReminderId"] as! Int)) + "Id RemindedCount: " + String(remindedCount))
        let iDelegate = WKExtension.shared().rootInterfaceController as? InterfaceController
        iDelegate?.currentResponseResult = 1
        //currentReminderCopy["reminded"] = remindedCount + 1
        if((iDelegate?.isRemindersNotFull(rId: rId))!){//(remindedCount < 2){
            iDelegate?.incrementRemindersIdx(rId: rId)
            currentReminderCopy["query"] = currentReminderCopy["requery"] //this one should be only when user asks to remind later, but what if user clicks at the end of day???
            var renotifSet: Bool = false
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(40), execute: {
                if((iDelegate?.currentResponseResult)! < 2 && renotifSet == false){ //ended at notified
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (10*60), repeats: false) //10minslater
                    //works, .visibleInterfaceController also works
                    iDelegate?.addNotification(trigger: trigger, reminder: currentReminderCopy, repeatedReminder: true)
                    iDelegate?.sendSubjectResponseToServer(ReminderId: (currentReminderCopy["ReminderId"] as! Int), ReminderIndex: (currentReminderCopy["reminded"] as! Int), ResponseResult: (iDelegate?.currentResponseResult)!, Interaction: "")
                    //exit(0)
                    renotifSet = true //only ensure DispatchQueue doesnt add multiple notifs
                    //but i blv renotifs in simulators happen bcz we dont uninstall everytime before build so calendar notifs are set multiple times
                }
            })
        }
        titleLabel.setText(content.title)
        subtitleLabel.setText(content.subtitle)
        bodyLabel.setText(content.body)
        completionHandler(.custom)
    }
    
}
