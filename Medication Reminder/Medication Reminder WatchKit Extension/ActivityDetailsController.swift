//
//  ActivityDetailsController.swift
//  Medication Reminder
//
//  Created by Abu Sayeed Mondol on 7/7/19.
//  Copyright © 2019 Sirat Samyoun. All rights reserved.
//

import Foundation
import WatchKit

class ActivityDetailsController: WKInterfaceController {

    var currentReminder: NSMutableDictionary?
    @IBOutlet var activityImage: WKInterfaceImage!
    @IBOutlet var activityTitleLbl: WKInterfaceLabel!
    
    override init() {
        super.init()
        loadActivityDetails()
    }
    
    func loadActivityDetails(){
        let iDelegate = WKExtension.shared().rootInterfaceController as? InterfaceController
        currentReminder = iDelegate?.currentReminder
        let currentPrescriptionType = (currentReminder!["type"] as? Int)!
        if(currentPrescriptionType == 2 || currentPrescriptionType == 5){
            activityImage.setImage(UIImage(named: "Exercise_Watch.png"))
        }else if(currentPrescriptionType == 3){
            activityImage.setImage(UIImage(named: "heart-rate_Watch.jpg"))
        }else if(currentPrescriptionType == 1){
            activityImage.setImage(UIImage(named: "Pill_Watch.png"))
        }else if(currentPrescriptionType == 4){
            activityImage.setImage(UIImage(named: "EKG-Watch.png"))
        }
        let medName:String = (currentReminder!["med_name"] as? String)!
        activityTitleLbl.setText(medName)
    }
    
    func loadBlank(){
        activityImage.setImage(nil)
        activityTitleLbl.setText("")
    }
}
