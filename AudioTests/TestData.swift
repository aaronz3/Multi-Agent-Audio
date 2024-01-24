//
//  TestData.swift
//  AudioTests
//
//  Created by Aaron Zheng on 1/20/24.
//

import Foundation
@testable import Audio

// MARK: CONNECTION & DISCONNECTION DATA

let emptyConnectedUserUUIDData = """
    {
        "type" : "JustConnectedUser",
        "payload" : { "userUUID" : nil }
    }
    """.data(using: .utf8)

let filledConnectedUserUUIDData = """
    {
        "type" : "JustConnectedUser",
        "payload" : { "userUUID" : "BF73C8CF-8176-4E76-952B-3A20CD2EB21D" }
    }
    """.data(using: .utf8)

let filledJustConnectedUserObject = JustConnectedUser(userUUID: "BF73C8CF-8176-4E76-952B-3A20CD2EB21D")


let filledDisconnectedUserUUID = [ DisconnectedUser(userUUID: "FILLEDCONNECTEDUSERID1"),
                                   DisconnectedUser(userUUID: "FILLEDCONNECTEDUSERID2"),
                                   DisconnectedUser(userUUID: "FILLEDCONNECTEDUSERID3"),
                                   DisconnectedUser(userUUID: "FILLEDCONNECTEDUSERID4")
                                 ]

let filledConnectedUserUUID = [ JustConnectedUser(userUUID: "FILLEDCONNECTEDUSERID1"),
                                JustConnectedUser(userUUID: "FILLEDCONNECTEDUSERID2"),
                                JustConnectedUser(userUUID: "FILLEDCONNECTEDUSERID3"),
                                JustConnectedUser(userUUID: "FILLEDCONNECTEDUSERID4")
                              ]
        
let filledJustConnectedUserUUIDDataArray = [
    """
    {
        "type" : "JustConnectedUser",
        "payload" : { "userUUID" : "FILLEDCONNECTEDUSERID1" }
    }
    """.data(using: .utf8),
    """
    {
        "type" : "JustConnectedUser",
        "payload" : { "userUUID" : "FILLEDCONNECTEDUSERID2" }
    }
    """.data(using: .utf8),
    """
    {
        "type" : "JustConnectedUser",
        "payload" : { "userUUID" : "FILLEDCONNECTEDUSERID3" }
    }
    """.data(using: .utf8),
    """
    {
        "type" : "JustConnectedUser",
        "payload" : { "userUUID" : "FILLEDCONNECTEDUSERID4" }
    }
    """.data(using: .utf8)
]

let filledJustDisconnectedUserUUIDDataArray = [
    """
    {
        "type" : "DisconnectedUser",
        "payload" : { "userUUID" : "FILLEDCONNECTEDUSERID1" }
    }
    """.data(using: .utf8),
    """
    {
        "type" : "DisconnectedUser",
        "payload" : { "userUUID" : "FILLEDCONNECTEDUSERID2" }
    }
    """.data(using: .utf8),
    """
    {
        "type" : "DisconnectedUser",
        "payload" : { "userUUID" : "FILLEDCONNECTEDUSERID3" }
    }
    """.data(using: .utf8),
    """
    {
        "type" : "DisconnectedUser",
        "payload" : { "userUUID" : "FILLEDCONNECTEDUSERID4" }
    }
    """.data(using: .utf8)
]

let emptyDisconnectedUserUUID = """
    {
        "type" : "DisconnectedUser",
        "payload" : { "userUUID" : nil }
    }
    """.data(using: .utf8)



// MARK: SDP & CANDIDATE DATA

let toThisUserSDPData = [
    """
    {
      "type": "SessionDescription",
      "payload": {
        "fromUUID": "USER1",
        "toUUID": "THISUSER",
        "type": "offer",
        "sdp": "v=0\\r\\no=- 5415472175708873252 2 IN IP4 127.0.0.1\\r\\ns=-\\r\\nt=0 0\\r\\na=group:BUNDLE 0\\r\\na=extmap-allow-mixed\\r\\na=msid-semantic: WMS stream\\r\\nm=audio 9 UDP/TLS/RTP/SAVPF 111 63 9 102 0 8 13 110 126\\r\\nc=IN IP4 0.0.0.0\\r\\na=rtcp:9 IN IP4 0.0.0.0\\r\\na=ice-ufrag:tnFG\\r\\na=ice-pwd:iTzcO8OSUxk5ZDrsxtHGugam\\r\\na=ice-options:trickle renomination\\r\\na=fingerprint:sha-256 76:DF:F9:03:1D:68:C3:22:0D:4C:0A:6E:DC:2A:D8:36:27:9A:5E:1F:2D:39:A2:9B:E7:B9:38:34:70:34:6A:B3\\r\\na=setup:actpass\\r\\na=mid:0\\r\\na=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level\\r\\na=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\\r\\na=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\\r\\na=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\\r\\na=sendrecv\\r\\na=msid:stream audio0\\r\\na=rtcp-mux\\r\\na=rtpmap:111 opus/48000/2\\r\\na=rtcp-fb:111 transport-cc\\r\\na=fmtp:111 minptime=10;useinbandfec=1\\r\\na=rtpmap:63 red/48000/2\\r\\na=fmtp:63 111/111\\r\\na=rtpmap:9 G722/8000\\r\\na=rtpmap:102 ILBC/8000\\r\\na=rtpmap:0 PCMU/8000\\r\\na=rtpmap:8 PCMA/8000\\r\\na=rtpmap:13 CN/8000\\r\\na=rtpmap:110 telephone-event/48000\\r\\na=rtpmap:126 telephone-event/8000\\r\\na=ssrc:3204832475 cname:cUbEqQargUoZt/TP\\r\\na=ssrc:3204832475 msid:stream audio0\\r\\n"
      }
    }
    """.data(using: .utf8),
    """
    {
      "type": "SessionDescription",
      "payload": {
        "fromUUID": "USER2",
        "toUUID": "THISUSER",
        "type": "offer",
        "sdp": "v=0\\r\\no=- 5907036994142298080 2 IN IP4 127.0.0.1\\r\\ns=-\\r\\nt=0 0\\r\\na=group:BUNDLE 0\\r\\na=extmap-allow-mixed\\r\\na=msid-semantic: WMS stream\\r\\nm=audio 9 UDP/TLS/RTP/SAVPF 111 63 9 102 0 8 13 110 126\\r\\nc=IN IP4 0.0.0.0\\r\\na=rtcp:9 IN IP4 0.0.0.0\\r\\na=ice-ufrag:XUF+\\r\\na=ice-pwd:BaGV7/XEOwIhQH6Oc4HPuGAn\\r\\na=ice-options:trickle renomination\\r\\na=fingerprint:sha-256 4A:3F:93:2C:BB:2E:CF:00:E1:77:57:7D:9D:8F:7C:02:F5:E9:0A:30:C8:58:6D:0A:1E:41:B6:0C:30:B7:0D:AA\\r\\na=setup:actpass\\r\\na=mid:0\\r\\na=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level\\r\\na=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\\r\\na=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\\r\\na=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\\r\\na=sendrecv\\r\\na=msid:stream audio0\\r\\na=rtcp-mux\\r\\na=rtpmap:111 opus/48000/2\\r\\na=rtcp-fb:111 transport-cc\\r\\na=fmtp:111 minptime=10;useinbandfec=1\\r\\na=rtpmap:63 red/48000/2\\r\\na=fmtp:63 111/111\\r\\na=rtpmap:9 G722/8000\\r\\na=rtpmap:102 ILBC/8000\\r\\na=rtpmap:0 PCMU/8000\\r\\na=rtpmap:8 PCMA/8000\\r\\na=rtpmap:13 CN/8000\\r\\na=rtpmap:110 telephone-event/48000\\r\\na=rtpmap:126 telephone-event/8000\\r\\na=ssrc:710158185 cname:8Nj5EEg7jPGGEZrL\\r\\na=ssrc:710158185 msid:stream audio0\\r\\n"
      }
    }
    """.data(using: .utf8),
    """
    {
      "type": "SessionDescription",
      "payload": {
        "fromUUID": "USER3",
        "toUUID": "THISUSER",
        "type": "offer",
        "sdp": "v=0\\r\\no=- 5907036994142298080 2 IN IP4 127.0.0.1\\r\\ns=-\\r\\nt=0 0\\r\\na=group:BUNDLE 0\\r\\na=extmap-allow-mixed\\r\\na=msid-semantic: WMS stream\\r\\nm=audio 9 UDP/TLS/RTP/SAVPF 111 63 9 102 0 8 13 110 126\\r\\nc=IN IP4 0.0.0.0\\r\\na=rtcp:9 IN IP4 0.0.0.0\\r\\na=ice-ufrag:XUF+\\r\\na=ice-pwd:BaGV7/XEOwIhQH6Oc4HPuGAn\\r\\na=ice-options:trickle renomination\\r\\na=fingerprint:sha-256 4A:3F:93:2C:BB:2E:CF:00:E1:77:57:7D:9D:8F:7C:02:F5:E9:0A:30:C8:58:6D:0A:1E:41:B6:0C:30:B7:0D:AA\\r\\na=setup:actpass\\r\\na=mid:0\\r\\na=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level\\r\\na=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\\r\\na=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\\r\\na=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\\r\\na=sendrecv\\r\\na=msid:stream audio0\\r\\na=rtcp-mux\\r\\na=rtpmap:111 opus/48000/2\\r\\na=rtcp-fb:111 transport-cc\\r\\na=fmtp:111 minptime=10;useinbandfec=1\\r\\na=rtpmap:63 red/48000/2\\r\\na=fmtp:63 111/111\\r\\na=rtpmap:9 G722/8000\\r\\na=rtpmap:102 ILBC/8000\\r\\na=rtpmap:0 PCMU/8000\\r\\na=rtpmap:8 PCMA/8000\\r\\na=rtpmap:13 CN/8000\\r\\na=rtpmap:110 telephone-event/48000\\r\\na=rtpmap:126 telephone-event/8000\\r\\na=ssrc:710158185 cname:8Nj5EEg7jPGGEZrL\\r\\na=ssrc:710158185 msid:stream audio0\\r\\n"
      }
    }
    """.data(using: .utf8),
    """
    {
      "type": "SessionDescription",
      "payload": {
        "fromUUID": "USER4",
        "toUUID": "THISUSER",
        "type": "offer",
        "sdp": "v=0\\r\\no=- 5907036994142298080 2 IN IP4 127.0.0.1\\r\\ns=-\\r\\nt=0 0\\r\\na=group:BUNDLE 0\\r\\na=extmap-allow-mixed\\r\\na=msid-semantic: WMS stream\\r\\nm=audio 9 UDP/TLS/RTP/SAVPF 111 63 9 102 0 8 13 110 126\\r\\nc=IN IP4 0.0.0.0\\r\\na=rtcp:9 IN IP4 0.0.0.0\\r\\na=ice-ufrag:XUF+\\r\\na=ice-pwd:BaGV7/XEOwIhQH6Oc4HPuGAn\\r\\na=ice-options:trickle renomination\\r\\na=fingerprint:sha-256 4A:3F:93:2C:BB:2E:CF:00:E1:77:57:7D:9D:8F:7C:02:F5:E9:0A:30:C8:58:6D:0A:1E:41:B6:0C:30:B7:0D:AA\\r\\na=setup:actpass\\r\\na=mid:0\\r\\na=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level\\r\\na=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\\r\\na=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\\r\\na=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\\r\\na=sendrecv\\r\\na=msid:stream audio0\\r\\na=rtcp-mux\\r\\na=rtpmap:111 opus/48000/2\\r\\na=rtcp-fb:111 transport-cc\\r\\na=fmtp:111 minptime=10;useinbandfec=1\\r\\na=rtpmap:63 red/48000/2\\r\\na=fmtp:63 111/111\\r\\na=rtpmap:9 G722/8000\\r\\na=rtpmap:102 ILBC/8000\\r\\na=rtpmap:0 PCMU/8000\\r\\na=rtpmap:8 PCMA/8000\\r\\na=rtpmap:13 CN/8000\\r\\na=rtpmap:110 telephone-event/48000\\r\\na=rtpmap:126 telephone-event/8000\\r\\na=ssrc:710158185 cname:8Nj5EEg7jPGGEZrL\\r\\na=ssrc:710158185 msid:stream audio0\\r\\n"
      }
    }
    """.data(using: .utf8),
    """
    {
      "type": "SessionDescription",
      "payload": {
        "fromUUID": "USER5",
        "toUUID": "THISUSER",
        "type": "offer",
        "sdp": "v=0\\r\\no=- 5907036994142298080 2 IN IP4 127.0.0.1\\r\\ns=-\\r\\nt=0 0\\r\\na=group:BUNDLE 0\\r\\na=extmap-allow-mixed\\r\\na=msid-semantic: WMS stream\\r\\nm=audio 9 UDP/TLS/RTP/SAVPF 111 63 9 102 0 8 13 110 126\\r\\nc=IN IP4 0.0.0.0\\r\\na=rtcp:9 IN IP4 0.0.0.0\\r\\na=ice-ufrag:XUF+\\r\\na=ice-pwd:BaGV7/XEOwIhQH6Oc4HPuGAn\\r\\na=ice-options:trickle renomination\\r\\na=fingerprint:sha-256 4A:3F:93:2C:BB:2E:CF:00:E1:77:57:7D:9D:8F:7C:02:F5:E9:0A:30:C8:58:6D:0A:1E:41:B6:0C:30:B7:0D:AA\\r\\na=setup:actpass\\r\\na=mid:0\\r\\na=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level\\r\\na=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\\r\\na=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\\r\\na=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\\r\\na=sendrecv\\r\\na=msid:stream audio0\\r\\na=rtcp-mux\\r\\na=rtpmap:111 opus/48000/2\\r\\na=rtcp-fb:111 transport-cc\\r\\na=fmtp:111 minptime=10;useinbandfec=1\\r\\na=rtpmap:63 red/48000/2\\r\\na=fmtp:63 111/111\\r\\na=rtpmap:9 G722/8000\\r\\na=rtpmap:102 ILBC/8000\\r\\na=rtpmap:0 PCMU/8000\\r\\na=rtpmap:8 PCMA/8000\\r\\na=rtpmap:13 CN/8000\\r\\na=rtpmap:110 telephone-event/48000\\r\\na=rtpmap:126 telephone-event/8000\\r\\na=ssrc:710158185 cname:8Nj5EEg7jPGGEZrL\\r\\na=ssrc:710158185 msid:stream audio0\\r\\n"
      }
    }
    """.data(using: .utf8),
    """
    {
      "type": "SessionDescription",
      "payload": {
        "fromUUID": "USER6",
        "toUUID": "THISUSER",
        "type": "offer",
        "sdp": "v=0\\r\\no=- 5907036994142298080 2 IN IP4 127.0.0.1\\r\\ns=-\\r\\nt=0 0\\r\\na=group:BUNDLE 0\\r\\na=extmap-allow-mixed\\r\\na=msid-semantic: WMS stream\\r\\nm=audio 9 UDP/TLS/RTP/SAVPF 111 63 9 102 0 8 13 110 126\\r\\nc=IN IP4 0.0.0.0\\r\\na=rtcp:9 IN IP4 0.0.0.0\\r\\na=ice-ufrag:XUF+\\r\\na=ice-pwd:BaGV7/XEOwIhQH6Oc4HPuGAn\\r\\na=ice-options:trickle renomination\\r\\na=fingerprint:sha-256 4A:3F:93:2C:BB:2E:CF:00:E1:77:57:7D:9D:8F:7C:02:F5:E9:0A:30:C8:58:6D:0A:1E:41:B6:0C:30:B7:0D:AA\\r\\na=setup:actpass\\r\\na=mid:0\\r\\na=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level\\r\\na=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\\r\\na=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\\r\\na=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\\r\\na=sendrecv\\r\\na=msid:stream audio0\\r\\na=rtcp-mux\\r\\na=rtpmap:111 opus/48000/2\\r\\na=rtcp-fb:111 transport-cc\\r\\na=fmtp:111 minptime=10;useinbandfec=1\\r\\na=rtpmap:63 red/48000/2\\r\\na=fmtp:63 111/111\\r\\na=rtpmap:9 G722/8000\\r\\na=rtpmap:102 ILBC/8000\\r\\na=rtpmap:0 PCMU/8000\\r\\na=rtpmap:8 PCMA/8000\\r\\na=rtpmap:13 CN/8000\\r\\na=rtpmap:110 telephone-event/48000\\r\\na=rtpmap:126 telephone-event/8000\\r\\na=ssrc:710158185 cname:8Nj5EEg7jPGGEZrL\\r\\na=ssrc:710158185 msid:stream audio0\\r\\n"
      }
    }
    """.data(using: .utf8)
]


let user1CandidateData = [
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER1","toUUID":"THISUSER","sdp":"candidate:1101761059 1 udp 2122063615 10.204.136.88 49739 typ host generation 0 ufrag tnFG network-id 6 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER1","toUUID":"THISUSER","sdp":"candidate:1462800804 1 udp 2122260223 169.254.212.237 50581 typ host generation 0 ufrag tnFG network-id 1 network-cost 10"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER1","toUUID":"THISUSER","sdp":"candidate:1101761059 1 udp 2122063615 10.204.136.88 49739 typ host generation 0 ufrag tnFG network-id 6 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER1","toUUID":"THISUSER","sdp":"candidate:7172996 1 udp 2122197247 2409:8970:11b5:4e40:a0dd:ab6f:237d:4c9 58866 typ host generation 0 ufrag tnFG network-id 7 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER1","toUUID":"THISUSER","sdp":"candidate:979198579 1 udp 2121935103 2409:8170:1047:711f:1096:a404:e567:77 56201 typ host generation 0 ufrag tnFG network-id 2 network-cost 50"}}
    """.data(using: .utf8)
]

let user2CandidateData = [
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER2","toUUID":"THISUSER","sdp":"candidate:1101761059 1 udp 2122063615 10.204.136.88 49739 typ host generation 0 ufrag tnFG network-id 6 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER2","toUUID":"THISUSER","sdp":"candidate:1462800804 1 udp 2122260223 169.254.212.237 50581 typ host generation 0 ufrag tnFG network-id 1 network-cost 10"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER2","toUUID":"THISUSER","sdp":"candidate:1101761059 1 udp 2122063615 10.204.136.88 49739 typ host generation 0 ufrag tnFG network-id 6 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER2","toUUID":"THISUSER","sdp":"candidate:7172996 1 udp 2122197247 2409:8970:11b5:4e40:a0dd:ab6f:237d:4c9 58866 typ host generation 0 ufrag tnFG network-id 7 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER2","toUUID":"THISUSER","sdp":"candidate:979198579 1 udp 2121935103 2409:8170:1047:711f:1096:a404:e567:77 56201 typ host generation 0 ufrag tnFG network-id 2 network-cost 50"}}
    """.data(using: .utf8)
]

let user3CandidateData = [
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER3","toUUID":"THISUSER","sdp":"candidate:1101761059 1 udp 2122063615 10.204.136.88 49739 typ host generation 0 ufrag tnFG network-id 6 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER3","toUUID":"THISUSER","sdp":"candidate:1462800804 1 udp 2122260223 169.254.212.237 50581 typ host generation 0 ufrag tnFG network-id 1 network-cost 10"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER3","toUUID":"THISUSER","sdp":"candidate:1101761059 1 udp 2122063615 10.204.136.88 49739 typ host generation 0 ufrag tnFG network-id 6 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER3","toUUID":"THISUSER","sdp":"candidate:7172996 1 udp 2122197247 2409:8970:11b5:4e40:a0dd:ab6f:237d:4c9 58866 typ host generation 0 ufrag tnFG network-id 7 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER3","toUUID":"THISUSER","sdp":"candidate:979198579 1 udp 2121935103 2409:8170:1047:711f:1096:a404:e567:77 56201 typ host generation 0 ufrag tnFG network-id 2 network-cost 50"}}
    """.data(using: .utf8)
]


let user4CandidateData = [
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER4","toUUID":"THISUSER","sdp":"candidate:1101761059 1 udp 2122063615 10.204.136.88 49739 typ host generation 0 ufrag tnFG network-id 6 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER4","toUUID":"THISUSER","sdp":"candidate:1462800804 1 udp 2122260223 169.254.212.237 50581 typ host generation 0 ufrag tnFG network-id 1 network-cost 10"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER4","toUUID":"THISUSER","sdp":"candidate:1101761059 1 udp 2122063615 10.204.136.88 49739 typ host generation 0 ufrag tnFG network-id 6 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER4","toUUID":"THISUSER","sdp":"candidate:7172996 1 udp 2122197247 2409:8970:11b5:4e40:a0dd:ab6f:237d:4c9 58866 typ host generation 0 ufrag tnFG network-id 7 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER4","toUUID":"THISUSER","sdp":"candidate:979198579 1 udp 2121935103 2409:8170:1047:711f:1096:a404:e567:77 56201 typ host generation 0 ufrag tnFG network-id 2 network-cost 50"}}
    """.data(using: .utf8)
]

let user5CandidateData = [
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER5","toUUID":"THISUSER","sdp":"candidate:1101761059 1 udp 2122063615 10.204.136.88 49739 typ host generation 0 ufrag tnFG network-id 6 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER5","toUUID":"THISUSER","sdp":"candidate:1462800804 1 udp 2122260223 169.254.212.237 50581 typ host generation 0 ufrag tnFG network-id 1 network-cost 10"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER5","toUUID":"THISUSER","sdp":"candidate:1101761059 1 udp 2122063615 10.204.136.88 49739 typ host generation 0 ufrag tnFG network-id 6 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER5","toUUID":"THISUSER","sdp":"candidate:7172996 1 udp 2122197247 2409:8970:11b5:4e40:a0dd:ab6f:237d:4c9 58866 typ host generation 0 ufrag tnFG network-id 7 network-cost 900"}}
    """.data(using: .utf8),
    """
    {"type":"IceCandidate","payload":{"sdpMLineIndex":0,"sdpMid":"0","fromUUID":"USER5","toUUID":"THISUSER","sdp":"candidate:979198579 1 udp 2121935103 2409:8170:1047:711f:1096:a404:e567:77 56201 typ host generation 0 ufrag tnFG network-id 2 network-cost 50"}}
    """.data(using: .utf8)
]
