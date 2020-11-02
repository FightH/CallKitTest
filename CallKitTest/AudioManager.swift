//
//  AudioManager.swift
//  CallKitTest
//
//  Created by Developer H on 2020/11/2.
//

import Foundation
import AVFoundation

func configureAudioSession() {
    print("Callkit& Configuring audio session")
    let session = AVAudioSession.sharedInstance()
    do {
        try session.setCategory(AVAudioSession.Category.playAndRecord)
        try session.setMode(AVAudioSession.Mode.voiceChat)
    } catch (let error) {
        print("Callkit& Error while configuring audio session: \(error)")
    }
}

func startAudio() {
    print("Callkit& Starting audio")
    //开始播放铃声
}

func stopAudio() {
    print("Callkit& Stopping audio")
    //停止播放铃声
}
