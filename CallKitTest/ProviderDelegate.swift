//
//  ProviderDelegate.swift
//  CallKitTest
//
//  Created by Developer H on 2020/11/2.
//

import Foundation
import CallKit
import AVFoundation

@available(iOS 10.0, *)
class ProviderDelegate: NSObject, CXProviderDelegate {
    static let shared = ProviderDelegate()
    //ProviderDelegate 需要和 CXProvider 和 CXCallController 打交道，因此保持两个对二者的引用。
    private let callManager: CallKitManager //还记得他里面有个callController嘛。。
    private let provider: CXProvider
    
    override init() {
        self.callManager = CallKitManager.shared
        //用一个 CXProviderConfiguration 初始化 CXProvider，前者在后面会定义成一个静态属性。CXProviderConfiguration 用于定义通话的行为和能力。
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        //为了能够响应来自于 CXProvider 的事件，你需要设置它的委托。
        provider.setDelegate(self, queue: nil)
    }
    
    //通过设置CXProviderConfiguration来支持视频通话、电话号码处理，并将通话群组的数字限制为 1 个，其实光看属性名大家也能看得懂吧。
    static var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "Mata Chat")//这里填你App的名字哦。。
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.supportedHandleTypes = [.phoneNumber]
        return providerConfiguration
    }
    
    //这个方法牛逼了，它是用来更新系统电话属性的。。
    func callUpdate(handle: String, hasVideo: Bool) -> CXCallUpdate {
        let update = CXCallUpdate()
        update.localizedCallerName = "ParadiseDuo"//这里是系统通话记录里显示的联系人名称哦。需要显示什么按照你们的业务逻辑来。
        update.supportsGrouping = false
        update.supportsHolding = false
        update.remoteHandle = CXHandle(type: .phoneNumber, value: handle) //填了联系人的名字，怎么能不填他的handle('电话号码')呢，具体填什么，根据你们的业务逻辑来
        update.hasVideo = hasVideo
        return update
    }

    //CXProviderDelegate 唯一一个必须实现的代理方法！！当 CXProvider 被 reset 时，这个方法被调用，这样你的 App 就可以清空所有去电，会到干净的状态。在这个方法中，你会停止所有的呼出音频会话，然后抛弃所有激活的通话。
    func providerDidReset(_ provider: CXProvider) {
        stopAudio()
        for call in callManager.calls {
            call.end()
        }
        callManager.removeAllCalls()
        //这里添加你们挂断电话或抛弃所有激活的通话的代码。。
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        //向系统通讯录更新通话记录
        let update = self.callUpdate(handle: action.handle.value, hasVideo: action.isVideo)
        provider.reportCall(with: action.callUUID, updated: update)
        
        let call = Call(uuid: action.callUUID, outgoing: true, handle: action.handle.value)
        //当我们用 UUID 创建出 Call 对象之后，我们就应该去配置 App 的音频会话。和呼入通话一样，你的唯一任务就是配置。真正的处理在后面进行，也就是在 provider(_:didActivate) 委托方法被调用时
        configureAudioSession()
        //delegate 会监听通话的生命周期。它首先会会报告的就是呼出通话开始连接。当通话最终连上时，delegate 也会被通知。
        call.connectedStateChanged = { [weak self] in
            guard let w = self else {
                return
            }
            if call.connectedState == .pending {
                w.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
            } else if call.connectedState == .complete {
                w.provider.reportOutgoingCall(with: call.uuid, connectedAt: nil)
            }
        }
        //调用 call.start() 方法会导致 call 的生命周期变化。如果连接成功，则标记 action 为 fullfill。
        call.start { [weak self] (success) in
            guard let w = self else {
                return
            }
            if success {
               //这里填写你们App内打电话的逻辑。。
  
                w.callManager.add(call: call)
                //所有的Action只有调用了fulfill()之后才算执行完毕。
                action.fulfill()
            } else {
                action.fail()
            }
        }
    }

    //当系统激活 CXProvider 的 audio session时，委托会被调用。这里开始处理通话的音频。
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        startAudio() //一定要记得播放铃声
    }
    
    //需要在所有接电话的地方手动调用，需要根据自己的业务逻辑来判断。还有就是不要忘了iOS的版本兼容哦。。
    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((Error?) -> Void)?) {
        
        //准备向系统报告一个 call update 事件，它包含了所有的来电相关的元数据。
        let update = self.callUpdate(handle: handle, hasVideo: hasVideo)
        //调用 CXProvider 的reportIcomingCall(with:update:completion:)方法通知系统有来电。
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                //completion 回调会在系统处理来电时调用。如果没有任何错误，你就创建一个 Call 实例，将它添加到 CallManager 的通话列表。
                let call = Call(uuid: uuid, handle: handle)
                self.callManager.add(call: call)
            }
            //调用 completion，如果它不为空的话。
            completion?(error)
        }
     }
    
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        //从 callManager 中获得一个引用，UUID 指定为要接听的动画的 UUID。
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        //设置通话要用的 audio session 是 App 的责任。系统会以一个较高的优先级来激活这个 session。
        configureAudioSession()
        //通过调用 answer，你会表明这个通话现在激活
        call.answer()
        //在这里添加自己App接电话的逻辑

        //在处理一个 CXAction 时，重要的一点是，要么你拒绝它（fail），要么满足它（fullfill)。如果处理过程中没有发生错误，你可以调用 fullfill() 表示成功。
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        //从 callManager 获得一个 call 对象。
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        //当 call 即将结束时，停止这次通话的音频处理。
        stopAudio()
        //调用 end() 方法修改本次通话的状态，以允许其他类和新的状态交互。
        call.end()
       //在这里添加自己App挂断电话的逻辑
        //将 action 标记为 fulfill。
        action.fulfill()
        //当你不再需要这个通话时，可以让 callManager 回收它。
        callManager.remove(call: call)
     }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        //获得 CXCall 对象之后，我们要根据 action 的 isOnHold 属性来设置它的 state。
        call.state = action.isOnHold ? .held:.active
        //根据状态的不同，分别进行启动或停止音频会话。
        if call.state == .held {
            stopAudio()
        } else {
            startAudio()
        }
        //在这里添加你们自己的通话挂起逻辑
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        //获得 CXCall 对象之后，我们要根据 action 的 ismuted 属性来设置它的 state。
        call.state = action.isMuted ? .muted : .active
        //在这里添加你们自己的麦克风静音逻辑
        
        
        action.fulfill()
    }
}


