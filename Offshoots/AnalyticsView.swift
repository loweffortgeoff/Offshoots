//
//  AnalyticsView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct AnalyticsView: View {
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
                    VStack(spacing: 24) {
                        if store.decisions.isEmpty {
                            EmptyAnalyticsView()
                        } else {
                            // Overall Stats
                            OverallStatsCard(decisions: store.decisions)

                            // Category Breakdown
                            CategoryBreakdownCard(decisions: store.decisions)

                            // Outcome Distribution
                            OutcomeDistributionCard(decisions: store.decisions)

                            // Prediction Accuracy
                            PredictionAccuracyCard(decisions: store.decisions)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct EmptyAnalyticsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundStyle(Color.offshootPrimary.opacity(0.3))

            Text("No Data Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.offshootPrimary)

            Text("Log and complete decisions to see your insights and analytics here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct OverallStatsCard: View {
    let decisions: [Decision]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Overview", systemImage: "chart.pie.fill")
                .font(.headline)
                .foregroundStyle(Color.offshootPrimary)

            let total = decisions.count
            let completed = decisions.filter { $0.actual != nil }.count
            let pending = total - completed
            let qualityScore = AnalyticsEngine.decisionQualityScore(from: decisions)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatBox(title: "Total", value: "\(total)", icon: "square.stack.3d.up.fill", color: .offshootPrimary)
                StatBox(title: "Completed", value: "\(completed)", icon: "checkmark.circle.fill", color: .outcomeGood)
                StatBox(title: "Pending", value: "\(pending)", icon: "hourglass", color: .outcomePending)
                StatBox(title: "Quality", value: "\(qualityScore)%", icon: "star.fill", color: .yellow)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct CategoryBreakdownCard: View {
    let decisions: [Decision]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Categories", systemImage: "tag.fill")
                .font(.headline)
                .foregroundStyle(Color.offshootPrimary)

            let categoryCounts = Dictionary(grouping: decisions, by: { $0.category })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }

            if categoryCounts.isEmpty {
                Text("No categories yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(categoryCounts, id: \.key) { category, count in
                        CategoryRow(category: category.rawValue.capitalized, count: count, total: decisions.count)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct CategoryRow: View {
    let category: String
    let count: Int
    let total: Int

    var percentage: Double {
        Double(count) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.offshootPrimary.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.offshootPrimary)
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct OutcomeDistributionCard: View {
    let decisions: [Decision]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Outcomes", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(Color.offshootPrimary)

            let completed = decisions.filter { $0.actual != nil }
            let goodCount = completed.filter { $0.actual == .good }.count
            let neutralCount = completed.filter { $0.actual == .neutral }.count
            let badCount = completed.filter { $0.actual == .bad }.count

            if completed.isEmpty {
                Text("No completed decisions yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    OutcomeBar(outcome: "Good", count: goodCount, total: completed.count, color: .outcomeGood)
                    OutcomeBar(outcome: "Neutral", count: neutralCount, total: completed.count, color: .outcomeNeutral)
                    OutcomeBar(outcome: "Bad", count: badCount, total: completed.count, color: .outcomeBad)
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct OutcomeBar: View {
    let outcome: String
    let count: Int
    let total: Int
    let color: Color

    var percentage: Double {
        Double(count) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(outcome)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Spacer()
                Text("\(Int(percentage * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct PredictionAccuracyCard: View {
    let decisions: [Decision]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Prediction Accuracy", systemImage: "target")
                .font(.headline)
                .foregroundStyle(Color.offshootPrimary)

            let completed = decisions.filter { $0.actual != nil }
            let accurate = completed.filter { $0.expected == $0.actual }.count

            if completed.isEmpty {
                Text("No completed decisions to analyze")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                let accuracy = Double(accurate) / Double(completed.count)

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.offshootPrimary.opacity(0.2), lineWidth: 20)
                            .frame(width: 140, height: 140)

                        Circle()
                            .trim(from: 0, to: accuracy)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.offshootPrimary, Color.offshootPrimary.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 4) {
                            Text("\(Int(accuracy * 100))%")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(Color.offshootPrimary)

                            Text("Accurate")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Correct")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(accurate)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.outcomeGood)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Incorrect")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(completed.count - accurate)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.outcomeBad)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(DecisionStore())
}   
