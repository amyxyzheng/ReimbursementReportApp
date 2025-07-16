//
//  TransportationSelector.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

struct TransportationSelector: View {
    @Binding var transportType: TransportType
    @Binding var originCity: String
    @Binding var noTransportReason: NoTransportReason?
    @State private var showingReasonPrompt = false
    
    let isEditable: Bool
    
    init(transportType: Binding<TransportType>,
         originCity: Binding<String>,
         noTransportReason: Binding<NoTransportReason?>,
         isEditable: Bool = true) {
        self._transportType = transportType
        self._originCity = originCity
        self._noTransportReason = noTransportReason
        self.isEditable = isEditable
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(TransportType.allCases) { type in
                HStack {
                    Text(type.displayName)
                    Spacer()
                    if transportType == type {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditable {
                        transportType = type
                        if type == .notApplicable {
                            showingReasonPrompt = true
                        }
                    }
                }
            }
            // Origin city input removed for all types
        }
        .sheet(isPresented: $showingReasonPrompt) {
            reasonPromptSheet
        }
    }
    
    private var reasonPromptSheet: some View {
        NavigationStack {
            VStack {
                Text("Please select a reason why transportation is not applicable:")
                    .font(.headline)
                    .padding()
                
                List {
                    ForEach(NoTransportReason.allCases) { reason in
                        Button(reason.displayName) {
                            noTransportReason = reason
                            showingReasonPrompt = false
                        }
                    }
                }
            }
            .navigationTitle("Why No Transport?")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Revert transport type if no reason selected
                        transportType = .flightTrain
                        noTransportReason = nil
                        showingReasonPrompt = false
                    }
                }
            }
        }
    }
}

#if DEBUG
import SwiftUI

struct TransportationSelector_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Editable")
            TransportationSelector(
                transportType: .constant(.flightTrain),
                originCity: .constant(""),
                noTransportReason: .constant(nil),
                isEditable: true
            )
            
            Text("Read-only")
            TransportationSelector(
                transportType: .constant(.drive),
                originCity: .constant("New York"),
                noTransportReason: .constant(nil),
                isEditable: false
            )
        }
        .padding()
    }
}
#endif 