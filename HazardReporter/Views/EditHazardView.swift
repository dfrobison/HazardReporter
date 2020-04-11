//
//  EditHazardView.swift
//  HazardReporter
//
//  Created by Doug Robison on 4/9/20.
//  Copyright © 2020 Doug Robison. All rights reserved.
//

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
}

struct EditHazardView: View {
    @ObservedObject var viewModel: EditHazardViewModel = EditHazardViewModel()
    @Binding var isPresented: Bool
    @State private var emergencyStatus = 0
    @State private var hazardDescription: String = ""
    @State var image: Image? = nil

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
                        //self.viewModel.takeSnapShot()
                        self.viewModel.startUpdating()

                }, label: {Text("Snap picture")})

                    Spacer()

                    image?.resizable()
                        .frame(width: 250, height: 250)

                    Spacer()
                }

                if viewModel.cameraAuthorized {
                    CaptureImageView(isShown: $viewModel.cameraAuthorized, image: $image)
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
                           }) {
                Text("Save").bold()
                           })
        }
        .alert(isPresented: $viewModel.showCameraAlert) {
            viewModel.getCameraAlert()
        }
    }
}
