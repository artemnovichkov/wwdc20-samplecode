/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`RequestResponseSession` is concrete subclass of NetworkSession that implements a request/response model.
*/

import Foundation
import Combine

public class RequestResponseSession: NetworkSession {
    public enum Error: Swift.Error {
        case requestTimeout
        case connectionReset
        case encoding(Swift.Error)
        case unableToDecode
        case unknown
    }
    
    private struct PendingRequest {
       var id: UInt32
       var completion: Future<Bool, Swift.Error>.Promise
    }
    
    private enum Command: String, Codable {
        case request
        case acknowledge
    }
    
    private struct Wrapper: Codable {
        var command: Command
        var requestIdentifier: UInt32
        var payload: KeyCodedPayload<UInt8>?
    }
    
    public private(set) lazy var messagePublisher = messagesSubject.eraseToAnyPublisher()
    public let timeout: DispatchTimeInterval = .seconds(10)
    public var disconnectOnFailure: Bool = true
    private let dispatchQueue = DispatchQueue(label: "RequestResponseSession.dispatchQueue")
    private let messagesSubject = PassthroughSubject<Codable, Never>()
    private var pendingRequests = [UInt32: PendingRequest]()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let keyCoder = KeyCoder()
    private var requestCancellables = [UInt32: AnyCancellable]()
    private var cancellables = Set<AnyCancellable>()
    
    public override init() {
        super.init()
        
        statePublisher
        .filter { state -> Bool in
            state == .disconnecting
        }
        .receive(on: dispatchQueue)
        .sink { [weak self] state in
            guard let self = self else {
                return
            }
            
            for (_, request) in self.pendingRequests {
                request.completion(.failure(Error.connectionReset))
            }
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Request
    
    public func request<Message: Codable>(message: Message, completion: ((Result<Bool, Swift.Error>) -> Void)? = nil) {
        let (id, publisher) = requestPublisher(message: message)
        
        let cancellable = publisher
        .receive(on: dispatchQueue)
        .sink(receiveCompletion: { [weak self] result in
            self?.requestCancellables[id] = nil
            
            switch result {
            case .finished:
                completion?(.success(true))
            case .failure(let error):
                completion?(.failure(error))
            }
        }) { _ in
            // noop
        }
        
        dispatchQueue.async { [weak self] in
            self?.requestCancellables[id] = cancellable
        }
    }
    
    @discardableResult
    public func requestPublisher<Message: Codable>(message: Message) -> (requestIdentifier: UInt32, publisher: AnyPublisher<Bool, Swift.Error>) {
        let id = arc4random_uniform(UInt32.max)
        let requestPublisher: AnyPublisher<Bool, Swift.Error> = self.requestPublisher(id: id, message: message)
        
        return (id, requestPublisher)
    }
    
    @discardableResult
    private func requestPublisher<Message: Codable>(id: UInt32, message: Message) -> AnyPublisher<Bool, Swift.Error> {
        Future { [weak self] (promise: @escaping Future<Bool, Swift.Error>.Promise) in
            guard let self = self else {
                promise(.failure(Error.unknown))
                return
            }
            self.request(id: id, message: message, completion: promise)
        }
        .timeout(.init(timeout), scheduler: dispatchQueue, customError: {
            Error.requestTimeout
        })
        .receive(on: dispatchQueue)
        .handleEvents(receiveCompletion: { [weak self] completion in
            guard let self = self else {
                return
            }
            
            self.pendingRequests[id] = nil
            
            switch completion {
            case .failure(let error):
                self.logger.log("Request failed.")
                
                switch error {
                case Error.connectionReset:
                    break
                default:
                    if self.disconnectOnFailure {
                        self.disconnect()
                    }
                }
            default:
                break
            }
        })
        .eraseToAnyPublisher()
    }
    
    private func request<Message: Codable>(id: UInt32, message: Message, completion: @escaping Future<Bool, Swift.Error>.Promise) {
        dispatchQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            guard self.state == .connected else {
                completion(.failure(NetworkSession.Error.notConnected))
                return
            }
            
            self.pendingRequests[id] = PendingRequest(id: id, completion: completion)
            
            do {
                let payload = try self.keyCoder.encode(value: message)
                let wrapper = Wrapper(command: .request, requestIdentifier: id, payload: payload)
                let encodedWrapper = try self.encoder.encode(wrapper)
                
                self.send(data: encodedWrapper)
            } catch {
                completion(.failure(Error.encoding(error)))
            }
        }
    }
    
    // MARK: - Response
    
    private func acknowledge(requestIdentifier: UInt32) {
        let wrapper = Wrapper(command: .acknowledge, requestIdentifier: requestIdentifier, payload: nil)
        
        do {
            let data = try encoder.encode(wrapper)
            send(data: data)
        } catch {
            logger.log("Error encoding acknowledgment - \(error)")
        }
    }
    
    // MARK: - Receive
    
    override func receive() {
        guard let connection = connection else {
            return
        }
        
        connection.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.logger.log("Receive failed with error - \(error)")
                return
            }
            
            if let data = data {
                self.dispatchQueue.async {
                    if let wrapper = self.decode(data: data), wrapper.command != .acknowledge {
                        self.acknowledge(requestIdentifier: wrapper.requestIdentifier)
                    }
                }
            }
            
            if let context = context, context.isFinal {
                self.logger.log("Receive context is final, disconnecting.")
                self.disconnect()
            } else {
                self.receive()
            }
        }
    }
    
    private func decode(data: Data) -> Wrapper? {
        do {
            let wrapper = try decoder.decode(Wrapper.self, from: data)
            
            switch wrapper.command {
            case .request:
                guard let payload = wrapper.payload else {
                    break
                }
                
                let message = try keyCoder.decode(for: payload.codingKey, data: payload.data)
                messagesSubject.send(message)
            case .acknowledge:
                dispatchQueue.async { [weak self] in
                    guard let request = self?.pendingRequests[wrapper.requestIdentifier] else {
                        return
                    }
                    
                    request.completion(.success(true))
                }
            }
            
            return wrapper
        } catch {
            logger.log("Error decoding - \(error)")
        }
        
        return nil
    }
}
