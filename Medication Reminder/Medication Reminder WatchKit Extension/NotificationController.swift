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
        let receivedReminderCopy: NSMutableDictionary = dc.mutableCopy() as! NSMutableDictionary
        let iDelegate = WKExtension.shared().rootInterfaceController as? InterfaceController //.visibleInterfaceController also works
        iDelegate?.currentResponseResult = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(40), execute: {
            if((iDelegate?.currentResponseResult)! < 2){ //ended at notified
                iDelegate?.setMissedReminderAsPerSerialIdentifer(reminder: receivedReminderCopy, mn: 10)
                iDelegate?.sendSubjectResponseToServer(ReminderId: (receivedReminderCopy["ReminderId"] as! Int), ReminderIndex: HelperMethods.getReminderIndex(serialIdentifier: receivedReminderCopy["serialIdentifier"] as! String), ResponseResult: (iDelegate?.currentResponseResult)!, Interaction: "")
                //exit(0)
                //but i blv renotifs in simulators happen bcz we dont uninstall everytime before build so calendar notifs are set multiple times
            }
        })
        titleLabel.setText(content.title)
        subtitleLabel.setText(content.subtitle)
        bodyLabel.setText(content.body)
        completionHandler(.custom)
    }
    
}
