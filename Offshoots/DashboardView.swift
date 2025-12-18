//
//  DasbboardView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: DecisionStore

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.offshootPrimary.opacity(0.05),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        DashboardHeaderView()

                        QuickStatsSection()

                        RecentDecisionsSection()

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("offshoots")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .offset(y: 10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(DecisionStore())
}
