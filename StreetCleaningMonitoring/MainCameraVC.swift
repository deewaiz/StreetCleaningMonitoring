//
//  MainCameraVC.swift
//  GPSTestApplication
//
//  Created by Igor Shukyurov on 23.08.2020.
//  Copyright © 2020 Igor Shukyurov. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion
import Photos

class MainCameraVC: UIViewController {
    // Выводы
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var updateDistanceLabel: UILabel!
    @IBOutlet weak var distanceFilterStepper: UIStepper!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var numberOfTakenPicturesLabel: UILabel!
    @IBOutlet weak var totalTravelledDistanceLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    
    private var photoManager: PhotoManager!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Инициализируем PhotoManager
        photoManager = PhotoManager(withCameraView: cameraView)
        
        // Настраиваем LocationManager
        let distanceFilter = LocationManager.shared.distanceFilter
        distanceFilterStepper.value = distanceFilter
        updateDistanceLabel.text = String(Int(distanceFilter))
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedLocationHandler), name: .didReceivedLocation, object: nil)
        
        // Запускаем UploadManager
        UploadManager.shared.start()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            photoManager.previewLayer.connection?.videoOrientation = .landscapeRight
        case .landscapeRight:
            photoManager.previewLayer.connection?.videoOrientation = .landscapeLeft
        case .portrait:
            photoManager.previewLayer.connection?.videoOrientation = .portrait
        default: break
        }
        DispatchQueue.main.async {
            self.photoManager.previewLayer.frame = self.cameraView.bounds
        }
    }
    
    // MARK: - DidReceivedLocationHandler
    @objc func didReceivedLocationHandler() {
        numberOfTakenPicturesLabel.text = String(LocationManager.shared.didUpdateLocationsCount)
        speedLabel.text = "\(LocationManager.shared.speedKMH) КМ/Ч"
        totalTravelledDistanceLabel.text = String(Int(LocationManager.shared.totalTravelledDistance))
            
        photoManager.capturePhoto()
    }
    
    // MARK: - Actions
    @IBAction func stepperAction(_ sender: UIStepper) {
        LocationManager.shared.distanceFilter = sender.value
        updateDistanceLabel.text = String(Int(sender.value))
    }
    
    @IBAction func startStopAction(_ sender: Any) {
        if !LocationManager.shared.isRunning {
            LocationManager.shared.start()
            totalTravelledDistanceLabel.text = "0"
            startStopButton.setTitle("Закончить фотофиксацию", for: .normal)
            startStopButton.setTitleColor(.systemRed, for: .normal)
        } else {
            LocationManager.shared.stop()
            startStopButton.setTitle("Начать фотофиксацию", for: .normal)
            startStopButton.setTitleColor(.systemBlue, for: .normal)
        }
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        DataBaseHelper.shared.deleteAllImages()
    }
    
}

