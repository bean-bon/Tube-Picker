//
//  NetworkMonitor.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 13/08/2023.
//

import Network

class NetworkMonitor {
    
    static let shared = NetworkMonitor()
    
    private var callbacks: [() async -> ()] = []
    
    var connected: Bool = false
    
    private init() {}
    
    private let monitor = NWPathMonitor()
    
    func startMonitoring() async {
        for await path in monitor.pathStream() {
            connected = path.status != .unsatisfied
            if connected {
                for callback in callbacks {
                    await callback()
                }
            }
        }
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    func registerConnectedCallback(callback: @escaping () async -> ()) {
        callbacks.append(callback)
    }
    
}

extension NWPathMonitor {
    
    /**
     Stream network updates to enable async callbacks when status changes.
     Based on https://stackoverflow.com/questions/74221389/use-nwpathmonitor-with-swift-modern-concurrency-asyncstream-vs-gcd-dispatchqu.
     */
    func pathStream() -> AsyncStream<NWPath> {
        AsyncStream { next in
            pathUpdateHandler = { new in
                next.yield(new)
            }
            next.onTermination = { _ in
                self.cancel()
            }
            start(queue: DispatchQueue(label: "NetworkMonitorStream"))
        }
    }
    
}
