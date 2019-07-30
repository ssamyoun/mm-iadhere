//
//  ViewController.swift
//  Medication Reminder
//
//  Created by Abu Sayeed Mondol on 9/6/18.
//  Copyright © 2018 Sirat Samyoun. All rights reserved.
//

import UIKit
import UserNotifications
import WatchConnectivity
import Speech
import AVFoundation

class ViewController: UIViewController, UNUserNotificationCenterDelegate, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate, WCSessionDelegate {
    
    //------------built-in functions-----------
    override func viewDidLoad() {
        //demoButton.isHidden = true
        super.viewDidLoad()
        authorizeSpeechFramework()
        activateSessionInPhone()
        //readPrescription()
        setReminderNotificationsInPhone()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //------------reminder functions-----------
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pillImage: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    private var currentReminder: NSDictionary?
    private var remindersDictionary = [String : NSDictionary]()
    
    var currentResponseText = ""
    var conversationFinished = false
    var notificationsLoaded = false
    
    private func readPrescription() {
        if let path = Bundle.main.path(forResource: "prescription_Phone", ofType: "json") {
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSData.ReadingOptions.mappedIfSafe)
                do {
                    let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    let allDailyReminders = jsonResult["events"] as? [NSMutableDictionary]
                    for item in allDailyReminders! {
                        let medCode: String = (item["query_code"] as? String)!
                        remindersDictionary[medCode] = item as? NSDictionary
                    }
                } catch {}
            } catch {}
        }
    }
    
    func handleFirstResponse(){
        if (currentResponseText.isEmpty == false) {
            let responseStr = currentResponseText.lowercased()
            currentResponseText = ""
            if (responseStr.contains("yes") || responseStr.contains("done") || responseStr.contains("did")
                || responseStr.contains("yeah") || responseStr.contains("taken") || responseStr.contains("took")
                || responseStr.contains("ok")){
                conversationFinished = true
                if (responseStr.contains("thank")){
                    utterSentence(line: "You are welcome.");
                }
                else{
                    utterSentence(line: "Ok. Thank you.");
                    //WKInterfaceDevice.current().play(.click)
                }
                sendResponseToServer(flag: 1, reply: responseStr, medName: (currentReminder!["med_name"] as? String)!)
                //loadNextReminder()
            }
            else if (responseStr.contains("details") || responseStr.contains("more")){
                let details:String = (currentReminder!["details"] as? String)!
                sendResponseToServer(flag: 2, reply: responseStr, medName: (currentReminder!["med_name"] as? String)!)
                utterSentence(line: details)
                //what now? set remind after 2?
            }
            else if (responseStr.contains("repeat") || responseStr.contains("what") || responseStr.contains("again")) {
                let query:String = (currentReminder!["query"] as? String)!
                sendResponseToServer(flag: 2, reply: responseStr, medName: (currentReminder!["med_name"] as? String)!)
                utterSentence(line: query)
                //what now? set remind after 2?
            }
            else if (responseStr.contains("remind")) {
                if (responseStr.contains("don't") || responseStr.contains("do not")){
                    conversationFinished = true
                    switchToBeginUI()
                    sendResponseToServer(flag: 0, reply: responseStr, medName: (currentReminder!["med_name"] as? String)!)
                }
                else if (responseStr.contains("later")){
                    let requeryTime: String = (currentReminder!["requery_interval"] as? String)!
                    let reqStrArr = requeryTime.components(separatedBy: ":")
                    let mn: Int = Int(reqStrArr[1])!
                    //conversationFinished = true
                    utterSentence(line: "Ok. Remind you after \(mn) minutes");
                    switchToBeginUI()
                    sendResponseToServer(flag: 2, reply: responseStr, medName: (currentReminder!["med_name"] as? String)!)
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(mn * 60), repeats: false)
                    addNotification(trigger: trigger, dictionary: currentReminder!)
                }
                else if (responseStr.contains("minute")){
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
                            switchToBeginUI()
                            sendResponseToServer(flag: 2, reply: responseStr, medName: (currentReminder!["med_name"] as? String)!)
                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(mn * 60), repeats: false)
                            addNotification(trigger: trigger, dictionary: currentReminder!)
                        }else{
                            let mn: Int = wordToNumber(word: wordsArr[indexOfMin])//2
                            //translate
                            utterSentence(line: "Ok. Remind you after \(mn) minutes");
                            switchToBeginUI()
                            sendResponseToServer(flag: 2, reply: responseStr, medName: (currentReminder!["med_name"] as? String)!)
                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(mn * 60), repeats: false)
                            addNotification(trigger: trigger, dictionary: currentReminder!)
                        }
                    }
                }
            }
            else if (responseStr.contains("thank")){
                conversationFinished = true
                utterSentence(line: "You are welcome.");
            }
            else{
                //said other than keywords, what now?
                conversationFinished = true
                switchToBeginUI()
                sendResponseToServer(flag: 0, reply: responseStr, medName: (currentReminder!["med_name"] as? String)!)
            }
        }else{
            //said nothing, pressed done, what now?
            conversationFinished = true
            switchToBeginUI()
            sendResponseToServer(flag: 0, reply: "", medName: (currentReminder!["med_name"] as? String)!)
        }
    }
    
    func switchToBeginUI(){
        //demoButton.isHidden = false
        pillImage.image = nil
        //titleLabel.text = "Medication Reminder"
        textView.text = ""
    }
    
    func switchToAlarm(){
        currentResponseText = ""
        conversationFinished = false
        let medName:String = (currentReminder!["med_name"] as? String)!
        let query:String = (currentReminder!["query"] as? String)!
        titleLabel.text = medName
        let type:Int = (currentReminder!["type"] as? Int)!
        if(type == 2){
            pillImage.image = UIImage(named: "Exercise_Phone.png")
        }else if(type == 3){
            pillImage.image = UIImage(named: "heart-rate_Phone.jpg")
        }else{
            pillImage.image = UIImage(named: "Pill_Phone.png")
        }
        utterSentence(line: query)
        sendReminderToServer(flag: 2, reminder: query, medName: medName)
    }
    
    //------------notification functions-----------
//    func didReceive(_ request: UNNotificationRequest,
//                    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
//        print(request.content.body)
//    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.badge,.sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let content = response.notification.request.content
        currentReminder = content.userInfo as NSDictionary
        do {
            UNUserNotificationCenter.current().removeAllDeliveredNotifications() //onclick
        } catch {
        }
        completionHandler()
        switchToAlarm()
    }
    
    func setReminderNotificationsInPhone(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge], completionHandler: {
            (granted,error) in
            if granted {
                self.setNotificationCategories()  // add categories to the app
                UNUserNotificationCenter.current().delegate = self
                if(!self.notificationsLoaded){
                    self.loadAllNotifications()
                    self.notificationsLoaded = true
                }
            }
        })
    }
    
    func setNotificationCategories(){
        //let openAction = UNNotificationAction(identifier: "open.action", title: "See Reminder", options: [])
        //let dismissAction = UNNotificationAction(identifier: "close.action", title: "Dismiss", options: [])
        let notificationCategory = UNNotificationCategory(identifier: "medicine.category", actions: [], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([notificationCategory])
    }
    
    func loadAllNotifications(){
        for item in remindersDictionary.values {
            let dateStr: String = (item["time"] as? String)!
            let dateStrArr = dateStr.components(separatedBy: ":")
            let hr: Int = Int(dateStrArr[0])!
            let mn: Int = Int(dateStrArr[1])!
            //let sc: Int = Int(dateStrArr[2])!
            var date = DateComponents()
            date.hour = hr//18
            date.minute = mn//04
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            addNotification(trigger: trigger, dictionary: item)
        }
    }
    
    func addNotification(trigger:UNNotificationTrigger, dictionary: NSDictionary){
        let content = UNMutableNotificationContent()
        content.title = "View Reminder"
        content.body = (dictionary["med_name"] as? String)! + " at " + convertToPmAmFormat(str: (dictionary["time"] as? String)!)
        content.sound = UNNotificationSound.default()
        content.attachments = pillImageInNotification()
        content.categoryIdentifier = "medicine.category"
        content.userInfo = dictionary as? [AnyHashable: Any] ?? [:]
        
        let request = UNNotificationRequest(identifier: stringWithUUID(), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) {
            (notificationError) in
            if let error = notificationError{
                print("^Error: \(error.localizedDescription)")
            }
        }
    }
    
    func pillImageInNotification()->[UNNotificationAttachment]{
        let path = Bundle.main.path(forResource: "Pill_Phone", ofType: "png")
        let photoURL = URL(fileURLWithPath: path!)
        do {
            let attachment = try UNNotificationAttachment(identifier: "Medicine.Photo", url: photoURL, options: nil)
            return [attachment]
        } catch {
            print("the attachment was not loaded")
            return []
        }
    }
    
    //------------speech-to-text functions-----------
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    fileprivate var timer:Timer?
    
    func authorizeSpeechFramework(){
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isButtonEnabled = false
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
        }
    }
    
    func initiateSpeechRecordSession() {
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        let inputNode = audioEngine.inputNode
        //let recognitionRequest = recognitionRequest
//        guard let inputNode = audioEngine.inputNode else {
//            fatalError("Audio engine has no input node")
//        }  //4
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        recognitionRequest.shouldReportPartialResults = true  //6
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            var isFinal = false  //8
            if result != nil{ // && self.conversationFinished == false
                let responseStr:String = (result?.bestTranscription.formattedString)!  //9
                if(self.conversationFinished == false){
                    self.currentResponseText = responseStr
                    if(self.currentResponseText.isEmpty == false){
                        self.startSpeechRecordTimer()
                    }
                    self.textView.text = self.currentResponseText
                }
                isFinal = (result?.isFinal)!
            }
            if error != nil || isFinal {  //10
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        })
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()  //12
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        textView.text = "Please Say Something!"
    }
    
    func closeSpeechRecordSession(){
        if audioEngine.isRunning {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSessionCategoryPlayback)
                try audioSession.setActive(false, with: .notifyOthersOnDeactivation)
            } catch {
            }
            audioEngine.stop()
            recognitionRequest?.endAudio()
            textView.text = ""
        }
    }
    
    func startSpeechRecordTimer(){
        OperationQueue.main.addOperation({[unowned self] in
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { (_) in
                self.timer?.invalidate()
                self.closeSpeechRecordSession()
                self.handleFirstResponse()
            }
        })
    }
    
    //------------text-to-speech functions-----------
    private var synth: AVSpeechSynthesizer?
    var myUtterance = AVSpeechUtterance(string: "")
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if(conversationFinished == false){
            self.currentResponseText = ""
            initiateSpeechRecordSession()
            startSpeechRecordTimer()
        }else{
            switchToBeginUI()
        }
    }
    
    func utterSentence(line: String ){
        synth = AVSpeechSynthesizer()
        myUtterance = AVSpeechUtterance(string: line)
        synth?.delegate = self
        myUtterance.rate = 0.4
        synth?.speak(myUtterance)
    }
    
    //------------session functions-----------
    var session: WCSession?
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let msg = message["Remind"] as! String
        let msgArr = msg.components(separatedBy: "_")
        currentReminder = remindersDictionary[msgArr[0]]
        let mn: Int = Int(msgArr[1])!
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(mn * 60), repeats: false)
        addNotification(trigger: trigger, dictionary: currentReminder!)
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) { }

    func activateSessionInPhone(){
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    //---------other functions------------
    struct Adherence: Codable {
        let patientId: String
        let med: String
        let taken: Int
        let time: Date
        let reply: String
    }
    
    struct Reminder: Codable {
        let patientId: String
        let med: String
        let notified: Int
        let time: Date
        let reminder: String
    }
    
    func sendResponseToServer(flag: Int, reply:String, medName: String){ //1=takenConfirmed,0=noResponse/dontremind 2=intermediate
        let adherence = Adherence(patientId: "1001", med: medName, taken: flag, time: Date() ,reply: reply)
        guard let uploadData = try? JSONEncoder().encode(adherence) else {
            return
        }
        sendToServer(uploadData: uploadData)
    }
    
    func sendReminderToServer(flag: Int, reminder:String, medName: String){ //1=takenConfirmed,0=noResponse/dontremind 2=intermediate
        let reminder = Reminder(patientId: "1001", med: medName, notified: flag, time: Date() ,reminder: reminder)
        guard let uploadData = try? JSONEncoder().encode(reminder) else {
            return
        }
        sendToServer(uploadData: uploadData)
    }
    
    func sendToServer(uploadData:Data){
        ///////////
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 120
        configuration.waitsForConnectivity = true
        let session = URLSession(configuration: configuration)
        //let session = URLSession.shared
        let url = URL(string: "http://ptsv2.com/t/1te8r-1532622698/post")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                    print ("server error")
                    return
            }
            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data,
                let dataString = String(data: data, encoding: .utf8) {
                print ("got data: \(dataString)")
            }
        }
        task.resume()
    }
    
    func stringWithUUID() -> String {
        let uuidObj = CFUUIDCreate(nil)
        let uuidString = CFUUIDCreateString(nil, uuidObj)!
        return uuidString as String
    }
    
    private func wordToNumber(word:String) -> Int{
        switch word
        {
        case "one": return 1
        case "an": return 1
        case "two": return 2
        case "three": return 3
        case "four": return 4
        case "five": return 5
        case "six": return 6
        case "seven": return 7
        case "eight": return 8
        case "nine": return 9
        case "ten": return 10
        case "eleven": return 11
        case "twelve": return 12
        case "thirteen": return 13
        case "fourteen": return 14
        case "fifteen": return 15
        case "sixteen": return 16
        case "seventeen": return 17
        case "eighteen": return 18
        case "nineteen": return 19
        case "twenty": return 20
        case "thirty": return 30
        case "fourty": return 40
        case "fifty": return 50
        case "sixty": return 60
        default: return 0
        }
    }
    
    func convertToPmAmFormat(str:String) -> String{
        let arrayTimes = [str]
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        for (_,time) in arrayTimes.enumerated() {
            dateFormatter.dateFormat = "HH:mm:ss"
            if let inDate = dateFormatter.date(from: time) {
                dateFormatter.dateFormat = "h:mm a"
                let outTime = dateFormatter.string(from:inDate)
                return outTime
            }
        }
        return ""
    }
    
    //---------to be thrown away layer-----------

    @IBOutlet weak var demoButton: UIButton!
    @IBAction func demoBtnAction(_ sender: Any) {
        conversationFinished = false
        currentReminder = remindersDictionary.first?.value
        pillImage.image = UIImage(named: "Pill_Phone.png")
        utterSentence(line: "Have you taken this medicine?")
    }
    
}

