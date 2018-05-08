//
//  SettingsViewController.swift
//  LiveVideoSplitter2
//
//  Created by rahulg on 06/05/18.
//  Copyright © 2018 rahulg. All rights reserved.
//

import UIKit
import AVFoundation

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var segmentDurationLabel: UILabel!
    @IBOutlet weak var segmentDurationSlider: UISlider!
    
    @IBOutlet weak var fpsLabel: UILabel!
    @IBOutlet weak var fpsSlider: UISlider!
    
    @IBOutlet weak var bitrateLabel: UILabel!
    @IBOutlet weak var bitrateSlider: UISlider!
    
    @IBOutlet weak var videoWidthLabel: UILabel!
    @IBOutlet weak var videoWidthSlider: UISlider!
    
    @IBOutlet weak var videoHeightLabel: UILabel!
    @IBOutlet weak var videoHeightSlider: UISlider!
    
    @IBOutlet weak var presetPickerView: UIPickerView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sdVal = Settings.shared.getSegmentDuration()
        segmentDurationLabel.text = "\(sdVal)"
        segmentDurationSlider.value = Float(sdVal)
        
        let fpsVal = Settings.shared.getFPS()
        fpsLabel.text = "\(fpsVal)"
        fpsSlider.value = Float(fpsVal)
        // AVCaptureDevice.default(for: AVMediaType.video)?.activeFormat.videoSupportedFrameRateRanges[0].minFrameRate
        // the above can give the minimum and max framerate that is device and camera specific
        
        let bitrateVal = Settings.shared.getBitrate()
        bitrateLabel.text = "\(bitrateVal)"
        bitrateSlider.value = Float(bitrateVal)
        
        let videoWidthVal = Settings.shared.getVideoWidth()
        videoWidthLabel.text = "\(videoWidthVal)"
        videoWidthSlider.value = Float(videoWidthVal)

        let videoHeightVal = Settings.shared.getVideoHeight()
        videoHeightLabel.text = "\(videoHeightVal)"
        videoHeightSlider.value = Float(videoHeightVal)
        
        let avCapturePreset = Settings.shared.getAVPreset()
        typealias AVP = AVCaptureSession.Preset
        var presetNum = 1
        switch avCapturePreset {
        case AVP.low:
            presetNum = 0
        case AVP.medium:
            presetNum = 1
        case AVP.high:
            presetNum = 2
        default:
            presetNum = 2
        }
        presetPickerView.selectRow(presetNum, inComponent: 0, animated: true)

    }
    
    @IBAction func segmentDurationSliderUpdated(_ sender: Any) {
        let sdVal = segmentDurationSlider.value
        segmentDurationLabel.text = "\(sdVal)"
        Settings.shared.setSegmentDuration(Double(sdVal))
    }
    
    @IBAction func fpsSliderUpdated(_ sender: Any) {
        let fpsVal = Int(fpsSlider.value)
        fpsLabel.text = "\(fpsVal)"
        Settings.shared.setFPS(fpsVal)
    }
    
    @IBAction func bitrateSliderUpdated(_ sender: Any) {
        let val = Int(bitrateSlider.value)
        bitrateLabel.text = "\(val)"
        Settings.shared.setBitrate(val)
    }
    
    @IBAction func videoWidthSliderUpdated(_ sender: Any) {
        let val = Int(videoWidthSlider.value)
        videoWidthLabel.text = "\(val)"
        Settings.shared.setVideoWidth(val)
    }
    
    @IBAction func videoHeightSliderUpdatded(_ sender: Any) {
        let val = Int(videoHeightSlider.value)
        videoHeightLabel.text = "\(val)"
        Settings.shared.setVideoHeight(val)
    }
    
    var presetArray = [AVCaptureSession.Preset.low, AVCaptureSession.Preset.medium, AVCaptureSession.Preset.high]

}

extension SettingsViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return presetArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return presetArray[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var presetToSave: AVCaptureSession.Preset?
        switch row {
        case 0:
            presetToSave = AVCaptureSession.Preset.low
        case 1:
            presetToSave = AVCaptureSession.Preset.medium
        case 2:
            presetToSave = AVCaptureSession.Preset.high
        default:
            presetToSave = AVCaptureSession.Preset.medium
        }
        Settings.shared.setAVPreset(presetToSave!)
        
    }
    
}

class Settings {
    static let shared = Settings()
    let defaults = UserDefaults.standard

    private let kSegmentDurationKey = "kSegmentDurationKey"
    private let kFPSKey = "kFPSKey"
    private let kBitrateKey = "kBitrateKey"
    private let kVideoWidthKey = "kVideoWidthKey"
    private let kVideoHeightKey = "kVideoHeightKey"
    private let kAVCaptureSessionPresetKey = "kAVCaptureSessionPresetKey"

    
    private init() {
    }
    func getSegmentDuration() -> Double {
        let retVal = defaults.double(forKey: kSegmentDurationKey)
        return (retVal == 0) ? 5 : retVal // default 5
    }
    func setSegmentDuration(_ value: Double) {
        defaults.set(value, forKey: kSegmentDurationKey)
    }
    
    func getFPS() -> Int {
        let retVal = defaults.integer(forKey: kFPSKey)
        return (retVal == 0) ? 30 : retVal // default 30
    }
    func setFPS(_ value: Int) {
        defaults.set(value, forKey: kFPSKey)
    }
    
    func getBitrate() -> Int {
        let retVal = defaults.integer(forKey: kBitrateKey)
        return (retVal == 0) ? 4096 : retVal
    }
    func setBitrate(_ value: Int) {
        defaults.set(value, forKey: kBitrateKey)
    }
    
    func getVideoWidth() -> Int {
        let retVal = defaults.integer(forKey: kVideoWidthKey)
        return (retVal == 0) ? 1920 : retVal
    }
    func setVideoWidth(_ value: Int) {
        defaults.set(value, forKey: kVideoWidthKey)
    }
    
    func getVideoHeight() -> Int {
        let retVal = defaults.integer(forKey: kVideoHeightKey)
        return (retVal == 0) ? 1080 : retVal
    }
    func setVideoHeight(_ value: Int) {
        defaults.set(value, forKey: kVideoHeightKey)
    }
    
    func getAVPreset() -> AVCaptureSession.Preset {
        let retVal: AVCaptureSession.Preset? = defaults.object(forKey: kAVCaptureSessionPresetKey) as? AVCaptureSession.Preset
        return (retVal == nil) ? AVCaptureSession.Preset.high : retVal!
    }
    func setAVPreset(_ value: AVCaptureSession.Preset) {
        defaults.set(value, forKey: kAVCaptureSessionPresetKey)
    }


//    // Custom Settings ------- You can edit them
//    let videoHeight = 1080
//    let videoWidth  = 1920
//
//    let bitratex1024:Float = 4096
//    let segmentDuration: Double = 5
//
//    let capturePreset: AVCaptureSession.Preset = AVCaptureSession.Preset.high

    
    

//    func getValue<T:Numeric>(key: String, defaultVal: T) -> T {
//        let retVal: T = defaults.object(forKey: key) as! T
//        return (retVal == 0) ? defaultVal : retVal
//    }
//    func setValue<T:Numeric>(_ value: T, key: String) {
//        defaults.set(value, forKey: key)
//    }
    
    
}

