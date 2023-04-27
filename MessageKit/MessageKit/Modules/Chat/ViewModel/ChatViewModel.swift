//
//  ChatViewModel.swift
//  MessageKit
//
//  Created by Suresh on 22/09/19.
//  Copyright © 2019 self. All rights reserved.
//

import UIKit

let dateFormat1 = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
let dateFormat2 = "hh:mm a dd MMM yyyy"

protocol ChatViewDelegate {
    func insertMessageOnUI()
}

final class ChatViewModel: BaseViewModel {

    private var user : User?
    private var chatApiClient: ChatApiClientProtocol?
    private var delegate : ChatViewDelegate?
    private var messages : [Chat] = [] {
        didSet {
             self.delegate?.insertMessageOnUI()
        }
    }
    private var dateFormatter = DateFormatter()
    private var attributedString = NSMutableAttributedString(string: "", attributes: [:])
    init(user: User?, delegate: ChatViewDelegate? = nil, apiClient: ChatApiClientProtocol = ChatApiClient()) {
        super.init()
        self.user = user
        self.delegate = delegate
        chatApiClient = apiClient
        
    }
    
    lazy var navigationTitle : String = {
        return "@\(self.user?.login ?? "")"
    }()
    
    var shouldEnableSendButton : Observable<Bool> = Observable(false)
}

extension ChatViewModel {
    
    func sendMessage(message: String) {
       
        
        let params = [
            "model": "gpt-3.5-turbo",
            "messages": [["role": "user", "content": message]]
        ] as [String : Any]
        
        
//       self.viewState.value = .Loading
        self.chatApiClient?.sendMessage(queryParam: params) {[weak self] (result: Result<Chat, Error>) in
            guard let weakSelf = self else {
                return
            }
            
//            weakSelf.viewState.value = .Loaded
            
            switch result {
            case .success(let chatMessage):
                weakSelf.messages.append(chatMessage)
                
            case .failure(let error):
                print(error)
                weakSelf.viewState.value = .Error(error)
            }
        }
    }
    
    func conversation(message: String) {
        let chatMessage = Chat(isReceived: false)
        let choice = Choice()
        let messageObject = Message(content: message, role: "user")
        messageObject.content = message
        messageObject.role = "user"
        choice.message = messageObject
        
        
        self.dateFormatter.dateFormat = dateFormat1
        chatMessage.created =  Date().timeIntervalSince1970 // self.dateFormatter.string(from: Date())
        chatMessage.choices = [choice]
        self.messages.append(chatMessage)
    }
    
    
}

extension ChatViewModel {
    func getMessages() -> [Chat] {
        return self.messages
    }
    
    func numberOfMessages(messages : [Chat]?) -> Int {
        return messages?.count ?? 0
    }
}

extension ChatViewModel {
    
    //Font for caption1 TextStyle,
    //To be used to find text size.
    static let messageFont = UIFont(name: "Helvetica-Bold", size:  13)!
    
    func getSize(for text : String?, defaultSize: CGSize, font: UIFont) -> CGSize {
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let estimatedRect = (text! as NSString).boundingRect(with: defaultSize, options: options, attributes: [NSAttributedString.Key.font : font], context: nil)
       
        return estimatedRect.size
    }
    
}
