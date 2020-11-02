//
//  NSUserActivity+Extension.swift
//  CallKitTest
//
//  Created by Developer H on 2020/11/2.
//
import Foundation
import Intents

protocol StartCallConvertible {
    var startCallHandle: String? { get }
    var video: Bool? { get }
}

extension StartCallConvertible {
    var video: Bool? {
        return nil
    }
}

@available(iOS 10.0, *)
protocol SupportedStartCallIntent {
    var contacts: [INPerson]? { get }
}

@available(iOS 10.0, *)
extension INStartAudioCallIntent: SupportedStartCallIntent {}
@available(iOS 10.0, *)
extension INStartVideoCallIntent: SupportedStartCallIntent {}

extension NSUserActivity: StartCallConvertible {
    
    var startCallHandle: String? {
        if #available(iOS 10.0, *) {
            guard
                let interaction = interaction,
                let startCallIntent = interaction.intent as? SupportedStartCallIntent,
                let contact = startCallIntent.contacts?.first
                else {
                    return nil
            }
            return contact.personHandle?.value
        }
        
        return nil
    }
    
    var video: Bool? {
        if #available(iOS 10.0, *) {
            guard
                let interaction = interaction,
                let startCallIntent = interaction.intent as? SupportedStartCallIntent
                else {
                    return nil
            }
            
            return startCallIntent is INStartVideoCallIntent
        }
        return nil
    }
}
