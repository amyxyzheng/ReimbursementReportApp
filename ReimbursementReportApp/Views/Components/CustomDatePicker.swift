//
//  CustomDatePicker.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

struct CustomDatePicker: View {
    @Binding var date: Date
    let title: String
    let displayedComponents: DatePickerComponents
    
    @State private var showingDatePicker = false
    @State private var tempDate: Date
    
    init(title: String, date: Binding<Date>, displayedComponents: DatePickerComponents = .date) {
        self.title = title
        self._date = date
        self.displayedComponents = displayedComponents
        self._tempDate = State(initialValue: date.wrappedValue)
    }
    
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
                    Text(date.formatted(date: .abbreviated, time: displayedComponents.contains(.hourAndMinute) ? .shortened : .omitted))
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
                    displayedComponents: displayedComponents
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding()
                .onChange(of: tempDate) { newValue in
                    date = newValue
                    showingDatePicker = false
                }
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