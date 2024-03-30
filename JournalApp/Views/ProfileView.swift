//
//  ProfileView.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 05.12.2023.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query var profiles: [ProfileSwiftData]
        
    var body: some View {
        if let profile = profiles.first?.profile {
            NavigationStack {
                ScrollView {
                    Text(profile)
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.green.opacity(0.1), Color.blue.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
                        .cornerRadius(25)
                }
                .padding([.leading, .trailing])
                .navigationTitle("Profile")
            }
        } else {
            NavigationStack {
                ScrollView {
                    Text("Hi, my name is Lumi and I will be your Journal friend. Just add an entry to your Journal to help me learn about you.")
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.green.opacity(0.1), Color.blue.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
                        .cornerRadius(25)
                }
                .padding([.leading, .trailing])
                .navigationTitle("Profile")
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(DatabaseInteractorMock.mockContainer())
}
