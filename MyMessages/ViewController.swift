//
//  ViewController.swift
//  MyMessages
//
//  Created by marobert on 2020-11-26.
//

import UIKit
import InputBarAccessoryView
import MessageKit
import Combine

class ViewController: MessagesViewController {

    private var chatMessages: [MessageType] = []
    
    private var threadClient: ThreadClient!
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
        return control
    }()
    
    @objc func loadMoreMessages() {
        threadClient.loadMore { messages in
            DispatchQueue.main.async {
                self.chatMessages.insert(contentsOf: messages, at: 0)
                self.messagesCollectionView.reloadDataAndKeepOffset()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    @objc func doNothing() {
        print("No-op ;)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.threadClient = ThreadClient(threadId: "19:c10c6b469c1b4ff18d30204a0a631eab@thread.v2")
        
        // Configure delegates and data sources
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        // Override some of the MessageKit defaults
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        showMessageTimestampOnSwipeLeft = true // default false
        
        // Confg
        title = "My Chat Thread"
        let call = UIBarButtonItem(image: UIImage(systemName: "phone"), style: .plain, target: self, action: #selector(doNothing))
        navigationItem.rightBarButtonItems = [call]
        
        // Pull down to fetch more messages
        messagesCollectionView.refreshControl = refreshControl
        
        
        // fetch the first pages of messages
        loadInitialMessages()
        
        // subscribe to new messages
        threadClient.onMessage { [weak self] message in
            self?.insertMessage(message)
        }
    }
    
    private func loadInitialMessages() {
        // show a spinner while we do the first fetch
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()
        messagesCollectionView.backgroundView = spinner
        
        threadClient.fetchMessages { result in
            self.messagesCollectionView.backgroundView = nil
            spinner.stopAnimating()
            if case let .success(messages) = result {
                self.chatMessages = messages
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
    
    func insertMessage(_ message: Message) {
        chatMessages.append(message)
        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([chatMessages.count - 1])
            if chatMessages.count >= 2 {
                messagesCollectionView.reloadSections([chatMessages.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        })
    }
    
    func isLastSectionVisible() -> Bool {
        guard !chatMessages.isEmpty else { return false }
        let lastIndexPath = IndexPath(item: 0, section: chatMessages.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
}

extension ViewController: MessagesDataSource {

    func currentSender() -> SenderType {
        return UserDirectory.currentUser()
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return chatMessages.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return chatMessages[indexPath.section]
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return NSAttributedString(string: formatter.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
}

extension ViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        inputBar.inputTextView.text = ""
        inputBar.sendButton.startAnimating()
        inputBar.inputTextView.placeholder = "Sending..."
        threadClient.sendChatMessage(content: text) { result in
            inputBar.sendButton.stopAnimating()
            inputBar.inputTextView.placeholder = String()
            if case let .success(message) = result {
                self.insertMessage(message)
            }
        }
    }
}

extension ViewController: MessagesDisplayDelegate, MessagesLayoutDelegate {
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let user = UserDirectory.getSender(fromId: message.sender.senderId)
        avatarView.initials = user.initials
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if indexPath.section % 3 == 0 {
            return 25
        }
        return 0;
    }
    
//    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
//        return 17
//    }
//
//    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
//        if indexPath.section % 3 == 0 {
//            return 18
//        }
//        return 0;
//    }
//
//    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
//        return 16
//    }
}
