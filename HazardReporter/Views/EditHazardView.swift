//
//  EditHazardView.swift
//  HazardReporter
//
//  Created by Doug Robison on 4/9/20.
//  Copyright © 2020 Doug Robison. All rights reserved.
//

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
                    manager.startUpdatingLocation()
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

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }

    func alertLocationAccessNeeded() {
        showLocationAlert = true
    }

    deinit {
        manager.stopUpdatingLocation()
    }
}

class EditHazardViewModel: ObservableObject, Identifiable {
    private let location = LocationManager()
    private var disposables = Set<AnyCancellable>()
    @Published var showLocationAlert = true

    init() {
        setUp()
    }

    func setUp() {
        location.$showLocationAlert.sink(receiveValue: {self.showLocationAlert = $0}).store(in: &disposables)
    }

    func start() {
        location.startUpdating()
    }

    deinit {}
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
                Button(action: {}, label: {Text("Snap picture")})
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
        .onAppear {
            self.viewModel.start()
        }
        .alert(isPresented: $viewModel.showLocationAlert) {
            Alert(title: Text("Are you sure you want to delete this?"), message: Text("There is no undo"), primaryButton: .default(Text("Allow Location Access"), action: {
                self.viewModel.showLocationAlert = false
                let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
                UIApplication.shared.open(settingsAppURL,
                                          options: [:],
                                          completionHandler: nil)
            }),
                  secondaryButton: .cancel())
        }
    }
}
