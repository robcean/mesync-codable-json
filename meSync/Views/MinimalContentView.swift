//
//  MinimalContentView.swift
//  meSync
//
//  Minimal view for testing compilation
//

import SwiftUI

struct MinimalContentView: View {
    var body: some View {
        VStack {
            Text("meSync - Testing")
                .font(AppTypography.largeTitle)
                .padding()
            
            Text("App is running!")
                .foregroundStyle(AppColors.secondaryText)
        }
    }
}

#Preview {
    MinimalContentView()
}