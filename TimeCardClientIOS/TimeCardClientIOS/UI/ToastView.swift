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
    let viewModel: ToastViewModel
    
    var body: some View {
        VStack {
            if viewModel.isPresented {
                Spacer()
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(viewModel.message)
                        .foregroundStyle(.black)
                        .accessibilityIdentifier("text_message")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 255/255, green: 228/255, blue: 222/255))
                .clipShape(.buttonBorder)
                .padding()
            }
        }
        .onChange(of: viewModel.isPresented) { _, newValue in
            if newValue == false {
                return
            }
            
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation {
                    viewModel.isPresented = false
                }
            }
        }
    }
}

#Preview {
    let viewModel = ToastViewModel()
    viewModel.isPresented = true
    viewModel.message = "test"
    return ToastView(viewModel: viewModel)
}
