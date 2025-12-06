//
//  DashboardView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Statistics section
                        StatisticsSection()
                        
                        // Recently opened books - takes most of available space
                        RecentlyOpenedSection()
                            .frame(height: max(geometry.size.height * 0.7, 450))
                        
                        // Add bottom padding to ensure content doesn't overlap with button
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Learn section (flashcards) - fixed at bottom
                VStack {
                    LearnSection()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    NavigationView {
        DashboardView()
    }
}
