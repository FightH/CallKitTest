//
//  AppDelegate.swift
//  CallKitTest
//
//  Created by Developer H on 2020/11/2.
//

import UIKit
import PushKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
        
        return true
    }
    
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        
        if pushCredentials.token.count > 0 {
            let token = NSString(format: "%@", pushCredentials.token as CVarArg) as String
            print("pushRegistry credentialsToken \(token)")
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        guard type == .voIP else {
            print("Not VoIP")
            return
        }
        //别忘了在这里加上你们自己接电话的逻辑，比如连接聊天服务器啥的，不然这个电话打不通的
        print("VoIP\(payload.dictionaryPayload)")
        if let uuidString = payload.dictionaryPayload["UUID"] as? String,
        let handle = payload.dictionaryPayload["handle"] as? String,
        let hasVideo = payload.dictionaryPayload["hasVideo"] as? Bool,
        let uuid = UUID(uuidString: uuidString){
            if #available(iOS 10.0, *) {
                ProviderDelegate.shared.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo, completion: { (error) in
                    if let e = error {
                        print("Error \(e)")
                    }
                })
            } else {
                // Fallback on earlier versions
            }
        }
        
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        if #available(iOS 10.0, *) {
            guard userActivity.startCallHandle != nil else {
                print("Could not determine start call handle from user activity: \(userActivity)")
                return false
            }
            
            guard userActivity.video != nil else {
                print("Could not determine video from user activity: \(userActivity)")
                return false
            }
            //如果当前有电话，需要根据自己App的业务逻辑判断
            
            
            //如果没有电话，就打电话，调用自己的打电话方法。
            
            return true
        }
        return false
        
        
    }
    
}

