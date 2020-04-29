//
//  EditHazardView.swift
//  HazardReporter
//
//  Created by Doug Robison on 4/9/20.
//  Copyright © 2020 Doug Robison. All rights reserved.
//

import CloudKit
import Combine
import Foundation
import SwiftUI

class EditHazardViewModel: ObservableObject, Identifiable {
    private let location = LocationManager()
    private let camera = CameraAuthorizationManager()
    private var disposables = Set<AnyCancellable>()
    @Published var showLocationAlert = false
    @Published var showCameraAlert = false
    @Published var cameraAuthorized = false
    @Published var locationAuthorized = false

    init() {
        setUp()
    }

    private func setUp() {
        location.locationAuthorizationNeeded.receive(on: DispatchQueue.main).sink(receiveValue: {
            print("Location = \($0)")
            self.showLocationAlert = $0

        }).store(in: &disposables)

        location.isLocationAuthorized.receive(on: DispatchQueue.main).sink(receiveValue: {
            print("Location = \($0)")
            self.locationAuthorized = $0

        }).store(in: &disposables)

        camera.needCameraAuthorization.receive(on: DispatchQueue.main).sink(receiveValue: {self.showCameraAlert = $0}).store(in: &disposables)
        camera.cameraAuthorized.receive(on: DispatchQueue.main).sink(receiveValue: {self.cameraAuthorized = $0}).store(in: &disposables)
        startUpdating()
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
        camera.authorizeCamera()
    }

    func startUpdating() {
        location.startUpdating()
    }

    func currentLocation() -> CLLocation? {
        location.currentLocation
    }
}

struct EditHazardView: View {
    @ObservedObject var viewModel: EditHazardViewModel = EditHazardViewModel()
    @Binding var isPresented: Bool
    @State private var emergencyStatus = 0
    @State private var hazardDescription: String = ""
    @State var image: Image? = nil
    @State var uiImage: UIImage? = nil

    var body: some View {
        NavigationView {
            ZStack {
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

                    image?.resizable()
                        .frame(width: 250, height: 250)

                    Spacer()
                }

                if viewModel.cameraAuthorized {
                    CaptureImageView(isShown: $viewModel.cameraAuthorized, image: $image, uiImage: $uiImage)
                }
            }
            .navigationBarTitle(Text("Edit Hazard Report"), displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                self.isPresented = false
                           }) {
                Text("Cancel").bold()
            },
                                
            trailing: Button(action: {
                self.isPresented = false
                let hazardReport = CKRecord(recordType: "HazardReport")
                hazardReport["isEmergency"] = self.emergencyStatus
                hazardReport["hazardDescription"] = self.hazardDescription
                hazardReport["hazardLocation"] = self.viewModel.currentLocation()
                hazardReport["isResolved"] = NSNumber(integerLiteral: 0)

                if let hazardPhoto = self.image {
                    // Generate unique file name
                    let hazardPhotoFileName = ProcessInfo.processInfo.globallyUniqueString + ".jpg"

                    // Create URL in temp directory
                    let hazardPhotoFileURL = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent(hazardPhotoFileName)

                    // Make JPEG
                    let hazardPhotoData = self.uiImage!.jpegData(compressionQuality: 0.70)

                    // Write to disk
                    do {
                        try hazardPhotoData?.write(to: hazardPhotoFileURL)
                    } catch {
                        print("Could not save hazard photo to disk")
                    }

                    // Convert to CKAsset and store with CKRecord
                    hazardReport["hazardPhoto"] = CKAsset(fileURL: hazardPhotoFileURL)
                }

                let container = CKContainer.default()
                let database = container.publicCloudDatabase

                database.save(hazardReport) { _, _ in
                    // Stay tuned!
                }

                           }) {
                Text("Save").bold()
                           })
        }
        .alert(isPresented: $viewModel.showCameraAlert) {
            viewModel.getCameraAlert()
        }
    }
}
