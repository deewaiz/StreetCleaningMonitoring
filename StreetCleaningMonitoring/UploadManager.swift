//
//  UploadManager.swift
//  GPSTestApplication
//
//  Created by Igor Shukyurov on 10.09.2020.
//  Copyright © 2020 Igor Shukyurov. All rights reserved.
//
import Foundation
import UIKit

final class UploadManager: UploadImageTaskProtocol {
    static let shared = UploadManager()
    
    // Модель
    private let uploadImageTask = UploadImageTask()
    private var currentImageEntity: ImageEntity!
    
    private var timer: Timer!
    private let interval = 10.0
    
    func start() {
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(uploadImage), userInfo: nil, repeats: true)
        print("-=- UploadManager -=- Start")
    }
    
    @objc private func uploadImage() {
        // Удаляем отправленные фоточки
        let uploadedImages = DataBaseHelper.shared.fetchImages().filter { imageEntity -> Bool in
            switch UploadStatus(rawValue: imageEntity.uploadStatus) {
            case .IsSuccessed: return true
            default: return false
            }
        }
        print("-=- UploadManager -=- uploadedImages.Count = \(uploadedImages.count)")
        for imageEntity in uploadedImages {
            DataBaseHelper.shared.deleteImage(imageEntity: imageEntity)
        }
        print("-=- UploadManager -=- allImages.Count = \(DataBaseHelper.shared.fetchImages().count)")
        guard let firstImageEntity = DataBaseHelper.shared.fetchImages().first else {
            if !timer.isValid {
                start()
            }
            return
        }
        timer.invalidate()

        currentImageEntity = firstImageEntity
        uploadImageTask.delegate = self
        uploadImageTask.upload(currentImageEntity.image!, latitude: currentImageEntity.latitude, longitude: currentImageEntity.longitude)
    }
    
    // MARK: - UploadImageTaskProtocol
    func startUploadingImage() {
        print("-=- UploadManager -=- startUploadingImage")
        currentImageEntity.uploadStatus = UploadStatus.IsStarted.rawValue
    }
    
    func successUploadingImage() {
        print("-=- UploadManager -=- successUploadingImage")
        currentImageEntity.uploadStatus = UploadStatus.IsSuccessed.rawValue
        uploadImage()
    }
    
    func failUploadingImage(error: String) {
        print("-=- UploadManager -=- failUploadingImage with error: - \(error)")
        currentImageEntity.uploadStatus = UploadStatus.IsFailed.rawValue
        start()
    }
}
