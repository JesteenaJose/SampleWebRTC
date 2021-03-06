//
//  ConferenceClient.swift
//  WebRTCiOSSDK
//

import Foundation
import Starscream

public protocol ConferenceClientProtocol {
    
    /**
     Join the room
     - roomId: the id of the room that conference client joins
     - streamId: the preferred stream id that can be sent to the server for publishing. Server likely responds the same streamId in
     delegate's streamIdToPublish method
     */
    func joinRoom(roomId:String, streamId:String)
    
    /*
     Leave the room
     */
    func leaveRoom();
}

public protocol ConferenceClientDelegate
{
    /**
     It's called after join to the room.
     - streamId: the id of the stream tha can be used to publish stream.
        It's not an obligation to publish a stream. It changes according to the project
     */
    func streamIdToPublish(streamId: String);
    
    /**
      Called when new streams join to the room. So that  they can be played
     - streams:  stream id array of the streams that join to the room
     */
    func newStreamsJoined(streams: [String]);
    
    /**
     Called when some streams leaves from the room. So that players can be removed from the user interface
     - streams: stream id array of the stream that leaves from the room
     */
    func streamsLeaved(streams: [String]);
}

open class ConferenceClient: ConferenceClientProtocol, WebSocketDelegate
{
    var serverURL: String;
    var webSocket: WebSocket;
    var roomId: String!;
    var streamId: String?;
    var streamsInTheRoom:[String] = [];
    
    var delegate: ConferenceClientDelegate!;
    
    var roomInfoGetterTimer: Timer?;
    
    public init(serverURL:String, conferenceClientDelegate:ConferenceClientDelegate)
    {
        self.serverURL = serverURL;
        var request = URLRequest(url: URL(string: self.serverURL)!)
        request.timeoutInterval = 5
        webSocket = WebSocket(request: request)
        webSocket.delegate = self;
        self.delegate = conferenceClientDelegate;
    }
    
    deinit {
        roomInfoGetterTimer?.invalidate()
    }
    
    public func websocketDidConnect(socket: WebSocketClient)
    {
        let joinRoomMessage =  [
                            COMMAND: "joinRoom",
                            ROOM_ID: self.roomId!,
                            STREAM_ID: self.streamId ?? "" ] as [String : Any]
        
        webSocket.write(string: joinRoomMessage.json)
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        
        AntMediaClient.printf("Received message \(text)")
        if let message = text.toJSON()
        {
           
            guard let command = message[COMMAND] as? String else {
                      return
            }
            
            switch command {
                case NOTIFICATION:
                    guard let definition = message[DEFINITION] as? String else {
                        return
                    }
                    if definition == JOINED_ROOM_DEFINITION
                    {
                        if let streamId = message[STREAM_ID] as? String {
                            self.streamId = streamId
                            self.delegate.streamIdToPublish(streamId: streamId);
                        }
                        
                        if let streams = message[STREAMS] as? [String] {
                            self.streamsInTheRoom = streams;
                            self.delegate.newStreamsJoined(streams:  streams);
                        }
                        
                        //start periodic check
                        roomInfoGetterTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { pingTimer in
                            let jsonString =
                                [ COMMAND: "getRoomInfo",
                                  ROOM_ID: self.roomId as String,
                                  STREAM_ID: self.streamId ?? ""
                                ] as [String: Any]
                            
                            self.webSocket.write(string: jsonString.json)
                        }
                        
                    }
                    break;
                case ROOM_INFORMATION_COMMAND:
                    if let updatedStreamsInTheRoom = message[STREAMS] as? [String] {
                       //check that there is a new stream exists
                        var newStreams:[String] = []
                        var leavedStreams: [String] = []
                        for stream in updatedStreamsInTheRoom
                        {
                           // AntMedia.printf("stream in updatestreamInTheRoom \(stream)")
                            if (!self.streamsInTheRoom.contains(stream)) {
                                newStreams.append(stream)
                            }
                        }
                        //check that any stream is leaved
                       for stream in self.streamsInTheRoom {
                           if (!updatedStreamsInTheRoom.contains(stream)) {
                               leavedStreams.append(stream)
                           }
                       }
                        
                        self.streamsInTheRoom = updatedStreamsInTheRoom
                        
                        if (newStreams.count > 0) {
                            self.delegate.newStreamsJoined(streams: newStreams)
                        }
                        
                        if (leavedStreams.count > 0) {
                            self.delegate.streamsLeaved(streams: leavedStreams)
                        }
                                
                    }
                    
                    break;
            
                default:
                print("default case")
                
            }
            
            
                  
        } else {
            print("WebSocket message JSON parsing error: " + text)
        }
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        
    }
    
    public func joinRoom(roomId: String, streamId:String) {
        self.roomId = roomId;
        self.streamId = streamId;
        webSocket.connect()
    }
    
    public func leaveRoom() {
        roomInfoGetterTimer?.invalidate()
        let joinRoomMessage =  [
                                   COMMAND: "leaveRoom",
                                   ROOM_ID: self.roomId!,
                                   STREAM_ID: self.streamId ?? "" ] as [String : Any]
               
        webSocket.write(string: joinRoomMessage.json)
    }
    
    
}
