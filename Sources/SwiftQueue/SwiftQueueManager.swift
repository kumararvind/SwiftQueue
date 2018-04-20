//
// Created by Lucas Nelaupe on 18/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import Foundation

/// Global manager to perform operations on all your queues/
/// You will have to keep this instance. We highly recommend you to store this instance in a Singleton
/// Creating and instance of this class will automatically un-serialise your jobs and schedule them
public final class SwiftQueueManager {

    private let creator: JobCreator
    private let persister: JobPersister
    private let serializer: JobInfoSerialiser

    internal let logger: SwiftQueueLogger

    private var manage = [String: SqOperationQueue]()

    private var isPaused = true

    /// Create a new QueueManager with creators to instantiate Job
    /// Synchronous indicate that serialized task will be added synchronously.
    /// This can be a time consuming operation.
    public init(creator: JobCreator,
                persister: JobPersister = UserDefaultsPersister(), serializer: JobInfoSerialiser = DecodableSerializer(),
                synchronous: Bool = true, logger: SwiftQueueLogger = NoLogger.shared) {

        self.creator = creator
        self.persister = persister
        self.serializer = serializer
        self.logger = logger

        for queueName in persister.restore() {
            manage[queueName] = SqOperationQueue(queueName, creator, persister, serializer, isPaused, synchronous, logger)
        }

        start()
    }

    /// Jobs queued will run again
    public func start() {
        isPaused = false
        for element in manage.values {
            element.isSuspended = false
        }
    }

    /// Avoid new job to run. Not application for current running job.
    public func pause() {
        isPaused = true
        for element in manage.values {
            element.isSuspended = true
        }
    }

    internal func getQueue(queueName: String) -> SqOperationQueue {
        return manage[queueName] ?? createQueue(queueName: queueName)
    }

    private func createQueue(queueName: String) -> SqOperationQueue {
        // At this point the queue should be totally new so it's safe to start the queue synchronously
        let queue = SqOperationQueue(queueName, creator, persister, serializer, isPaused, true, logger)
        manage[queueName] = queue
        return queue
    }

    /// All operations in all queues will be removed
    public func cancelAllOperations() {
        for element in manage.values {
            element.cancelAllOperations()
        }
    }

    /// All operations with this tag in all queues will be removed
    public func cancelOperations(tag: String) {
        assertNotEmptyString(tag)
        for element in manage.values {
            element.cancelOperations(tag: tag)
        }
    }

    /// All operations with this uuid in all queues will be removed
    public func cancelOperations(uuid: String) {
        assertNotEmptyString(uuid)
        for element in manage.values {
            element.cancelOperations(uuid: uuid)
        }
    }

    /// Blocks the current thread until all of the receiver’s queued and executing operations finish executing.
    public func waitUntilAllOperationsAreFinished() {
        for element in manage.values {
            element.waitUntilAllOperationsAreFinished()
        }
    }

}
