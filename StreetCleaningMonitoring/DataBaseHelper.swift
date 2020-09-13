//
//  DataBaseHelper.swift
//  GPSTestApplication
//
//  Created by Igor Shukyurov on 08.09.2020.
//  Copyright © 2020 Igor Shukyurov. All rights reserved.
//

import UIKit
import CoreData

enum UploadStatus: Int16 {
    case NotUploaded = 0
    case IsStarted = 1
    case IsSuccessed = 2
    case IsFailed = 3
}

final class DataBaseHelper {
    static let shared = DataBaseHelper()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private func saveContext() {
        do {
            try context.save()
            print("Context saved")
        } catch  {
            print(error.localizedDescription)
        }
    }
    
    func saveImage(data: Data, latitude: Float, longitude: Float) {
        let imageEntity = ImageEntity(context: context)
        imageEntity.image = data
        imageEntity.latitude = latitude
        imageEntity.longitude = longitude
        imageEntity.uploadStatus = UploadStatus.NotUploaded.rawValue
        saveContext()
    }
    
    func fetchImages() -> [ImageEntity] {
        var fetchingImage = [ImageEntity]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ImageEntity")
        do {
            fetchingImage = try context.fetch(fetchRequest) as! [ImageEntity]
        } catch {
            print("Error while fetching the image")
        }
        return fetchingImage
    }
    
    func deleteImage(imageEntity: ImageEntity) {
        context.delete(imageEntity)
        saveContext()
    }
    // Функция-помощник. Только для отладки!
    func deleteAllImages() {
        let context = ( UIApplication.shared.delegate as! AppDelegate ).persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ImageEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
}

