

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    @IBOutlet weak var RecordingButton: UIButton!
    var startCalled = false
    var session:AVCaptureSession!
    var cameraAccess: Bool!
    var captureDevice : AVCaptureDevice?
    var captureLayer : AVCaptureVideoPreviewLayer!
    var avWriter1: AVAssetWriter?
    var avWriter2: AVAssetWriter?
    var avAudioInput1: AVAssetWriterInput?
    var avVideoInput1: AVAssetWriterInput?
    var avAudioInput2: AVAssetWriterInput?
    var avVideoInput2: AVAssetWriterInput?
    
    var avActiveWriter: AVAssetWriter?
    var avActiveAudioInput: AVAssetWriterInput?
    var avActiveVideoInput: AVAssetWriterInput?
    
    var outputURL1 : URL?
    var outputURL2 : URL?
    var isVideoFramesWritten: Bool?
    var fileName: String?
    var iCount: Int?
    
    var currentTime: Int64?
    
    var timer: Timer!
    var video_queue : DispatchQueue!
    var startTime: CMTime!
    var lastTime: CMTime!
    
    var bufferArray = [CMSampleBuffer]()
    var hasWritingStarted: Bool!
    
    
//    // Custom Settings ------- You can edit them
//    let videoHeight = 1080
//    let videoWidth  = 1920
//
//    let bitratex1024:Float = 4096
//    let segmentDuration: Double = 5
//
//    let capturePreset: AVCaptureSession.Preset = AVCaptureSession.Preset.high

    
    
    
    var folderName = ""
    
    // Video Settings
    var videoOutputSettings = Dictionary<String, Any>()
    
    // Audio setting
    let audioOutputSettings: Dictionary<String, AnyObject> = [
        AVFormatIDKey : Int(kAudioFormatMPEG4AAC) as AnyObject,
        AVNumberOfChannelsKey : 2 as AnyObject,
        AVSampleRateKey : 44100 as AnyObject
    ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraAccess = false
        captureDevice = nil
        isVideoFramesWritten = false
        currentTime = 0
        iCount = 0
        initializeSession()
        hasWritingStarted = false
        video_queue = DispatchQueue(label: "com.Interval.video_queue")
        
        
//        do {
//            let content = try FileManager.default.contentsOfDirectory(atPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
//            for file in content {
//                // Create writer
//                let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
//                let url1 = documentsPath.appendingPathComponent(file)
//
//                try FileManager.default.removeItem(at: url1!)
//            }
//        } catch {
//            print(error)
//        }
    }
    
    
    
    @objc func runTimedCode() {
        // Check if segmentDuration second has elapsed or not
        
        // Time to switch 
        // print("Time to switch")
        if (avActiveWriter == avWriter1) {
            // print("Current recorder 1 ")
            
            avActiveWriter = avWriter2
            avActiveAudioInput = avAudioInput2
            avActiveVideoInput = avVideoInput2
            
            DispatchQueue(label: "com.Interval.video_queue2").asyncAfter(deadline: .now(), execute: {
                // do some task
                self.avAudioInput1?.markAsFinished()
                self.avVideoInput1?.markAsFinished()
                print(self.lastTime)
                self.avWriter1?.endSession(atSourceTime: self.lastTime)
                // Finish writing for first one
                self.video_queue.async {
                    // print("finishWriting began at ", self.getCurrentMillis())
                    
                    self.avWriter1?.finishWriting(completionHandler: {
                        if self.avWriter1?.status == AVAssetWriterStatus.failed {
                            // Handle error here
                            print( "Error : ", self.avWriter1?.error.debugDescription as Any)
                            return;
                        }
                        
                    })
                    // print("finishWriting ended at ", self.getCurrentMillis())
                    
                    self.InitFirstWriter()
                    // print("time after 2 ", self.getCurrentMillis())
                }
            })
        } else {
            print("Current recorder 2 ")
            
            avActiveWriter = avWriter1
            avActiveAudioInput = avAudioInput1
            avActiveVideoInput = avVideoInput1
            
            DispatchQueue(label: "com.Interval.video_queue3").asyncAfter(deadline: .now() , execute: {
                // do some task
                self.avAudioInput2?.markAsFinished()
                self.avVideoInput2?.markAsFinished()
                self.avWriter2?.endSession(atSourceTime: self.startTime)
                // Finish writing for second one
                self.video_queue.async {
                    
                    // print("time before ", self.getCurrentMillis())
                    // print("finishWriting began at ", self.getCurrentMillis())
                    
                    self.avWriter2?.finishWriting(completionHandler: {
                        if self.avWriter2?.status == AVAssetWriterStatus.failed {
                            // Handle error here
                            print( "Error : ", self.avWriter2?.error.debugDescription as Any)
                            return;
                        }
                    })
                    // print("finishWriting ended at ", self.getCurrentMillis())
                    
                    self.InitSecondWriter()
                    
                    // print("time after 2 ", self.getCurrentMillis()
                }
            })
        }
    }
    
    @IBAction func OnRecordingButtonPress(_ sender: Any) {
        
        if (!self.cameraAccess) {
            print(" Camera access needed in order to use the app ")
            initializeSession()
            return
        }
        if (!startCalled) {
            startCamera();
        } else {
            stopCamera();
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if startCalled {
            stopCamera()
        }
        super.viewWillDisappear(animated)
    }
    
    func initializeSession() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video,
                                          completionHandler: { (granted:Bool) -> Void in
                                            if granted {
                                                
                                                self.cameraAccess = true
                                            } else {
                                                print(" Access denied, cannot use the app ")
                                            }
            })
            break
        case .authorized:
            cameraAccess = true
            break
        case .denied, .restricted:
            break
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission( { (granted: Bool) -> Void in
            
        });
    }
    

    
    
    
    func InitFirstWriter()
    {
        iCount = iCount! + 1;
        fileName = String(iCount!) + ".mp4"
        
        // Create writer
        let documentsPath = NSURL(fileURLWithPath: currentDirectory())
        outputURL1 = documentsPath.appendingPathComponent(fileName!)
        
        // Delete if it exists
        if FileManager.default.fileExists(atPath: outputURL1!.path) {
            do {
                try FileManager.default.removeItem(at: outputURL1!)
            } catch {
                print("File deletion error: \(error)")
            }
        }
        
        // Writer
        avWriter1 = try? AVAssetWriter(outputURL: outputURL1!, fileType: AVFileType.mp4)
        
        avAudioInput1 = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
        avAudioInput1?.expectsMediaDataInRealTime = true
        
        avVideoInput1 = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings:videoOutputSettings)
        avVideoInput1?.expectsMediaDataInRealTime = true
        
        avVideoInput1?.transform = CGAffineTransform(rotationAngle: CGFloat( Double.pi / 2))
        
        avWriter1?.add(avAudioInput1!)
        avWriter1?.add(avVideoInput1!)
        
        
    }
    func InitSecondWriter() {
        iCount = iCount! + 1;
        fileName = String(iCount!) + ".mp4"
        
        // Create writer
        let documentsPath = NSURL(fileURLWithPath: currentDirectory())
        outputURL2 = documentsPath.appendingPathComponent(fileName!)
        
        avWriter2 = try? AVAssetWriter(outputURL: outputURL2!, fileType: AVFileType.mp4)
        
        avAudioInput2 = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
        avAudioInput2?.expectsMediaDataInRealTime = true
        

        
        avVideoInput2 = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings:videoOutputSettings)
        avVideoInput2?.expectsMediaDataInRealTime = true
        avVideoInput2?.transform = CGAffineTransform(rotationAngle: CGFloat( Double.pi / 2))

        
        avWriter2?.add(avAudioInput2!)
        avWriter2?.add(avVideoInput2!)
    }
    
    func startCamera() {
        
        startCalled = true;
        RecordingButton.setTitle("Stop Recording", for: .normal )
        folderName = "\(Int(NSDate().timeIntervalSince1970))"
        FileManager.default.createDirectory(dirName: folderName)

        
        // get device properties
        let compressionProperties = [   // other ways to compress the same @ https://stackoverflow.com/questions/11296642/
            AVVideoAverageBitRateKey: NSNumber(value: (Settings.shared.getBitrate() * 1024)),
            ]
        
        videoOutputSettings = [
            AVVideoCodecKey : AVVideoCodecType.h264 as AnyObject, // AVVideoCodecType.h264,  // AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey : NSNumber(value: Settings.shared.getVideoWidth()),
            AVVideoHeightKey : NSNumber(value: Settings.shared.getVideoHeight()),
            AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
            AVVideoCompressionPropertiesKey : compressionProperties
        ]

        
        // Get the device
        if (captureDevice == nil) {
            captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back)
        }
        captureDevice?.configureDesiredFrameRate(Settings.shared.getFPS())
        
        InitFirstWriter()
        InitSecondWriter()
        
        avActiveWriter = avWriter1
        avActiveAudioInput = avAudioInput1
        avActiveVideoInput = avVideoInput1
        
        
        // Create capture session
        session = AVCaptureSession()
        session.sessionPreset  = Settings.shared.getAVPreset()
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            session.addInput(input)
            
            let ainput =  try AVCaptureDeviceInput(device:AVCaptureDevice.default(for: AVMediaType.audio)!)
            session.addInput(ainput)
            
            let videoOutput = AVCaptureVideoDataOutput()
            let videoserialQueue = DispatchQueue(label: "videoQueue")
            videoOutput.setSampleBufferDelegate(self, queue: videoserialQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            let connectionVideo = videoOutput.connection(with: AVMediaType.video)
            connectionVideo?.videoOrientation = AVCaptureVideoOrientation.portrait;
            if (session?.canAddOutput(videoOutput) != nil) {
                session?.addOutput(videoOutput)
            }
            
            captureLayer = AVCaptureVideoPreviewLayer(
                session: session)
            
            captureLayer!.frame = self.view.bounds
            captureLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            self.view.layer.insertSublayer(captureLayer!, at: 0)
            
        }
        catch{
            print(error)
            return
        }
        
        let audioDataOutput = AVCaptureAudioDataOutput()
        let serialQueue = DispatchQueue(label: "audioQueue")
        audioDataOutput.setSampleBufferDelegate(self, queue: serialQueue)
        
        if (session?.canAddOutput(audioDataOutput) != nil) {
            session?.addOutput(audioDataOutput)
            print(" Audio output added ")
        }
        session.startRunning()
        
        timer = Timer.scheduledTimer(timeInterval: Settings.shared.getSegmentDuration(), target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
        
        
    }
    
    
    
    func merge() {
        let composition = AVMutableComposition()
        
        let videoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let audioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var time:Double = 0.0
        
        for i in 1 ..< iCount! {
            fileName = String(i) + ".mp4"
            let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
            let outputURL = documentsPath.appendingPathComponent(fileName!)
            print("URL: " , fileName!)
            
            let asset = AVAsset(url: outputURL!)
            var videoAssetTrack: AVAssetTrack!
            videoAssetTrack = nil
            if (asset.tracks(withMediaType: AVMediaType.video).count > 0)
            {
                videoAssetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
            }
            var audioAssetTrack: AVAssetTrack!
            audioAssetTrack = nil;
            if (asset.tracks(withMediaType: AVMediaType.audio).count > 0) {
                audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio)[0]
            }
            
            let timeScale = asset.duration.timescale
            
            let atTime = CMTime(seconds: time, preferredTimescale: timeScale)
            
            
            do {
                if (videoAssetTrack != nil) {
                    try videoTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), of: videoAssetTrack, at: atTime)
                }
                
                if (audioAssetTrack != nil) {
                    try audioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), of: audioAssetTrack, at: atTime)
                }
            }
                
            catch {
                print("Error : \(error)")
            }
            
            
            time += asset.duration.seconds
        }
        
        
        let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        
        let path = documentsPath.appendingPathComponent("finalVideo.mp4")
        
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = path
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.outputFileType = AVFileType.mp4
        
        exporter?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                print("export finished")
                
                UISaveVideoAtPathToSavedPhotosAlbum ((exporter?.outputURL?.path)!, self, nil, nil);
                
            }
        })
    }
    
    func stopCamera() {
        startCalled = false;
        RecordingButton.setTitle("Start Recording", for: .normal );
        
        timer.invalidate()
        if (session.isRunning) {
            session.stopRunning()
        }
        captureLayer!.removeFromSuperlayer()
        
        avActiveAudioInput?.markAsFinished()
        avActiveVideoInput?.markAsFinished()
        avActiveWriter?.finishWriting(completionHandler: {
            if self.avActiveWriter?.status == AVAssetWriterStatus.failed {
                // Handle error here
                print( "Error : ", self.avActiveWriter?.error.debugDescription as Any)
                return
            }
            
            // UISaveVideoAtPathToSavedPhotosAlbum ((self.outputURL?.path)!, self, nil, nil);
            //  self.merge();
            
        })
        
    }
    
//    func getCurrentMillis()->Int64 {
//        return Int64(Date().timeIntervalSince1970 * 1000)
//    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        //        if (avWriter1?.status != nil) {
        //            print("Status of writer1 ", avWriter1?.status.rawValue as Any)
        //        }
        //        else {
        //            print("Status of writer1 nil")
        //        }
        //
        //        if (avWriter2?.status != nil) {
        //            print("Status of writer2 ", avWriter2?.status.rawValue as Any)
        //        } else {
        //            print("Status of writer2 nil")
        //        }
        
        
        
        if CMSampleBufferDataIsReady(sampleBuffer) == false {
            // Handle error
            print("Data is not ready")
            return;
        }
        
        
        
        if let _ = captureOutput as? AVCaptureVideoDataOutput {
            
            startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            
            if avActiveWriter?.status == AVAssetWriterStatus.unknown {
                if (bufferArray.count > 0) {
                    startTime = CMSampleBufferGetPresentationTimeStamp(bufferArray[0])
//                    print("1::  PTS", startTime)
                }
                print(" Start writing and start session ")
                avActiveWriter?.startWriting()
                avActiveWriter?.startSession(atSourceTime: startTime)
//                print("2::  PTS", startTime)
//
//                print("1:: Startsession called at PTS", startTime)
                hasWritingStarted = true
                isVideoFramesWritten = false
                
            }
        }
        
        if avActiveWriter?.status != AVAssetWriterStatus.writing {
            // print("Status not wrting ", avActiveWriter?.status as Any)
            if (hasWritingStarted == false) {
                return
            }
            
            var bufferCopy : CMSampleBuffer?
            CMSampleBufferCreateCopy(kCFAllocatorDefault, sampleBuffer, &bufferCopy);
            bufferArray.append(bufferCopy!);
            return;
        }
        if avActiveWriter?.status == AVAssetWriterStatus.failed {
            // Handle error here
            print( "Error AVAssetWriterStatus.failed : ", avActiveWriter?.error.debugDescription as Any)
            return;
        }
        
        
        if let _ = captureOutput as? AVCaptureVideoDataOutput {
            
            
            if (avActiveVideoInput?.isReadyForMoreMediaData == true){
                
                // Check if we had pending buffer
                if (bufferArray.count > 0)
                {
                    for buffer in bufferArray
                    {
                        let format = CMSampleBufferGetFormatDescription(buffer);
                        let type = CMFormatDescriptionGetMediaType(format!);
                        if (type == kCMMediaType_Video)
                        {
                            avActiveVideoInput?.append(buffer);
                            lastTime = CMSampleBufferGetPresentationTimeStamp(buffer)
                            // print("1: Writng video frames at ", lastTime)
                            
                            isVideoFramesWritten = true
                        }
                        else if (isVideoFramesWritten == true)
                        {
                            // print("Status not wrting ", avActiveWriter?.status as Any)
                            
                            // print("1: Writing audio frames ")
                            
                            avActiveAudioInput?.append(buffer);
                        }
                        
                    }
                    bufferArray.removeAll()
                }
                avActiveVideoInput?.append(sampleBuffer)
                lastTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                
                // print("2: Writng video frames at ", lastTime)
                
                isVideoFramesWritten = true
            } else {
                print("Skipping frames ")
                
            }
        }
        if let _ = captureOutput as? AVCaptureAudioDataOutput {
            if avActiveAudioInput?.isReadyForMoreMediaData == true && isVideoFramesWritten == true{
                // Check if we had pending buffer
                if (bufferArray.count > 0) {
                    for  buffer in bufferArray {
                        let format = CMSampleBufferGetFormatDescription(buffer);
                        let type = CMFormatDescriptionGetMediaType(format!);
                        if (type == kCMMediaType_Video) {
                            avActiveVideoInput?.append(buffer);
                            print("3: Writng video frames at ", lastTime)
                        } else {
                            avActiveAudioInput?.append(buffer);
                        }
                    }
                    bufferArray.removeAll()
                }
                avActiveAudioInput?.append(sampleBuffer)
            }
            
        }
        
    }
    
    private func currentDirectory() -> String {
        return "\(FileManager.documentsDir())/\(folderName)/"
    }
    
}

extension AVCaptureDevice {
    
    /// http://stackoverflow.com/questions/21612191/set-a-custom-avframeraterange-for-an-avcapturesession#27566730
    func configureDesiredFrameRate(_ desiredFrameRate: Int) {
        
        var isFPSSupported = false
        
        do {
            
            if let videoSupportedFrameRateRanges = activeFormat.videoSupportedFrameRateRanges as? [AVFrameRateRange] {
                for range in videoSupportedFrameRateRanges {
                    if (range.maxFrameRate >= Double(desiredFrameRate) && range.minFrameRate <= Double(desiredFrameRate)) {
                        isFPSSupported = true
                        break
                    }
                }
            }
            
            if isFPSSupported {
                try lockForConfiguration()
                activeVideoMaxFrameDuration = CMTimeMake(1, Int32(desiredFrameRate))
                activeVideoMinFrameDuration = CMTimeMake(1, Int32(desiredFrameRate))
                unlockForConfiguration()
            } else {
                print("FPS NOT SUPPORTED -  \(desiredFrameRate)")
            }
        } catch {
            print("lockForConfiguration error: \(error.localizedDescription)")
        }
    }
    
}


