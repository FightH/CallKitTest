//
//  CallKitManager.swift
//  CallKitTest
//
//  Created by Developer H on 2020/11/2.
//
import Foundation
import CallKit

@available(iOS 10.0, *)
class CallKitManager {
    
    static let shared = CallKitManager()
  
    var callsChangedHandler: (() -> Void)?

    private let callController = CXCallController()
    private(set) var calls = [Call]()
    
    private init(){}

    func callWithUUID(uuid: UUID) -> Call? {
        guard let index = calls.firstIndex(where: { $0.uuid == uuid }) else {
          return nil
        }
        return calls[index]
    }

    func startCall(handle: String, videoEnabled: Bool) {
        //一个 CXHandle 对象表示了一次操作，同时指定了操作的类型和值。App支持对电话号码进行操作，因此我们在操作中指定了电话号码。
        let handle = CXHandle(type: .phoneNumber, value: handle)
        //一个 CXStartCallAction 用一个 UUID 和一个操作作为输入。
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        //你可以通过 action 的 isVideo 属性指定通话是音频还是视频。
        startCallAction.isVideo = videoEnabled
        let transaction = CXTransaction(action: startCallAction)
        requestTransaction(transaction)
    }

    // 挂断电话
    func end(call: Call) {
        //先创建一个 CXEndCallAction。将通话的 UUID 传递给构造函数，以便在后面可以识别通话。
        let endCallAction = CXEndCallAction(call: call.uuid)
        //然后将 action 封装成 CXTransaction，以便发送给系统。
        let transaction = CXTransaction(action: endCallAction)
        requestTransaction(transaction)
    }
    
    // 通话暂时挂起
    func setHeld(call: Call, onHold: Bool) {
        //这个 CXSetHeldCallAction 包含了通话的 UUID 以及保持状态
        let setHeldCallAction = CXSetHeldCallAction(call: call.uuid, onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)
        
        requestTransaction(transaction)
    }
    
    // 麦克风静音
    func setMute(call: Call, muted: Bool) {
        //CXSetMutedCallAction设置麦克风静音
        let setMuteCallAction = CXSetMutedCallAction(call: call.uuid, muted: muted)
        let transaction = CXTransaction()
        transaction.addAction(setMuteCallAction)
        requestTransaction(transaction)
    }
    
    //调用 callController 的 request(_:completion:) 。系统会请求 CXProvider 执行这个 CXTransaction，这会导致你实现的委托方法被调用。
    private func requestTransaction(_ transaction: CXTransaction) {
        callController.request(transaction) { error in
            if let error = error {
                print("Error: \(error)")
            } else {
                print("successfully")
            }
        }
    }
    
    
    func add(call: Call) {
        calls.append(call)
        call.stateChanged = { [weak self] in
          guard let strongSelf = self else { return }
          strongSelf.callsChangedHandler?()
        }
        callsChangedHandler?()
    }

    func remove(call: Call) {
        guard let index = calls.firstIndex(where: { $0 === call }) else { return }
        calls.remove(at: index)
        callsChangedHandler?()
    }

    func removeAllCalls() {
        calls.removeAll()
        callsChangedHandler?()
    }
    
    
}
