//
//  CKOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 7/07/2016.
//
//

import Foundation
import Dispatch

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class CKOperation: Operation, @unchecked Sendable {
    public var container: CKContainer?
    public var requestUUIDs: [String] = []

    private var _finished: Bool = false
    private var _executing: Bool = false

    var task: Task<Void, Error>?
    private var operationID: String

    override init() {
        if type(of: self) == CKOperation.self {
            fatalError("You must use a concrete subclass of CKOperation")
        }
        
        operationID = UUID().uuidString
        super.init()
    }

    // using dispatch queue rather than operation queue because don't need cancellation for the callbacks.
    lazy var callbackQueue: DispatchQueue = {
        return DispatchQueue(label: "opencloudkit.operation-\(self.operationID).callback")
    }()
    
    var operationContainer: CKContainer {
        return container ?? CKContainer.default()
    }

    open override func start() {
        // Send out KVO notifications for the executing
        isExecuting = true

        if isCancelled {
            self.callbackQueue.async {
                self.finishOnCallbackQueue()
            }
            return
        }

        self.callbackQueue.async {
            self.main()
        }
    }

    open override func main() {
        guard !isCancelled else { return }
        performCKOperation()
    }
    
    open override func cancel() {
        // Calling Super will update the isCancelled and send KVO notifications
        super.cancel()
        task?.cancel()
    }

    func finishOnCallbackQueue() {
        isExecuting = false
        isFinished = true
        task = nil
    }

    func performCKOperation() {
        fatalError("performCKOperation should be override by \(self)")
    }

    override public var isFinished : Bool {
        get { return _finished }
        set {
            guard _finished != newValue else { return }
            // Linux doesn't support KVO
            #if canImport(FoundationNetworking)
            _finished = newValue
            #else
            willChangeValue(forKey: "isFinished")
            _finished = newValue
            didChangeValue(forKey: "isFinished")
            #endif
        }
    }

    override public var isExecuting : Bool {
        get { return _executing }
        set {
            guard _executing != newValue else { return }

            // Linux doesn't support KVO
            #if canImport(FoundationNetworking)
            _executing = newValue
            #else
            willChangeValue(forKey: "isExecuting")
            _executing = newValue
            didChangeValue(forKey: "isExecuting")
            #endif
        }
    }

    override public var isAsynchronous: Bool {
        get { return true }
    }
}

public class CKDatabaseOperation : CKOperation {
    public var database: CKDatabase?
}
