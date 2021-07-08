//
//  WebRTCClientDelegate.swift
//  AntMediaSDK
//


import Foundation
import WebRTC

internal protocol WebRTCClientDelegate {
    
    func sendMessage(_ message: [String: Any])
    
    func addRemoteStream()
    
    func addLocalStream()
    
    func connectionStateChanged(newState: RTCIceConnectionState);
    
    func dataReceivedFromDataChannel(didReceiveData data: RTCDataBuffer);
}
