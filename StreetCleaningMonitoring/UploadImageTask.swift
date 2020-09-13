//
//  UploadImageTask.swift
//  GPSTestApplication
//
//  Created by Igor Shukyurov on 08.09.2020.
//  Copyright © 2020 Igor Shukyurov. All rights reserved.
//

import UIKit

protocol UploadImageTaskProtocol {
    func startUploadingImage()
    func successUploadingImage()
    func failUploadingImage(error: String)
}

final class UploadImageTask: NSObject, URLSessionDelegate {
    private let url: String = "http://46.101.238.176/api/upload"
    var delegate: UploadImageTaskProtocol!
    
    func upload(_ imageData: Data, latitude: Float, longitude: Float) {
        DispatchQueue.main.async {
            self.delegate.startUploadingImage()
        }
        var request = URLRequest(url: URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!)
        request.httpMethod = "POST"
        
        // Установка хэдэров
        request.addValue("iosApp", forHTTPHeaderField: "User-Agent")
        request.addValue(NSUUID().uuidString, forHTTPHeaderField: "X-Device-Guid")
        
        // Создание multipart/form-data
        let boundary = "Boundary-\(NSUUID().uuidString)"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = NSMutableData()
        
        
        // Установка дополнительных параметров в боди
        let parameters = [
            "latitude": latitude,
            "longitude": longitude
        ]
        for (key, value) in parameters {
            body.append(("--\(boundary)\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
            body.append(("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
        }

        // Установка картинки в боди
        body.append(("--\(boundary)\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
        body.append(("Content-Disposition: form-data; name=\"image\"; filename=\"someFile.jpg\"\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
        body.append(("Content-Type: image/jpg\r\n\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
        body.append(imageData)
        print("\(imageData.count / 1024) KBytes")
        body.append(("\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
        body.append(("--\(boundary)--\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
        
        request.httpBody = body as Data
        
        // Запрос в сеть
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil {
                DispatchQueue.main.async {
                    self.delegate.failUploadingImage(error: error!.localizedDescription)
                }
                return
            }
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.delegate.successUploadingImage()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.delegate.failUploadingImage(error: "Ошибка \(response.statusCode)")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.delegate.failUploadingImage(error: "invalid response")
                }
            }
        }
        task.resume()
    }
}
