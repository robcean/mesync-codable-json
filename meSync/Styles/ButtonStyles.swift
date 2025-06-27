//
//  ButtonStyles.swift
//  meSync
//
//  ViewModifiers para estilos de botones personalizados
//

import SwiftUI

// MARK: - Quick Add Button Style
struct QuickAddButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            .foregroundStyle(AppColors.primary)
    }
}

// MARK: - Tab Bar Button Style
struct TabBarButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(AppColors.secondaryText)
            .font(.system(size: AppDimensions.mediumIcon))
    }
}

// MARK: - Primary Action Button Style
struct PrimaryActionButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTypography.bodyMedium)
            .foregroundStyle(AppColors.onPrimaryText)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.primary, in: RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius))
    }
}

// MARK: - Secondary Action Button Style
struct SecondaryActionButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTypography.body)
            .foregroundStyle(AppColors.primary)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                    .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Floating Action Button Style
struct FloatingActionButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: AppDimensions.largeIcon, weight: .medium))
            .foregroundStyle(AppColors.onPrimaryText)
            .frame(width: AppDimensions.floatingButtonSize, height: AppDimensions.floatingButtonSize)
            .background(AppColors.primary, in: Circle())
    }
}

// MARK: - Destructive Button Style
struct DestructiveButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTypography.bodyMedium)
            .foregroundStyle(AppColors.onPrimaryText)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.error, in: RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius))
    }
}

// MARK: - View Extensions for Button Styles
extension View {
    
    /// Aplica el estilo de botón Quick Add
    func quickAddButtonStyle() -> some View {
        self.modifier(QuickAddButtonStyle())
    }
    
    /// Aplica el estilo de botón Tab Bar
    func tabBarButtonStyle() -> some View {
        self.modifier(TabBarButtonStyle())
    }
    
    /// Aplica el estilo de botón de acción principal
    func primaryActionButtonStyle() -> some View {
        self.modifier(PrimaryActionButtonStyle())
    }
    
    /// Aplica el estilo de botón de acción secundaria
    func secondaryActionButtonStyle() -> some View {
        self.modifier(SecondaryActionButtonStyle())
    }
    
    /// Aplica el estilo de botón flotante
    func floatingActionButtonStyle() -> some View {
        self.modifier(FloatingActionButtonStyle())
    }
    
    /// Aplica el estilo de botón destructivo
    func destructiveButtonStyle() -> some View {
        self.modifier(DestructiveButtonStyle())
    }
}

// MARK: - Custom Button Styles
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions
extension View {
    
    /// Aplica efecto de presión al botón
    func pressableStyle() -> some View {
        self.buttonStyle(PressableButtonStyle())
    }
    
    /// Aplica efecto de rebote al botón
    func bounceStyle() -> some View {
        self.buttonStyle(BounceButtonStyle())
    }
} 