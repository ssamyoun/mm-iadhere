//
//  HeartRateController.swift
//  Medication Reminder WatchKit Extension
//
//  Created by Abu Sayeed Mondol on 10/21/18.
//  Copyright © 2018 Sirat Samyoun. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class HeartRateController: WKInterfaceController, HKWorkoutSessionDelegate {

    override init() {
        super.init()
        heartImage.setImage(UIImage(named: "heart-rate_Watch.png"))
        activateHKSession()
        workoutActive = false
        heartRateBtnAction()
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
        workoutActive = true
        heartRateBtnAction()
    }

    var workoutActive = false
    let healthStore = HKHealthStore()
    var hkSession : HKWorkoutSession?
    var hkTimer: Timer?
    var screenOffTimer: Timer?
    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    @IBOutlet var heartImage: WKInterfaceImage!
    @IBOutlet var heartRateBtn: WKInterfaceButton!
    
    @IBAction func heartRateBtnAction() {
        if (self.workoutActive) {
            //finish the current workout
            self.hkTimer?.invalidate()
            self.screenOffTimer?.invalidate()
            self.sendHeartRatesToServer()
            self.workoutActive = false
            heartRateBtn.setHidden(false)
            self.heartRateBtn.setTitle("Check Again")
            if let workout = self.hkSession {
                healthStore.end(workout)
            }
        } else {
            //start a new workout
            heartRates = []
            heartRatesAsStr = ""
            self.workoutActive = true
            heartRateBtn.setHidden(true)
            //self.heartRateBtn.setTitle("Finish")
            if (hkSession != nil) {
                return
            }
            // Configure the workout session.
            let workoutConfiguration = HKWorkoutConfiguration()
            workoutConfiguration.activityType = .crossTraining
            workoutConfiguration.locationType = .indoor
            do {
                hkSession = try HKWorkoutSession(configuration: workoutConfiguration)
                hkSession?.delegate = self
            } catch {
                fatalError("Unable to create the workout session!")
            }
            healthStore.start(self.hkSession!)
            //timers
            self.hkTimer?.invalidate()
            self.hkTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(HeartRateController.endof30Sec), userInfo: nil, repeats: false)
            self.screenOffTimer?.invalidate()
            self.screenOffTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(HeartRateController.endof60Sec), userInfo: nil, repeats: false)
        }
    }
    
    @objc func endof30Sec()
    {
        self.hkTimer?.invalidate()
        self.sendHeartRatesToServer()
        self.workoutActive = false
        heartRateBtn.setHidden(false)
        self.heartRateBtn.setTitle("Check Again")
        if let workout = self.hkSession {
            self.healthStore.end(workout)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
            //exit(0);
        })
    }
    
    @objc func endof60Sec()
    {
        self.screenOffTimer?.invalidate()
        self.dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
            //exit(0);
        })
    }
    
    //*************HKSession Codes*************
    func activateHKSession(){
        guard HKHealthStore.isHealthDataAvailable() == true else {
            heartRateLabel.setText("not available")
            return
        }
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            heartRateLabel.setText("not allowed")
            return
        }
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success == false {
                print(error.debugDescription)
                print(error?.localizedDescription)
                self.heartRateLabel.setText("not allowed")
            }
        }
    }
    // define the activity type and location
    let heartRateUnit = HKUnit(from: "count/min")
    //var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    var currenHRQuery : HKQuery?
    
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            workoutDidStart(date)
        case .ended:
            workoutDidEnd(date)
        default:
            print("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // Do nothing for now
        print("Workout error")
    }
    
    
    func workoutDidStart(_ date : Date) {
        if let query = createHeartRateStreamingQuery(date) {
            self.currenHRQuery = query
            healthStore.execute(query)
        } else {
            heartRateLabel.setText("cannot start")
        }
    }
    
    func workoutDidEnd(_ date : Date) {
        healthStore.stop(self.currenHRQuery!)
        //heartRateLabel.setText("---")
        hkSession = nil
    }
    
    func createHeartRateStreamingQuery(_ workoutStartDate: Date) -> HKQuery? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return nil }
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictEndDate )
        //let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate])
        
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            //guard let newAnchor = newAnchor else {return}
            //self.anchor = newAnchor
            if(error != nil){
                print(error?.localizedDescription)
                print(error.debugDescription)
            }
            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            //self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
    
    func updateHeartRate(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        DispatchQueue.main.async {
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValue(for: self.heartRateUnit)
            let hr = Int(value)
            self.heartRateLabel.setText(String(hr))//(String(UInt16(value)))
            self.heartRates.append(hr)
            let hrSt = String(hr) + ","//" [" + String(hr) + "] "
            self.heartRatesAsStr = self.heartRatesAsStr + hrSt
            // retrieve source from sample
            let name = sample.sourceRevision.source.name
            self.updateDeviceName(name)
            self.animateHeart()
        }
    }
    
    func updateDeviceName(_ deviceName: String) {
        //        deviceLabel.setText(deviceName)
    }
    //
    func animateHeart() {
        //        self.animate(withDuration: 0.5) {
        //            self.heart.setWidth(60)
        //            self.heart.setHeight(90)
        //        }
        //        let when = DispatchTime.now() + Double(Int64(0.5 * double_t(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        //        DispatchQueue.global(qos: .default).async {
        //            DispatchQueue.main.asyncAfter(deadline: when) {
        //                self.animate(withDuration: 0.5, animations: {
        //                    self.heart.setWidth(50)
        //                    self.heart.setHeight(80)
        //                })            }
        //
        //
        //        }
    }
    
    var heartRates:[Int] = []
    var heartRatesAsStr:String = ""
    
//    struct Response: Codable {
//        let ReminderId: Int
//        let DateasString: String
//        let RemindedTime: String
//        let ResponseTime: String
//        let TimeGroup : Int
//        let AskedForDetails : Int
//        let AskedToRepeat : Int
//        let ReminderIndex: Int
//        let PatientId: Int
//        let ResponseResult: Int
//        let Interaction: String
//        let BatteryLevel: Int
//    }
    
    func sendHeartRatesToServer(){ //1=takenConfirmed,0=noResponse/dontremind 2=intermediate
        if(heartRates.count > 0){            
            print(heartRates)
            //let hr = HeartRateData(patientId: "1001", time: Date(), heartRates: heartRates)
            //print(hr)
            let iDelegate = WKExtension.shared().rootInterfaceController as? InterfaceController
            let currentReminder: NSMutableDictionary? = iDelegate?.currentReminder
            let patientId: Int = (iDelegate?.PatientId)!
            heartRatesAsStr = String(heartRatesAsStr.dropLast()) //remove , from last
            iDelegate?.sendSubjectResponseToServer(ReminderId: (currentReminder?["ReminderId"] as! Int), ReminderIndex: 0, ResponseResult: 6, Interaction: heartRatesAsStr, RemindedTime: currentReminder?["time"] as! String, TimeGroup: currentReminder?["TimeGroup"] as! Int)
            //
            //let response = iDelegate?.Response(ReminderId: (currentReminder?["ReminderId"] as! Int), DateasString: HelperMethods.currentDateNoAmPmAsString(), RemindedTime: (currentReminder!["time"] as? String)!, ResponseTime: HelperMethods.currentTime24AsString(), TimeGroup: (currentReminder!["TimeGroup"] as? Int)!, AskedForDetails: 0, AskedToRepeat: 0, ReminderIndex: 0, PatientId: patientId, ResponseResult: 6, Interaction: heartRatesAsStr)
            //guard let uploadData = try? JSONEncoder().encode(response) as NSData else {
                //return
            //}
            //HelperMethods.sendToServer(uploadData: uploadData)
            heartRates = []
            heartRatesAsStr = ""
            //guard let uploadData = try? JSONEncoder().encode(hr) else {
            //    return
            //}
            //HelperMethods.sendToServer(uploadData: uploadData)
        }
    }
}
