//
//  EditHazardView.swift
//  HazardReporter
//
//  Created by Doug Robison on 4/9/20.
//  Copyright © 2020 Doug Robison. All rights reserved.
//

import AVFoundation
import Combine
import CoreLocation
import Foundation
import SwiftUI

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager: CLLocationManager
    var lastKnownLocation: CLLocation?
    @Published var showLocationAlert = false

    init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()
    }

    func startUpdating() {
        let locationAuthorizationStatus = CLLocationManager.authorizationStatus()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest

        switch locationAuthorizationStatus {
            case .notDetermined: manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                if CLLocationManager.locationServicesEnabled() {
                    locationServicesEnabled()
                }
            case .restricted, .denied: alertLocationAccessNeeded()
        @unknown default:
                fatalError()
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(locations)
        lastKnownLocation = locations.last
    }

    private func locationServicesEnabled() {
        manager.startUpdatingLocation()
        showLocationAlert = false
    }

    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationServicesEnabled()
        }
    }

    private func alertLocationAccessNeeded() {
        showLocationAlert = true
    }

    deinit {
        manager.stopUpdatingLocation()
    }
}

class CameraManager {
    @Published var showCameraAlert = false

    func takePicture() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch cameraAuthorizationStatus {
            case .notDetermined: requestCameraPermission()
            case .authorized: presentCamera()
            case .restricted, .denied: alertCameraAccessNeeded()
        @unknown default:
                fatalError()
        }
    }

    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video,
                                      completionHandler: {accessGranted in
                                          guard accessGranted == true else { return }
                                          self.presentCamera()
        })
    }

    func presentCamera() {
        showCameraAlert = false

        let hazardPhotoPicker = UIImagePickerController()
       // hazardPhotoPicker.sourceType = .camera
        // hazardPhotoPicker.delegate = self

        // present(hazardPhotoPicker, animated: true, completion: nil)
    }

    func alertCameraAccessNeeded() {
        showCameraAlert = true
    }
}

class EditHazardViewModel: ObservableObject, Identifiable {
    private let location = LocationManager()
    private let camera = CameraManager()
    private var disposables = Set<AnyCancellable>()
    @Published var showLocationAlert = false
    @Published var showCameraAlert = false

    init() {
        setUp()
    }

    private func setUp() {
        location.$showLocationAlert.sink(receiveValue: {self.showLocationAlert = $0}).store(in: &disposables)
        location.startUpdating()

        camera.$showCameraAlert.sink(receiveValue: {self.showCameraAlert = $0}).store(in: &disposables)
    }

    func getLocationAlert() -> Alert {
        Alert(title: Text("Need Location Access"),
              message: Text("Location access is required for including the location of the hazard."),
              primaryButton: .cancel(),
              secondaryButton: .default(Text("Allow Location Access"), action: {
                  let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
                  UIApplication.shared.open(settingsAppURL,
                                            options: [:],
                                            completionHandler: nil)
        }))
    }

    func getCameraAlert() -> Alert {
        Alert(title: Text("Need Camera Access"),
              message: Text("Camera access is required for including pictures of hazards."),
              primaryButton: .cancel(),
              secondaryButton: .default(Text("Allow Camera"), action: {
                  let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
                  UIApplication.shared.open(settingsAppURL,
                                            options: [:],
                                            completionHandler: nil)
        }))
    }

    func takeSnapShot() {
        camera.takePicture()
    }
}

struct EditHazardView: View {
    @ObservedObject var viewModel: EditHazardViewModel = EditHazardViewModel()
    @Binding var isPresented: Bool
    @State private var emergencyStatus = 0
    @State private var hazardDescription: String = ""

    var body: some View {
        return NavigationView {
            VStack {
                Picker(selection: $emergencyStatus, label: Text("")) {
                    Text("Non-Emergency").tag(0)
                    Text("Emergency!").tag(1)
                }.pickerStyle(SegmentedPickerStyle())
                    .padding()

                VStack(alignment: .leading) {
                    Text("Briefly describe the problem you see")
                    TextField("Describe problem", text: $hazardDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                Button(action: {
                    self.viewModel.takeSnapShot()
                }, label: {Text("Snap picture")})
                Spacer()
            }
            .navigationBarTitle(Text("Edit Hazard Report"), displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                print("Dismissing sheet view...")
                self.isPresented = false
                           }) {
                Text("Cancel").bold()
            },
                                
            trailing: Button(action: {
                print("Dismissing sheet view...")
                self.isPresented = false
                           }) {
                Text("Save").bold()
                           })
        }
        .alert(isPresented: $viewModel.showLocationAlert) {
            viewModel.getLocationAlert()
        }
        .alert(isPresented: $viewModel.showCameraAlert) {
            viewModel.getCameraAlert()
        }
    }
}
