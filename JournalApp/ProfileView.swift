//
//  ProfileView.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 05.12.2023.
//

import SwiftUI
import RealmSwift

struct ProfileView: View {
    @ObservedResults(Profile.self) var profiles
    
    var body: some View {
        if let profile = profiles.first?.profile {
            ScrollView {
                Text(profile)
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.green.opacity(0.1), Color.blue.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
                    .cornerRadius(25)
                
            }
            .padding([.leading, .trailing])
        }
        
    }
}

#Preview {
    ProfileView()
        .environment(\.realm, DatabaseInteractor.RealmMockup)
}
