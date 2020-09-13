//
//  PhotoManager.swift
//  GPSTestApplication
//
//  Created by Igor Shukyurov on 13.09.2020.
//  Copyright © 2020 Igor Shukyurov. All rights reserved.
//

import UIKit
import AVFoundation

#warning("А не сделать ли тебя синглтоном?")
final class PhotoManager: NSObject, AVCapturePhotoCaptureDelegate {
    private let cameraView: UIView
    var previewLayer: AVCaptureVideoPreviewLayer!
    let photoOutput = AVCapturePhotoOutput()
    
    init(withCameraView cameraView: UIView) {
        self.cameraView = cameraView
        
        super.init()

        // Запрашиваем права на съёмку
        AVCaptureDevice.requestAccess(for: .video) { success in
            if success {
                DispatchQueue.main.async {
                    let captureSession = AVCaptureSession()
                    captureSession.sessionPreset = .hd4K3840x2160
                    if let captureDevice = AVCaptureDevice.default(for: .video) {
                        do {
                            let input = try AVCaptureDeviceInput(device: captureDevice)
                            if captureSession.canAddInput(input) {
                                captureSession.addInput(input)
                            }
                        } catch let error {
                            print("-=- PhotoManager -=- Unable to set input device with error: \(error)")
                        }
                        
                        if captureSession.canAddOutput(self.photoOutput) {
                            captureSession.addOutput(self.photoOutput)
                            self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                            self.previewLayer.videoGravity = .resizeAspectFill
                            self.previewLayer.connection?.videoOrientation = .portrait
                            cameraView.layer.addSublayer(self.previewLayer)
                            DispatchQueue.main.async {
                                self.previewLayer.frame = self.cameraView.bounds
                            }
                        }
                        captureSession.startRunning()
                    }
                    
                    print("-=- PhotoManager -=- The user has granted to accsess the camera")
                }
            } else {
                print("-=- PhotoManager -=- The user has not granted to accsess the camera")
            }
            print("-=- PhotoManager -=- Init")
        }
    }
    
    func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        
        if let photoOutputConnection = photoOutput.connection(with: AVMediaType.video) {
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                photoOutputConnection.videoOrientation = .landscapeRight
            case .landscapeRight:
                photoOutputConnection.videoOrientation = .landscapeLeft
            case .portrait:
                photoOutputConnection.videoOrientation = .portrait
            default: break

            }
        }
        
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
        print("-=- PhotoManager -=- capturePhoto")
    }
    
    func createLocationMetadata() -> NSMutableDictionary? {
        if let location = LocationManager.shared.previousLocation {
            let gpsDictionary = NSMutableDictionary()
            var latitude = location.coordinate.latitude
            var longitude = location.coordinate.longitude
            var altitude = location.altitude
            var latitudeRef = "N"
            var longitudeRef = "E"
            var altitudeRef = 0
            
            if latitude < 0.0 {
                latitude = -latitude
                latitudeRef = "S"
            }
            
            if longitude < 0.0 {
                longitude = -longitude
                longitudeRef = "W"
            }
            
            if altitude < 0.0 {
                altitude = -altitude
                altitudeRef = 1
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd"
            gpsDictionary[kCGImagePropertyGPSDateStamp] = formatter.string(from:location.timestamp)
            formatter.dateFormat = "HH:mm:ss"
            gpsDictionary[kCGImagePropertyGPSTimeStamp] = formatter.string(from:location.timestamp)
            gpsDictionary[kCGImagePropertyGPSLatitudeRef] = latitudeRef
            gpsDictionary[kCGImagePropertyGPSLatitude] = latitude
            gpsDictionary[kCGImagePropertyGPSLongitudeRef] = longitudeRef
            gpsDictionary[kCGImagePropertyGPSLongitude] = longitude
            gpsDictionary[kCGImagePropertyGPSDOP] = location.horizontalAccuracy
            gpsDictionary[kCGImagePropertyGPSAltitudeRef] = altitudeRef
            gpsDictionary[kCGImagePropertyGPSAltitude] = altitude
            
            if let heading = LocationManager.shared.heading {
                gpsDictionary[kCGImagePropertyGPSImgDirectionRef] = "T"
                gpsDictionary[kCGImagePropertyGPSImgDirection] = heading.trueHeading
            }
            
            return gpsDictionary
        }
        return nil
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        var properties = photo.metadata
        guard let gpsDictionary = createLocationMetadata() else {
            print("gpsDict")
            return
        }
        properties[kCGImagePropertyGPSDictionary as String] = gpsDictionary
        
        guard let imageData = photo.fileDataRepresentation(withReplacementMetadata:properties,
            replacementEmbeddedThumbnailPhotoFormat:photo.embeddedThumbnailPhotoFormat,
            replacementEmbeddedThumbnailPixelBuffer:photo.previewPixelBuffer,
            replacementDepthData:photo.depthData) else {
            return
        }
        let latitude = Float(gpsDictionary[kCGImagePropertyGPSLatitude] as! Double)
        let longitude = Float(gpsDictionary[kCGImagePropertyGPSLongitude] as! Double)
        
        DataBaseHelper.shared.saveImage(data: imageData, latitude: latitude, longitude: longitude)
//        DataBaseHelper.shared.saveImage(data: photo.fileDataRepresentation()!, latitude: latitude, longitude: longitude)
        
        
        
        
        
        
//        print("-=- photoCaptured")
//        guard let imageData = photo.fileDataRepresentation() else { return }
//        guard let image = UIImage(data: imageData) else { return }
//        PHPhotoLibrary.requestAuthorization { (status) in
//            if status == .authorized {
//                do {
//                    try PHPhotoLibrary.shared().performChangesAndWait {
//                        PHAssetChangeRequest.creationRequestForAsset(from: image)
//                    }
//                } catch let error {
//                    print("Unable to add a photo to the library with error: \(error)")
//                }
//            } else {
//                print("Permission denied")
//            }
//        }
    }
}
