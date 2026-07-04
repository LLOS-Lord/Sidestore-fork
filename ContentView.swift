import SwiftUI

/**
 * ContentView.swift
 * Giao diện người dùng chính của SideLoader.
 */

struct ContentView: View {
    @StateObject var viewModel = MainViewModel()
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Section
                StatusCard(title: "Local VPN", 
                          status: viewModel.isVPNConnected ? "Đã kết nối" : "Đã ngắt", 
                          color: viewModel.isVPNConnected ? .green : .red)
                
                StatusCard(title: "Device Muxer", 
                          status: viewModel.isMuxerReady ? "Sẵn sàng" : "Chưa khởi tạo", 
                          color: viewModel.isMuxerReady ? .green : .orange)
                
                Text(viewModel.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Divider()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: { viewModel.toggleVPN() }) {
                        Label(viewModel.isVPNConnected ? "Tắt VPN" : "Bật VPN", systemImage: "network")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: { showingFilePicker = true }) {
                        Label("Cài đặt IPA", systemImage: "plus.app")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.isMuxerReady)
                    
                    Button(action: { viewModel.refreshCerts() }) {
                        Label("Làm mới Chứng chỉ", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { viewModel.fixAFC() }) {
                        Label("Sửa lỗi AFC", systemImage: "wrench.and.screwdriver")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("SideLoader")
            .sheet(isPresented: $showingFilePicker) {
                VStack {
                    Text("IPA File Picker (Mô phỏng)")
                    Button("Đóng") { showingFilePicker = false }
                }
                .padding()
            }
        }
    }
}

struct StatusCard: View {
    let title: String
    let status: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(status)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
