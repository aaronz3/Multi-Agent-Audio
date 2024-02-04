//
//  NetworkMonitor.swift
//  Audio
//
//  Created by Aaron Zheng on 1/19/24.
//

import Foundation
import Network

class NetworkMonitor: ObservableObject {
    
    private var monitor: NWPathMonitor = NWPathMonitor()
    private var queue: DispatchQueue
    var previousNetwork: Network.NWInterface.InterfaceType?
    
    
    init() {
        self.queue = DispatchQueue.global()
    }

    deinit {
        self.monitor.cancel()
    }
    
    func start() {
        
        // Set up a handler to be notified when the network path changes
        self.monitor.pathUpdateHandler = { path in


            if path.usesInterfaceType(.wifi) && self.previousNetwork != .wifi {
                print("NOTE: Connected via Wi-Fi. Previous network:", self.previousNetwork ?? "nil")
                
                self.previousNetwork = .wifi

                
            } else if path.usesInterfaceType(.cellular) && self.previousNetwork != .cellular {
                print("NOTE: Connected via Cellular")
                self.previousNetwork = .cellular

                
            } else if path.usesInterfaceType(.wiredEthernet) && self.previousNetwork != .wiredEthernet {
                print("NOTE: Connected via wiredEthernet")
                
                self.previousNetwork = .wiredEthernet
                
                
            } else if path.usesInterfaceType(.loopback) && self.previousNetwork != .loopback {
                print("NOTE: Connected via loopback")
                
                self.previousNetwork = .loopback
                
                
            } else if path.usesInterfaceType(.other) {
                print("DEBUG: Some new interface")
            }
        }
        
        self.monitor.start(queue: self.queue)
    }
}

