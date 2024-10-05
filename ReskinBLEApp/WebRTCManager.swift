import WebRTC

class WebRTCManager: NSObject {
    private var peerConnection: RTCPeerConnection?
    private var localVideoTrack: RTCVideoTrack?
    private var localStream: RTCMediaStream?
    
    private let factory: RTCPeerConnectionFactory
    
    override init() {
        RTCInitializeSSL()
        factory = RTCPeerConnectionFactory()
        super.init()
        setupPeerConnection()
    }
    
    private func setupPeerConnection() {
        let configuration = RTCConfiguration()
        // Configure your ICE servers here
        configuration.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        
        peerConnection = factory.peerConnection(with: configuration, constraints: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), delegate: nil)
        
        peerConnection?.add(localStream!)
    }
    
    func startStreaming() {
        let videoSource = factory.videoSource()
        localVideoTrack = factory.videoTrack(with: videoSource, trackId: "video0")
        
        let mediaStream = factory.mediaStream(withStreamId: "stream0")
        mediaStream.addVideoTrack(localVideoTrack!)
        localStream = mediaStream
        
        peerConnection?.add(localStream!)
    }
    
    func stopStreaming() {
        peerConnection?.close()
        peerConnection = nil
        localStream = nil
        localVideoTrack = nil
    }
}
