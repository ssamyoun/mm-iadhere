//
//  HelperMethods.swift
//  Medication Reminder WatchKit Extension
//
//  Created by Abu Sayeed Mondol on 9/26/18.
//  Copyright © 2018 Sirat Samyoun. All rights reserved.
//

import Foundation

class HelperMethods {
    
    static func stringWithUUID() -> String {
        let uuidObj = CFUUIDCreate(nil)
        let uuidString = CFUUIDCreateString(nil, uuidObj)!
        return uuidString as String
    }
    
    static func wordToNumber(word:String) -> Int{
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
        default: return 5
        }
    }
    
  static func CurrentTimeToMinutes() -> Int {
        let date = Date()
        let hour = Calendar.current.component(.hour, from: date)
        let mins = Calendar.current.component(.minute, from: date)
        let totalmins = hour * 60 + mins
        return totalmins
    }

   static func ConvertToMinutes(str:String) -> Int{
        let arrayTimes = [str]
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        for (_,time) in arrayTimes.enumerated() {
            dateFormatter.dateFormat = "HH:mm:ss"
            if let inDate = dateFormatter.date(from: time) {
                let hour = Calendar.current.component(.hour, from: inDate)
                let mins = Calendar.current.component(.minute, from: inDate)
                let totalmins = hour * 60 + mins
                return totalmins
            }
        }
        return 0
    }
    
    static func convertToPmAmFormat(str:String) -> String{
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
    
    static func currentTimeAmPmAsString() -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "h:mm:ss a"
        let outputString = dateFormatter.string(from: Date())
        return outputString
    }
    
    static func currentDateAmPmAsString() -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy/MM/dd h:mm a"
        let outputString = dateFormatter.string(from: Date())
        return outputString
    }
    
    static func convertDictionaryToString(dic: Dictionary<String, String>) -> String{
        if(dic.count == 0){
            return ""
        }
        let sortedDict = dic.sorted { $0.0 < $1.0 }
        let theJSONData = try? JSONSerialization.data(withJSONObject: sortedDict, options:[])
        let theJSONText = String(data: theJSONData!,encoding: .ascii)
        if(theJSONText == nil){
            return ""
        }
        return theJSONText!
    }
    
    static func currentTime24AsString() -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = ""
        let outputString = dateFormatter.string(from: Date())
        return outputString
    }
    
    static func currentDateNoAmPmAsString() -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let outputString = dateFormatter.string(from: Date())
        return outputString
    }
    
    static func sendToServer(uploadData:NSData){
        let strId = "randStr" + String(Int.random(in: 0..<100))
        print(strId)
        let configuration = URLSessionConfiguration.background(withIdentifier: strId)
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 300
        configuration.waitsForConnectivity = true
        let session = URLSession(configuration: configuration)
        //let session = URLSession.shared
        let url = URL(string: "http://ec2-18-188-221-234.us-east-2.compute.amazonaws.com:3000/")!
        //let url = URL(string: "http://172.26.134.250:3000")!
        //let url = URL(string: "http://ptsv2.com/t/1te8r-1532622698/post")!
        dataTaskFromURL(url: url, uploadData: uploadData, session: session)
    }
    //changed nsdata to calling function,was data, set content-lenght- can revert,Approach1 can revert
    //&also changed to backfround instead default--Approach 2,can revert
    static func dataTaskFromURL(url: URL, uploadData:NSData, session: URLSession){
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(uploadData.length)", forHTTPHeaderField: "Content-Length")
        request.httpBody = uploadData as Data
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil {
                print("error=\(error)")
                return
            }
            print((response as? HTTPURLResponse)?.statusCode)
        }
        task.resume()
    }
    
    static func sendToServer2(uploadData:Data){
        ///////////
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 120
        configuration.waitsForConnectivity = true
        let session = URLSession(configuration: configuration)
        //let session = URLSession.shared
        let url = URL(string: "http://ec2-18-188-221-234.us-east-2.compute.amazonaws.com:3000/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //morenew
//        var login_details: [String: String] = [
//            "email" : "ss8hf",
//            "password" : "rdhrh"
//        ]
//        do {
//        request.httpBody = try JSONSerialization.data(withJSONObject: login_details, options: .prettyPrinted)
//        } catch {
//            print(error.localizedDescription)
//        }
        //new
        request.httpBody = uploadData
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil {
                print("error=\(error)")
                return
            }
            print((response as? HTTPURLResponse)?.statusCode)
        }
        //new ends
//        let task = session.uploadTask(with: request, from: uploadData) { data, response, error in
//            if let error = error {
//                print ("error: \(error)")
//                return
//            }
//            print((response as? HTTPURLResponse)?.statusCode)
//
//            guard let response = response as? HTTPURLResponse,
//                (200...299).contains(response.statusCode) else {
//                    print ("server error")
//                    return
//            }
//            if let mimeType = response.mimeType,
//                mimeType == "application/json",
//                let data = data,
//                let dataString = String(data: data, encoding: .utf8) {
//                print ("got data: \(dataString)")
//            }
//        }
        task.resume()
    }
}
