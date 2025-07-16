//
//  CustomDatePicker.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

struct CustomDatePicker: View {
    let title: String
    @Binding var date: Date
    var displayedComponents: DatePickerComponents = .date
    var minDate: Date? = nil
    var maxDate: Date? = nil

    @State private var showingDatePicker = false
    @State private var tempDate: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Button(action: {
                tempDate = date
                showingDatePicker = true
            }) {
                HStack {
                    Text(date.formatted(date: .abbreviated, time: displayedComponents == .date ? .omitted : .shortened))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingDatePicker) {
            VStack {
                DatePicker(
                    title,
                    selection: $tempDate,
                    in: (minDate ?? Date.distantPast)...(maxDate ?? Date.distantFuture),
                    displayedComponents: displayedComponents
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding()
                Button("Done") {
                    date = tempDate
                    showingDatePicker = false
                }
                .padding(.top)
                Spacer()
            }
            .presentationDetents([.medium])
        }
    }
}



#if DEBUG
struct CustomDatePicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomDatePicker(title: "Start Date", date: .constant(Date()))
            CustomDatePicker(title: "End Date", date: .constant(Date()))
        }
        .padding()
    }
}
#endif 