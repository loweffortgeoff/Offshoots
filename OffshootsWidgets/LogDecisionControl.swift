//
//  LogDecisionControl.swift
//  OffshootsWidgets
//

import SwiftUI
import WidgetKit

struct LogDecisionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "LogDecisionControl") {
            ControlWidgetButton(action: OpenLogDecisionIntent()) {
                Label("Log Decision", systemImage: "plus")
            }
        }
        .displayName("Log a Decision")
        .description("Open Offshoots to log a new decision.")
    }
}
