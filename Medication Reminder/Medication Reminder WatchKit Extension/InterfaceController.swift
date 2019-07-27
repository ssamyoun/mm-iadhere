//
//  InterfaceController.swift
//  Medication Reminder WatchKit Extension
//
//  Created by Abu Sayeed Mondol on 9/6/18.
//  Copyright © 2018 Sirat Samyoun. All rights reserved.
//

import WatchKit
import Foundation
import AVFoundation
import UserNotifications
import WatchConnectivity
import HealthKit

class InterfaceController: WKInterfaceController, UNUserNotificationCenterDelegate, AVSpeechSynthesizerDelegate, WCSessionDelegate {
    
    @IBOutlet var startBtn: WKInterfaceButton!
    @IBAction func startBtnAction() {
        currentReminder = remindersDictionary.values.randomElement()
        //  setcurrentRemindertoType(type: 3)
        setNotifAfterSeconds(sec: 3)
        //loadAlarm()
        //startDemo()
        super.willActivate()
    }
    @IBOutlet var prescriptionTable: WKInterfaceTable!    
    @IBOutlet var activityTitle: WKInterfaceLabel!
    @IBOutlet var activityImage: WKInterfaceImage!
    
    override func awake(withContext context: Any?) {//first time open app
        startBtn.setHidden(true) //after testing, demo button not needed anymore
        super.awake(withContext: context)
        checkConnectivityStatus()
        activateSessionInWatch()
        readPrescription()
        activateNotificationsOnWatch()
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        if(!UserDefaults.standard.bool(forKey: "firstlaunch1.0")){
            print("NOTIFICATIONS LOADED")
            loadAllNotifications()
            UserDefaults.standard.set(true, forKey: "firstlaunch1.0")
            UserDefaults.standard.synchronize();
        }
        switchToPrescriptionsListView()
        loadPrescriptionListView()
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    func switchToPrescriptionsListView(){
        activityTitle.setHidden(true)
        activityImage.setHidden(true)
        
        prescriptionTable.setHidden(false)
        //startBtn.setHidden(false)
    }
    
    func switchToActivityView(){
        prescriptionTable.setHidden(true)
        //startBtn.setHidden(true)
        
        activityTitle.setHidden(false)
        activityImage.setHidden(false)
    }
    
    func switchToBlankView(){
        prescriptionTable.setHidden(true)
        //startBtn.setHidden(true)
        activityTitle.setHidden(true)
        activityImage.setHidden(true)
    }
    
    //------------reminder functions-----------
    
    public var currentReminder: NSMutableDictionary?
    public var remindersDictionary = [Int : NSMutableDictionary]()
    public var serialDictionary = [Int : Int]()
    
    public var currentConversation: String = ""
    public var currentResponseResult: Int = 0 // final state
    var currentPrescriptionType: Int = 0
    var currentResponseText = ""
    var currentAskedDetails: Int = 0 // intermediate state
    var currentAskedtoRepeat: Int = 0 // intermediate state
    
    var dontExit: Bool = false
    var conversationFinished = false

    public enum ResponseType: Int {
        case noResponse = 0
        case notified = 1
        case clicked = 2
        case respondedNotUnderstood = 3
        case respondedWithStop = 4
        case respondedWithPostpone = 5 //count as accept later
        case respondedWithConfirmedTaking = 6
        case respondedWithAskedDetails = 7
        case respondedWithRepeat = 8
    } //if these values are changed, change in HRController and index.ejs in server as well
    //=>2 count as responded, 6/5 as accepted, <2 as didnt respond, 4 as not accepted/stopeed,
    
//    public func setIndexOfReminder(rId: Int, rSerial: Int){
//        serialDictionary[rId] = rSerial
//    }
//
//    public func getIndexOfReminder(rId: Int) -> Int{
//        return serialDictionary[rId]!
//    }
//
//    public func isRemindersNotFull(rId: Int) -> Bool{
//        let remSerial: Int = serialDictionary[rId]!
//        if (remSerial < 2){
//            return true
//        }
//        return false
//    }
//
//    public func incrementRemindersIdx(rId: Int){
//        serialDictionary[rId] = serialDictionary[rId]! + 1
//    }
    
    private func readPrescription() {
        if let path = Bundle.main.path(forResource: "prescription_Watch", ofType: "json") {
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSData.ReadingOptions.mappedIfSafe)
                do {
                    let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    let allDailyReminders = jsonResult["events"] as? [NSMutableDictionary]
                    for item in allDailyReminders! {
                        let medCode: Int = (item["ReminderId"] as? Int)!
                        item["reminded"] = 0
                        remindersDictionary[medCode] = item as? NSDictionary as! NSMutableDictionary
                    }
                } catch {}
            } catch {}
        }
    }
    
    func handleFirstResponse(){
        if (currentResponseText.isEmpty == false) {
            var responseStr = currentResponseText
            currentResponseText = ""
            currentConversation = currentConversation + " U: " + responseStr + " \n"
            currentResponseResult = ResponseType.respondedNotUnderstood.rawValue //not yet
            responseStr = responseStr.lowercased()
            if (responseStr.contains("yes") || responseStr.contains("done") || responseStr.contains("did")
                || responseStr.contains("yeah") || responseStr.contains("sure") || responseStr.contains("taken") || responseStr.contains("took")
                ){
                currentResponseResult = ResponseType.respondedWithConfirmedTaking.rawValue
                conversationFinished = true
                if(currentPrescriptionType == 3)
                {
                    dontExit = true
                    utterSentence(line: "Ok. Hold your wrist and Look at the watch.");
                    loadHKController()
                } else if (currentPrescriptionType == 4){
                    utterSentence(line: "Ok. Press the crown to go to Apps, tap on the ECG app, and follow the instructions.")
                    //exit(0)
                } else if (responseStr.contains("thank")){
                    utterSentence(line: "You are welcome.");
                } else{
                    utterSentence(line: "Ok. Thank you.");
                }
                //if (type=3)utter(look at watch) else if(thank)utter(welcome) else(thanku)
            }
            else if (responseStr.contains("how") || responseStr.contains("details") || responseStr.contains("describe") || responseStr.contains("more")){
                //currentResponseResult = ResponseType.respondedWithAskedDetails.rawValue //doesnt hold any significant coz we recorded different value
                currentAskedDetails = 1
                let details:String = (currentReminder!["details"] as? String)!
                utterSentence(line: details)
            }
            else if (responseStr.contains("repeat") || responseStr.contains("what") || responseStr.contains("again")) {
                //currentResponseResult = ResponseType.respondedWithRepeat.rawValue
                currentAskedtoRepeat = 1
                let query:String = (currentReminder!["query"] as? String)!
                utterSentence(line: query)
            }
            else if (responseStr.contains("remind")) {
                if (responseStr.contains("don't") || responseStr.contains("do not")){
                    currentResponseResult = ResponseType.respondedWithStop.rawValue
                    conversationFinished = true
                }
                else if (responseStr.contains("later")){
                    currentResponseResult = ResponseType.respondedWithPostpone.rawValue
                    let requeryTime: String = (currentReminder!["requery_interval"] as? String)!
                    let reqStrArr = requeryTime.components(separatedBy: ":")
                    let mn: Int = Int(reqStrArr[1])!
                    utterSentence(line: "Ok. Remind you after \(mn) minutes");
                    setCurrentReminderAfterNminutes(mn: mn)
                }
                else if (responseStr.contains("minute")){
                    currentResponseResult = ResponseType.respondedWithPostpone.rawValue
                    let wordsArr = responseStr.components(separatedBy: " ")
                    var indexOfMin: Int = 0
                    for (idx, str) in wordsArr.enumerated(){
                        if(str.contains("minute")){
                            indexOfMin = idx - 1
                            break
                        }
                    }
                    if(indexOfMin >= 0){
                        if(CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: wordsArr[indexOfMin]))){
                            let mn: Int = Int(wordsArr[indexOfMin])!
                            utterSentence(line: "Ok. Remind you after \(mn) minutes");
                            setCurrentReminderAfterNminutes(mn: mn)
                        } else{
                            let mn: Int = HelperMethods.wordToNumber(word: wordsArr[indexOfMin])//2  //extensiveLater
                            utterSentence(line: "Ok. Remind you after \(mn) minutes");
                            setCurrentReminderAfterNminutes(mn: mn)
                        }
                    }
                } else if (responseStr.contains("thank")){ //"thanks for reminding" type response
                    conversationFinished = true //currentResponseResult unchnaged
                    utterSentence(line: "You are welcome.")
                }
            }
            else if (responseStr.contains("thank")){
                conversationFinished = true //currentResponseResult unchnaged
                utterSentence(line: "You are welcome.")
            } else if(responseStr.contains("ok")||responseStr.contains("ll do") || responseStr.contains("ll check") || responseStr.contains("ll take")){
                currentResponseResult = ResponseType.respondedWithConfirmedTaking.rawValue
                conversationFinished = true
                utterSentence(line: "Ok. Thank you.")
            }
            else{
                //said other than keywords, what now? //currentResponseResult unchnaged
                conversationFinished = true
                switchToPrescriptionsListView()
                //thank you??
            }
        }else{
            //said nothing, pressed done, what now? //currentResponseResult unchnaged
            conversationFinished = true
            switchToPrescriptionsListView() //jekhane system utter kortese na, maane system er bolar kichunai, sekhane prescriptionview
        }
        //adding for sending app to background
        //in NotifController, after 40 secs of notif arrival it sets renotif after 1*60 mins if notif not clickedorinteracted yet, that is currentResponseResult<2
        if(conversationFinished == true){
            //this 5sec is not important,conversationFinished does everything, but overall click/start talking has to be started within 40 secs mentioned in notifcontroller
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
                self.sendSubjectResponseToServer(ReminderId: (self.currentReminder?["ReminderId"] as! Int), ReminderIndex: (self.currentReminder!["reminded"] as! Int), ResponseResult: self.currentResponseResult, Interaction: self.currentConversation)  //Interaction: HelperMethods.convertDictionaryToString(dic: self.currentInteractions)
                if(self.dontExit == false){
                    //exit(0);//should related to server send
                }
            })
        }
    }
    
//    func setCurrentReminderAfterNminutes(mn:Int){
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(mn * 60), repeats: false)
//        let reminder: NSMutableDictionary = currentReminder!.mutableCopy() as! NSMutableDictionary
//        reminder["query"] = currentReminder?["requery"]
//        addRemindderNotification(trigger: trigger, reminder: reminder, repeatedReminder: false)
//    }
    
    func setRepeatingReminderAsPerSerialIdentifer(reminder: NSMutableDictionary, mn: Int) -> String{
        let serialIdentifier = reminder["serialIdentifier"] as! String
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(mn * 60), repeats: false)
        if(serialIdentifier == "org")
        {
            addReminderNotification(trigger: trigger, reminder: reminder, serialIdentifier: "uno")
        }
        else if(serialIdentifier == "uno")
        {
            addReminderNotification(trigger: trigger, reminder: reminder, serialIdentifier: "duo")
        }
    }
    
    var watchBatteryPercentage:Int {
        return Int(roundf(WKInterfaceDevice.current().batteryLevel * 100))
    }
    
    public func loadAlarm() {
        currentResponseText = ""
        conversationFinished = false
        currentResponseResult = ResponseType.clicked.rawValue
        currentConversation = ""
        currentAskedtoRepeat = 0
        currentAskedDetails = 0
        dontExit = false
        WKInterfaceDevice.current().play(.success)
        WKInterfaceDevice.current().play(.click)
        currentPrescriptionType = (currentReminder!["type"] as? Int)!
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
        activityTitle.setText(medName)
        switchToActivityView()
        let query:String = (currentReminder!["query"] as? String)!
        //let user see the medicine name for 1 sec
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.utterSentence(line: query)
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(15), execute: {
            if(self.currentResponseResult == 2){ //ended at clicked
                self.sendSubjectResponseToServer(ReminderId: (self.currentReminder?["ReminderId"] as! Int), ReminderIndex: (self.currentReminder!["reminded"] as! Int), ResponseResult: self.currentResponseResult, Interaction: "")
                self.switchToPrescriptionsListView()
                //exit(0)
                //right now exits are for interactinos finished scene only, except if its not heartrate check beginning interaction
            }
        })
    }
    
    //------------notification functions-----------
    var nfIdIssuedAfterNext10Mins = [String]()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound,.alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        //clicked
        let content = response.notification.request.content
        let dc = content.userInfo as NSDictionary
        currentReminder = dc.mutableCopy() as! NSMutableDictionary
        //currentReminder!["reminded"] = 2
        //let rId: Int = (currentReminder!["ReminderId"] as? Int)!
//        if(isRemindersNotFull(rId: rId)){
//            incrementRemindersIdx(rId: rId)
//        }
        //setIndexOfReminder(rId: rId, rSerial: 2)
        //notificationClicked = true
        do {
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        } catch {
        }
        completionHandler()
        loadAlarm()
    }
    
    func activateNotificationsOnWatch(){
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound,.alert]) { (granted, error) in
            if granted == false {
                print("Launch Notification Error: \(error?.localizedDescription)")
            }
        }
        let notificationCategory = UNNotificationCategory(identifier: "medicine.category", actions: [], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([notificationCategory])
    }
    
    func loadAllNotifications(){
        for item in remindersDictionary.values {
            let dateStr: String = (item["time"] as? String)!
            let dateStrArr = dateStr.components(separatedBy: ":")
            var date = DateComponents()
            date.hour = Int(dateStrArr[0])!
            date.minute = Int(dateStrArr[1])!
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            addReminderNotification(trigger: trigger, reminder: item, serialIdentifier: "org")
        }
    }
    
    func setNotifAfterSeconds(sec: Int){
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(sec), repeats: false)
        addReminderNotification(trigger: trigger, reminder: currentReminder!, serialIdentifier: "test")
    }
    
    func getNotificationContent(reminder:NSMutableDictionary) -> UNMutableNotificationContent{
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        let reminderType = (reminder["type"] as? Int)!
        if(reminderType == 1){
            content.subtitle = "Pill Time"
        }else if(reminderType == 2){
            content.subtitle = "Exercise Time"
        }else if(reminderType == 3){
            content.subtitle = "Heartbit Check Time"
        }else if(reminderType == 4){
            content.subtitle = "ECG Check Time"
        }else if(reminderType == 5){
            content.subtitle = "Activities"
        }
        content.body = HelperMethods.convertToPmAmFormat(str: (reminder["time"] as? String)!)
        content.sound = UNNotificationSound.default()
        //content.attachments = pillImageInNotification()
        content.categoryIdentifier = "medicine.category"
        content.userInfo = reminder as? NSDictionary as? [AnyHashable: Any] ?? [:]
        return content
    }
    
//    func addNotification(trigger: UNNotificationTrigger, reminder: NSMutableDictionary, repeatedReminder: Bool){
//        let content = getNotificationContent(reminder: reminder)
//        let uuId = HelperMethods.stringWithUUID()
//        let request = UNNotificationRequest(identifier: uuId, content: content, trigger: trigger)
//        UNUserNotificationCenter.current().add(request) { (notificationError) in
//            if(notificationError == nil){
//                if(repeatedReminder){
//                    self.nfIdIssuedAfterNext10Mins.append(uuId)
//                }
//            }
//        }
//    }
    
    func addReminderNotification(trigger: UNNotificationTrigger, reminder: NSMutableDictionary, serialIdentifier: String){
        reminder["serialIdentifier"] = serialIdentifier
        let content = getNotificationContent(reminder: reminder)
        let uuId = HelperMethods.stringWithUUID()
        let request = UNNotificationRequest(identifier: uuId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (notificationError) in
            if(notificationError == nil){
//                if(repeatedReminder){
//                    self.nfIdIssuedAfterNext10Mins.append(uuId)
//                }
            }
        }
    }
    
//    func pillImageInNotification()->[UNNotificationAttachment]{
//        let path = Bundle.main.path(forResource: "Pill_Watch", ofType: "png")
//        let photoURL = URL(fileURLWithPath: path!)
//        do {
//            let attachment = try UNNotificationAttachment(identifier: "Medicine.Photo", url: photoURL, options: nil)
//            return [attachment]
//        } catch {
//            print("the attachment was not loaded")
//            return []
//        }
//    }
    //------------text-to-speech functions-----------
    private var synth: AVSpeechSynthesizer?
    var myUtterance = AVSpeechUtterance(string: "")
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if(conversationFinished == false){
            self.currentResponseText = ""
            let textChoices = ["Yes/Taking now","Don't remind","Remind me later","Tell me details"]
            if(connectedToInternet){
                InitiateDictation(textChoices: []) //[]
            }else{
                InitiateDictation(textChoices: textChoices)
            }
            //switchToBlankView()
        }
        else{
            self.switchToPrescriptionsListView()
        }
    }
    
    func utterSentence(line: String ){
        synth = AVSpeechSynthesizer()
        myUtterance = AVSpeechUtterance(string: line)
        synth?.delegate = self
        myUtterance.rate = 0.5
        currentConversation = currentConversation + " S: " + line + " \n"
        synth?.speak(myUtterance)
        checkConnectivityStatus()
    }
    
    //-----------speech-to-text--------
    func InitiateDictation(textChoices: [String]){
        presentTextInputController(withSuggestions: textChoices, allowedInputMode:WKTextInputMode.plain, completion: {(results) -> Void in
            if results != nil && results!.count > 0 {
                self.currentResponseText = (results?[0] as? String)!
                self.handleFirstResponse()
            }
        })
    }
    
    //------------session functions-----------
    var session: WCSession?
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
    }
    
    func activateSessionInWatch(){
        session = WCSession.default()
        session?.delegate = self
        session?.activate()
    }
    
    //------------healthkit functions-----------
    func loadHKController(){
        presentController(withName: "HRController", context: ["segue": "pagebased","data": "Passed through page-based navigation"])
    }
    
    //---------other functions------------
    var connectedToInternet : Bool = true
    func checkConnectivityStatus(){
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        let sesh = URLSession(configuration: config)
        let url = URL(string: "https://apple.com")! //
        var request = URLRequest(url: url)
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData //removes error
        sesh.dataTask(with: request) { (_, _, error) in
            self.connectedToInternet = (error == nil)
            }.resume()
        /*if let url = URL(string: "https://apple.com") {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            URLSession(configuration: .default)
                .dataTask(with: request) { (_, _, error) in
                    self.connectedToInternet = (error == nil)
                }.resume()
        }*///https://stackoverflow.com/questions/48982014/network-reachability-check-in-watchkit
    }
    
    public struct Response: Codable {
        let ReminderId: Int
        let DateasString: String
        let RemindedTime: String
        let ResponseTime: String
        let TimeGroup : Int
        let AskedForDetails : Int
        let AskedToRepeat : Int
        let ReminderIndex: Int
        let ResponseResult: Int
        let PatientId: Int
        let Interaction: String
        let BatteryLevel: Int
    }
    
    public func sendSubjectResponseToServer(ReminderId: Int, ReminderIndex: Int, ResponseResult: Int, Interaction: String){
        let response = Response(ReminderId: ReminderId, DateasString: HelperMethods.currentDateNoAmPmAsString(), RemindedTime: (currentReminder!["time"] as? String)!, ResponseTime: HelperMethods.currentTime24AsString(), TimeGroup: (currentReminder!["TimeGroup"] as? Int)!, AskedForDetails: currentAskedDetails, AskedToRepeat: currentAskedtoRepeat, ReminderIndex: ReminderIndex, ResponseResult: ResponseResult, PatientId: PatientId, Interaction: Interaction, BatteryLevel: watchBatteryPercentage)
        print(response)
        guard let uploadData = try? JSONEncoder().encode(response) as NSData else {return}
        HelperMethods.sendToServer(uploadData: uploadData)
        //ClearFileContents()
        //file_approach(r: response)
    }
    
    //---------to be thrown away layer-----------
//    @IBOutlet var demoButton: WKInterfaceButton!
//    @IBAction func demoBtnAction() {
//        currentReminder = remindersDictionary.values.randomElement()
//        //print(String((currentReminder?["ReminderId"] as! Int)) + "Id")
//        //setcurrentRemindertoType(type: 3)
//
//        //switchToAlarm()
//        setNotifAfterSeconds(sec: 3)
//
//        //startDemo()
//        //loadPrescriptionsVC() //WKInterfaceController.reloadRootControllers(withNames: ["PrescriptionController"], contexts: nil)
//    }
    
    func setcurrentRemindertoType(type: Int){
        for item in remindersDictionary.values {
            let reminderType = (item["type"] as? Int)!
            if(reminderType == type){
                currentReminder = item
                break;
            }
        }
    }
    
    func loadPrescriptionListView(){
        prescriptionTable.setNumberOfRows(remindersDictionary.count, withRowType: "PrescriptionList")
        var index: Int = 0
        let sortRem = remindersDictionary.sorted(by:{ $0.key < $1.key })
        for prescription in sortRem{
            let prescripMins = HelperMethods.ConvertToMinutes(str: prescription.value["time"] as! String)
            let currentMins = HelperMethods.CurrentTimeToMinutes()
            if(currentMins < prescripMins){
                //set reminder 0
                prescription.value["Taken"] = 0
            }

            var time: String = "\(prescription.value["time"])"
            time = String(time.dropFirst(9))
            time = String(time.dropLast(4))
            var check:Int = Int(String(time.dropLast(3))) ?? 0

            if check > 12 {
                check = check - 12
                time = String(time.dropFirst(2))
                time = String(check) + time + " PM"
            }else if check == 12 {
                time = time + " PM"
            }else if check == 0 {
                time = String(time.dropFirst(2))
                time = String(12) + time + " AM"
            }else{
                time = time + " AM"
            }
            var text: String = "\(prescription.value["display_text"])"
            text = String(text.dropFirst(9))
            text = String(text.dropLast(1))
            let row = prescriptionTable.rowController(at: index) as! PrescriptionList
            row.prescriptionLbl.setText(time + " " + text)
            index = index+1

            //let t: Int = prescription.value["Taken"] as! Int

            //if t == 1{
            //    row.PrescriptionLbl.setTextColor(UIColor(red: 0.8588, green: 0.1137, blue: 0, alpha: 1.0) )
            //}else if t == 2{
                //row.prescriptionLbl.setTextColor(UIColor(red: 0.2431, green: 0.5882, blue: 0, alpha: 1.0) )
           // }
        }
    }
    
    func loadActivityDetailsVC() {
        presentController(withName: "ActivityDetailsController",
                          context: ["segue": "pagebased",
                                    "data": "Passed through page-based navigation"])
        
    }
    

    
    public var PatientId: Int = 2002
    private var localServer: String = "http://172.26.134.73:3000"
    private var remoteServer: String = "http://ec2-18-188-221-234.us-east-2.compute.amazonaws.com:3000/"
    private var testServer: String = "http://ptsv2.com/t/1te8r-1532622698/post"
    
    func startDemo() {
        let r1 = Response(ReminderId: 1, DateasString: HelperMethods.currentDateNoAmPmAsString(), RemindedTime: (currentReminder!["time"] as? String)!, ResponseTime: HelperMethods.currentTime24AsString(), TimeGroup: (currentReminder!["TimeGroup"] as? Int)!, AskedForDetails: currentAskedDetails, AskedToRepeat: currentAskedtoRepeat, ReminderIndex: 1, ResponseResult: 3, PatientId: PatientId, Interaction: "4:47:35 PM, S: It\'s the time to check your heart-rate. Do you want to check it now? \n4:47:43 PM, U: Don\'t remind \n", BatteryLevel: watchBatteryPercentage)
        let r2 = Response(ReminderId: 2, DateasString: HelperMethods.currentDateNoAmPmAsString(), RemindedTime: (currentReminder!["time"] as? String)!, ResponseTime: HelperMethods.currentTime24AsString(), TimeGroup: (currentReminder!["TimeGroup"] as? Int)!, AskedForDetails: currentAskedDetails, AskedToRepeat: currentAskedtoRepeat, ReminderIndex: 2, ResponseResult: 4, PatientId: PatientId, Interaction: "8:47:35 PM, S: It\'s the time to check your heart-rate. Do you want to check it now? \n8:47:43 PM, U: Don\'t remind \n",BatteryLevel: watchBatteryPercentage)
        responseDictionary.removeAll()
        responseDictionary[String(r1.ReminderId) + "_" + r1.DateasString] = convertStructToString(response: r1)
        ConvDicToDataThenWriteToFile()
        responseDictionary.removeAll()
        //code starts here after test part
        ReadFromFileThenConvDataToDic()
        ClearFileContents()
        responseDictionary[String(r2.ReminderId) + "_" + r2.DateasString] = convertStructToString(response: r2)
        ConvDicToDataThen_SendToServer_WritetoFile()
    }
    
    public func file_approach(r: Response){
        ReadFromFileThenConvDataToDic()
        ClearFileContents()
        responseDictionary[String(r.ReminderId) + "_" + r.DateasString] = convertStructToString(response: r)
        ConvDicToDataThen_SendToServer_WritetoFile()
    }
    
    func convertStructToString(response: Response)-> String
    {
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(response)
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString!
        } catch {
            print(error)
        }
        return ""
    }
    
    func ReadFromFileThenConvDataToDic()
    {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent("toWrite.json")
            do {
                let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                if(json != nil){
                    responseDictionary = (json as? [String: String])!
                    print(responseDictionary)
                }
            }
            catch {}
        }
    }
    
    func ConvDicToDataThenWriteToFile()
    {
        if JSONSerialization.isValidJSONObject(responseDictionary) {
            if let dataToSend = try? JSONSerialization.data(withJSONObject: responseDictionary, options: []) {
                WriteDatatoFile(data: dataToSend)
            }
        }
    }
    

    func ConvDicToDataThen_SendToServer_WritetoFile()
    {
        if JSONSerialization.isValidJSONObject(responseDictionary) {
            if let dataToSend = try? JSONSerialization.data(withJSONObject: responseDictionary, options: []) {
                let strId = "randStr" + String(Int.random(in: 0..<100))
                print(strId)
                let configuration = URLSessionConfiguration.background(withIdentifier: strId)
                configuration.timeoutIntervalForRequest = 300
                configuration.timeoutIntervalForResource = 300
                configuration.waitsForConnectivity = true
                let session = URLSession(configuration: configuration)//let session = URLSession.shared
                let url = URL(string: localServer)!
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                //request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")//this has been commented after changing NSData to Data
                request.httpBody = dataToSend
                let task = URLSession.shared.dataTask(with: request) {
                    data, response, error in
                    if error != nil {
                        self.WriteDatatoFile(data: dataToSend)
                        return
                    }
                }
                task.resume()
            }
        }
    }
    
    public func ClearFileContents()
    {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent("toWrite.json")
            do {
                try "".write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {}
        }
    }
    
    func WriteDatatoFile(data: Data)
    {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent("toWrite.json")
            do {
                try data.write(to: fileURL, options: .atomic)
            }
            catch {}
        }
    }
    
    private var responseDictionary = [String : String]()
}
