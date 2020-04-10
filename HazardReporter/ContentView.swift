//
//  ContentView.swift
//  HazardReporter
//
//  Created by Doug Robison on 4/8/20.
//  Copyright © 2020 Doug Robison. All rights reserved.
//

import SwiftUI

struct HazardItem: View {
    let iconName: String
    let incidentDate: String
    let incidentDescription: String

    var body: some View {
        HStack {
            Image(iconName).resizable().aspectRatio(contentMode: .fit).frame(width: 50, height: 50, alignment: .center)
            VStack(alignment: .leading) {
                Text(incidentDate).bold()
                Text(incidentDescription).font(.footnote)
            }
        }
    }
}



struct ActiveHazardsView: View {
    @State private var showModal: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    HazardItem(iconName: "hazard-icon", incidentDate: "January 1, 2019", incidentDescription: "At the entrance to building 4, there's a puddle of water")
                }
            }
            .navigationBarTitle("Active Hazards", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                self.showModal.toggle()
                }, label:
                {
                    Image(systemName: "plus")
                })
                .sheet(isPresented: self.$showModal) {
                    EditHazardView(isPresented: self.$showModal)
                }
            )
        }
    }
}

struct ResolvedHazardsView: View {
    var body: some View {
        NavigationView {
            List {
                HazardItem(iconName: "resolved-hazard-icon", incidentDate: "January 1, 2019", incidentDescription: "Ice on the sidewalk")
            }
            .navigationBarTitle("Resolved Hazards", displayMode: .inline)
        }
    }
}

struct ContentView: View {
    @State var selectedView = 0

    var body: some View {
        TabView(selection: $selectedView) {
            ActiveHazardsView()
                .tabItem {
                    Image("active-hazard-bar-button-icon")
                    Text("Active Hazards")
                }.tag(0)
            ResolvedHazardsView()
                .tabItem {
                    Image("resolve-hazard-icon")
                    Text("Resolved Hazards")
                }.tag(1)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
