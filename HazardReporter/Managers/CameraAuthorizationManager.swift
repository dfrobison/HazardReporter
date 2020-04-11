//
//  CameraAuthorizationManager.swift
//  HazardReporter
//
//  Created by Doug Robison on 4/10/20.
//  Copyright © 2020 Doug Robison. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

class CameraAuthorizationManager {
    let needCameraAuthorization = CurrentValueSubject<Bool, Never>(false)
    let cameraAuthorized = CurrentValueSubject<Bool, Never>(false)

    func authorizeCamera() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch cameraAuthorizationStatus {
            case .notDetermined: requestCameraPermission()
            case .authorized: cameraAuthorizationGranted()
            case .restricted, .denied: cameraAuthorizationNeeded()
        @unknown default:
                fatalError()
        }
    }

    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video,
                                      completionHandler: {accessGranted in
                                          guard accessGranted == true else { return }
                                          self.cameraAuthorizationGranted()
        })
    }

    func cameraAuthorizationGranted() {
        needCameraAuthorization.send(false)
        cameraAuthorized.send(true)
    }

    func cameraAuthorizationNeeded() {
        needCameraAuthorization.send(true)
    }
}
