//
//  NetworkMonitor.swift
//  Audio
//
//  Created by Aaron Zheng on 1/19/24.
//

import Foundation
import Network

class NetworkMonitor: ObservableObject {
    
    
    @Published var previousNetwork: Network.NWInterface.InterfaceType?
    
    private var monitor: NWPathMonitor = NWPathMonitor()
    private var queue: DispatchQueue
    
    init() {
        self.queue = DispatchQueue.global()
    }

    deinit {
        self.monitor.cancel()
    }
    
    @MainActor
    func start() {
        // Set up a handler to be notified when the network path changes
        self.monitor.pathUpdateHandler = { path in
            guard path.status == .satisfied else {
                print("No internet connection.")
                DispatchQueue.main.async {
                    self.previousNetwork = nil
                }
                return
            }
            
            print("We're connected to the internet!")
            
            if path.usesInterfaceType(.wifi) && self.previousNetwork != .wifi {
                print("NOTE: Connected via Wi-Fi. Previous network:", self.previousNetwork ?? "nil")
                
                DispatchQueue.main.async {
                    self.previousNetwork = .wifi
                }
                
            } else if path.usesInterfaceType(.cellular) && self.previousNetwork != .cellular {
                print("NOTE: Connected via Cellular")
                
                DispatchQueue.main.async {
                    self.previousNetwork = .cellular
                }
                
            } else if path.usesInterfaceType(.wiredEthernet) && self.previousNetwork != .wiredEthernet {
                print("NOTE: Connected via wiredEthernet")
                
                DispatchQueue.main.async {
                    self.previousNetwork = .wiredEthernet
                }

            } else if path.usesInterfaceType(.loopback) && self.previousNetwork != .loopback {
                print("NOTE: Connected via loopback")
                
                DispatchQueue.main.async {
                    self.previousNetwork = .loopback
                }

            } else if path.usesInterfaceType(.other) {
                print("DEBUG: Some new interface")
            }
        }
        
        self.monitor.start(queue: self.queue)
    }
}

