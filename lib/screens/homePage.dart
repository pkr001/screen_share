
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String by = 'by';
  
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? pc;
  String connectionState = 'noting now';
  bool connectionStatex = false;
  //MediaStream? ms;
  //....iniatialize renderer
  iniatialize() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();
  }



  //...get user media
  Future<void> _getMedia() async {
    final mediaConstraints = <String, dynamic>{ 'video':true,'systemAudio': true,};
    _localStream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);

  
    setState(() {
      
      _localRenderer.srcObject = _localStream;
    });

    _localStream!.getTracks().forEach((track) { 
      pc!.addTrack(track,_localStream!);
    });
  }

  //.....configuratiion
  Map<String, dynamic> configuration = {
    "iceServers": [
      {"url": "stun:stun.l.google.com:19302"},
    ]
  };

  //.....sdp constr..
  final Map<String, dynamic> offerSdpConstraints = {
    
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };

  //....create pear connection
  
  Future<void> connection() async {
    await createPeerConnection(configuration, offerSdpConstraints)
        .then((value) {
      pc = value;

      pc?.onIceCandidate = (e) {
        if (e.candidate != null) {
          FirebaseFirestore.instance.collection(by+'ice').add({
            'candidate': e.candidate,
            'sdpMid': e.sdpMid,
            'sdpMlineIndex': e.sdpMLineIndex,
            'by': by
          });
        }
      };
    });

    pc?.onIceConnectionState = (e) {
     if(e == RTCIceConnectionState.RTCIceConnectionStateConnected){
      setState(() {
        connectionStatex = true;
      });
     }
     if(e == RTCIceConnectionState.RTCIceConnectionStateDisconnected){
      setState(() {
        connectionStatex = false;
      });
     }
     setState(() {
       connectionState = e.toString();
     });
    };

    pc?.onAddTrack = (stream,track) {
     // _remoteRenderer.srcObject!.addTrack(track);
      setState(() {
        
      //  stream.addTrack(track);
        _remoteRenderer.srcObject = stream;
      });
    };
  }

  //.....init state
  @override
  void initState() {
    iniatialize();
    connection();
    _getMedia();
    super.initState();
  }

  //......create offer
   _createOffer() async {
    by = 'offer';
    RTCSessionDescription description =
        await pc!.createOffer({'offerToReceiveVideo': 1,'offerToReceiveAudio': 1});
    String sdp = description.sdp.toString();
    pc!.setLocalDescription(description);
    await FirebaseFirestore.instance.collection('offer').add({'offer': sdp});
  }

  //......create answer
   _createAnswer() async {
    by = 'answer';
    await FirebaseFirestore.instance.collection('offer').get().then((value) {
      RTCSessionDescription abc =
          RTCSessionDescription(value.docs.first['offer'], 'offer');
      pc?.setRemoteDescription(abc);
    });
    RTCSessionDescription description =
        await pc!.createAnswer({'offerToReceiveVideo': 1,'offerToReceiveAudio': 1});

    String sdp = description.sdp.toString();

    pc!.setLocalDescription(description);
    await FirebaseFirestore.instance.collection('answer').add({'answer': sdp});
  }

  //......set answer
    setAnswer() async {
    await FirebaseFirestore.instance.collection('answer').get().then((value) {
      RTCSessionDescription abc =
          RTCSessionDescription(value.docs.first['answer'], 'answer');
      pc?.setRemoteDescription(abc);
      FirebaseFirestore.instance.collection('answer').doc(value.docs.first.id).delete();
    });
  }

  //......add ice from answerer
  iceByAnswer()async{
      await FirebaseFirestore.instance.collection('answerice').get().then((value) {
      value.docs.forEach((element) {
        RTCIceCandidate x = RTCIceCandidate(
            element['candidate'], element['sdpMid'], element['sdpMlineIndex']);
        pc?.addCandidate(x);
        FirebaseFirestore.instance.collection('answerice').doc(element.id).delete();
      });
    });
  }

  //......add ice from answerer
  iceByOffer()async{
      await FirebaseFirestore.instance.collection('offerice').get().then((value) {
      value.docs.forEach((element) {
        RTCIceCandidate x = RTCIceCandidate(
            element['candidate'], element['sdpMid'], element['sdpMlineIndex']);
        pc?.addCandidate(x);
        FirebaseFirestore.instance.collection('offerice').doc(element.id).delete();
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:connectionStatex?
       Center(
         child: SizedBox(
          height: MediaQuery.of(context).size.height*86/100,
          width: MediaQuery.of(context).size.width*86/100,
          child: RTCVideoView(_remoteRenderer)),
       )
      :Padding(
        padding: const EdgeInsets.only(top: 72.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
               SizedBox(
                  width: MediaQuery.of(context).size.width * 48 / 100,
                  height: MediaQuery.of(context).size.height * 48 / 100,
                  child: Stack(
                    children: [
                      RTCVideoView(_localRenderer),
                     const Center(child: Text('system audio'),)
                    ],
                  ),
                ),
                const SizedBox(
                  height: 72,
                ),
                ElevatedButton(
                    onPressed: () async {
                      _createOffer();
                    },
                    child: const Text('Offer')),
                const SizedBox(
                  height: 8,
                ),
                ElevatedButton(
                    onPressed: () {
                      setAnswer();
                    },
                    child: const Text('set answr')),
                const SizedBox(
                  height: 8,
                ),
                ElevatedButton(
                    onPressed: () async {
                      iceByAnswer();
                    },
                    child: const Text('add sdp')),
              ],
            ),
            Column(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 48 / 100,
                  height: MediaQuery.of(context).size.height * 48 / 100,
                  child: Stack(
                    children: [
                      RTCVideoView(_remoteRenderer),
                      Center(child: Text(connectionState),)
                    ],
                  ),
                ),
                const SizedBox(
                  height: 72,
                ),
                ElevatedButton(
                    onPressed: () {
                      _createAnswer();
                    },
                    child: const Text('answer')),
                const SizedBox(
                  height: 48,
                ),
                ElevatedButton(
                    onPressed: () async {
                      iceByOffer();
                    },
                    child: const Text('Add Ice')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
