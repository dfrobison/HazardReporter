//
//  ContentView.swift
//  HazardReporter
//
//  Created by Doug Robison on 4/8/20.
//  Copyright © 2020 Doug Robison. All rights reserved.
//

import SwiftUI

struct HazardItem: View {
      var body: some View {
        HStack {
            Image
            VStack {
                Text
                Text
            }
            
        }
    }
}

struct ActiveHazardsView: View {
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Text("HI")
                }
            }
            .navigationBarTitle("Active Hazards", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {})
                {
                    Image(systemName: "plus")
                }
            )
        }
    }
}

struct ResolvedHazardsView: View {
    var body: some View {
        NavigationView {
            Text( "Resolved")
        }.navigationBarTitle("Welcome")
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
