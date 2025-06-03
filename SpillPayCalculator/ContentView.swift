//
//  ContentView.swift
//  SpillPayCalculator
//
//  Created by Junxian Zhao on 6/3/25.
//

import SwiftUI

#Preview {
    ContentView()
}

struct Person: Identifiable, Codable {
    let id = UUID()
    var name: String
    var order: Double
}

struct ContentView: View {
    @AppStorage("cachedNames") private var cachedNamesData: Data = Data()
    @State private var people: [Person] = []
    @State private var totalAmount: String = ""
    @State private var sharedItemAmount: String = ""
    
    init() {
        if let decoded = try? JSONDecoder().decode([Person].self, from: cachedNamesData) {
            _people = State(initialValue: decoded.map { Person(name: $0.name, order: 0.0) })
        } else {
            _people = State(initialValue: [Person(name: "", order: 0.0)])
        }
    }
    
    @FocusState private var totalFieldFocused: Bool
    @State private var isConfirmed: Bool = false
    
    var body: some View {
        VStack {
            List {
                // NEW: Shared item column
                HStack {
                    Text("Shared Item")
                    Spacer()
                    TextField("Price", text: $sharedItemAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(5)
                .background(Color.yellow.opacity(0.3))
                .cornerRadius(8)
                ForEach($people.indices, id: \.self) { index in
                    let color = Color(hue: Double(index) / Double(max(people.count, 1)), saturation: 0.3, brightness: 0.9)
                    HStack {
                        TextField("Name", text: $people[index].name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: people[index].name) { _ in
                                cacheNames()
                            }
                        TextField("Order", value: $people[index].order, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: {
                            people.remove(at: index)
                            cacheNames()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(5)
                    .background(color)
                    .cornerRadius(8)
                }
                Button("Add Person") {
                    people.append(Person(name: "", order: 0.0))
                }
            }
            
            HStack {
                Text("Total (with tax/tip):")
                TextField("Total", text: $totalAmount)
                    .submitLabel(.done)
                    .onSubmit {
                        hideKeyboard()
                        isConfirmed = true
                    }
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            
            Button("Confirm Total") {
                hideKeyboard()
                isConfirmed = true
            }
            .padding(.bottom)
            
            if isConfirmed, let total = Double(totalAmount), total > 0 {
                let totalOrder = people.reduce(0.0) { $0 + $1.order }
                if totalOrder > 0 {
                    List {
                        ForEach(Array(people.enumerated()), id: \.1.id) { index, person in
                            let shared = Double(sharedItemAmount) ?? 0.0
                            let share = ((person.order + shared / Double(people.count)) / (totalOrder + shared)) * total
                            if share > 0 {
                                let color = Color(hue: Double(index) / Double(max(people.count, 1)), saturation: 0.2, brightness: 0.95)
                                Text("\(person.name.isEmpty ? "Unnamed" : person.name): $\(String(format: "%.2f", share))")
                                    .padding(5)
                                    .background(color)
                                    .cornerRadius(8)
                            }
                        }}
                    .listStyle(PlainListStyle())
                    .frame(height: 200)
                } else {
                    Text("Enter at least one non-zero order.")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
    
    // Dismiss keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // NEW: Cache names to @AppStorage as JSON
    func cacheNames() {
        let namesToCache = people.map { Person(name: $0.name, order: 0.0) }
        if let encoded = try? JSONEncoder().encode(namesToCache) {
            cachedNamesData = encoded
        }
    }
}
