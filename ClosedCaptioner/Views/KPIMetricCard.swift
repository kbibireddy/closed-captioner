//
//  KPIMetricCard.swift
//  ClosedCaptioner
//
//  Compact themed sparkline card: latest value + last-hour series.
//

import Charts
import SwiftUI

struct KPIMetricSample: Identifiable, Equatable {
    let date: Date
    let value: Double
    var id: Date { date }
}

enum KPIChartYScale {
    /// Pin the floor at 0 and ensure the ceiling is at least `minimum`.
    case zeroToAtLeast(Double)
    /// Zoom to the visible samples with a little headroom.
    case padded
    case zeroToHundred
}

struct KPIMetricCard: View {
    let title: String
    let valueText: String
    let samples: [KPIMetricSample]
    let colors: ThemeColors
    var window: TimeInterval = AppPerformanceMonitor.fastHistoryWindow
    var yScale: KPIChartYScale = .padded
    var formatY: (Double) -> String = { String(format: "%.0f", $0) }

    private var windowStart: Date {
        Date().addingTimeInterval(-window)
    }

    private static let axisTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private var yDomain: ClosedRange<Double> {
        let values = samples.map(\.value)
        switch yScale {
        case .zeroToHundred:
            return 0...100
        case .zeroToAtLeast(let minimum):
            let maxValue = values.max() ?? minimum
            return 0...max(minimum, maxValue)
        case .padded:
            guard let minValue = values.min(), let maxValue = values.max() else {
                return 0...1
            }
            if minValue == maxValue {
                let pad = max(abs(minValue) * 0.08, minValue == 0 ? 1 : abs(minValue) * 0.08)
                return (minValue - pad)...(maxValue + pad)
            }
            let pad = (maxValue - minValue) * 0.12
            return (minValue - pad)...(maxValue + pad)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppType.display(11, weight: .bold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundColor(colors.muted)

            Text(valueText)
                .font(AppType.display(22, weight: .bold))
                .tracking(-0.4)
                .monospacedDigit()
                .foregroundColor(colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if samples.count < 2 {
                Text("Collecting…")
                    .font(AppType.display(11, weight: .medium))
                    .foregroundColor(colors.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .frame(height: 56)
            } else {
                chart
                    .frame(height: 56)
            }

            HStack {
                Text(Self.axisTimeFormatter.string(from: windowStart))
                Spacer()
                Text(Self.axisTimeFormatter.string(from: Date()))
            }
            .font(AppType.display(10, weight: .medium))
            .foregroundColor(colors.muted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(colors.line, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(valueText)
    }

    private var chart: some View {
        let domain = yDomain
        return Chart(samples) { sample in
            AreaMark(
                x: .value("Time", sample.date),
                yStart: .value("Floor", domain.lowerBound),
                yEnd: .value("Value", sample.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(colors.accent.opacity(0.14))

            LineMark(
                x: .value("Time", sample.date),
                y: .value("Value", sample.value)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            .foregroundStyle(colors.accent)
        }
        .chartXScale(domain: windowStart...Date())
        .chartYScale(domain: domain)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 2)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(colors.line)
                AxisValueLabel {
                    if let number = value.as(Double.self) {
                        Text(formatY(number))
                            .font(AppType.display(9, weight: .medium))
                            .foregroundColor(colors.muted)
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .chartPlotStyle { plot in
            plot.padding(.trailing, 2)
        }
    }
}
