//
//  CallKitTestTests.swift
//  CallKitTestTests
//
//  Created by Developer H on 2020/11/2.
//

import XCTest
@testable import CallKitTest

class CallKitTestTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        //拨打电话
        if #available(iOS 10.0, *) {
            CallKitManager.shared.startCall(handle:"PhoneNumber value", videoEnabled: false)
        } else {
              //原来打电话的逻辑
        }
        
        
        //挂断电话
        if #available(iOS 10.0, *) {
            if let call = CallKitManager.shared.calls.first {
                CallKitManager.shared.end(call: call)
            }
        } else {
            
        }
        
        // 暂时挂起
        if #available(iOS 10.0, *) {
            if let call = CallKitManager.shared.calls.first {
                   CallKitManager.shared.setHeld(call: call, onHold: true)
            }
        } else {
            
            
        }
        
        // 麦克风静音
        if #available(iOS 10.0, *) {
            if let call = CallKitManager.shared.calls.first {
                   CallKitManager.shared.setMute(call: call, muted: true)
            }
        } else {
            
        }
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
