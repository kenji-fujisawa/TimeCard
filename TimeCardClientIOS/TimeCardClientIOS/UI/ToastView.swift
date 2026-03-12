//
//  ToastView.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/11/05.
//

import SwiftUI

@Observable
class ToastViewModel {
    var isPresented: Bool = false
    var message: String = ""
}

struct ToastView: View {
    @State var model: ToastViewModel
    
    var body: some View {
        VStack {
            if model.isPresented {
                Spacer()
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(model.message)
                        .accessibilityIdentifier("text_message")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 255/255, green: 228/255, blue: 222/255))
                .clipShape(.buttonBorder)
                .padding()
            }
        }
        .onChange(of: model.isPresented) { _, newValue in
            if newValue == false {
                return
            }
            
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation {
                    model.isPresented = false
                }
            }
        }
    }
}

#Preview {
    let model = ToastViewModel()
    model.isPresented = true
    model.message = "test"
    return ToastView(model: model)
}
