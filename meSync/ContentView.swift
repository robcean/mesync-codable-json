//
//  ContentView.swift
//  meSync
//
//  Created by Brandon Cean on 6/13/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var quickAddState: QuickAddState = .hidden
    
    var body: some View {
        HomeView(quickAddState: $quickAddState)
            .environmentObject(dataManager)
    }
}

// MARK: - Quick Add Button Component
struct QuickAddButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: AppDimensions.xlIcon))
                    .foregroundStyle(AppColors.primary)
                
                Text(title)
                    .captionStyle()
            }
        }
        .quickAddButtonStyle()
        .pressableStyle()
    }
}

// MARK: - Tab Bar Button Component
struct TabBarButton: View {
    let title: String
    let systemImage: String
    
    var body: some View {
        Button {
            // Acción del botón
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: systemImage)
                    .font(.system(size: AppDimensions.mediumIcon))
                
                Text(title)
                    .font(AppTypography.caption2)
            }
        }
        .tabBarButtonStyle()
        .pressableStyle()
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
}
