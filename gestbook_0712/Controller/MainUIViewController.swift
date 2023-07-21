import UIKit
import RealmSwift
import Speech
import AVFoundation

class MainUIViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    var itemArray: [ItemTable] = []
        let realm = try! Realm()

    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var newButton: UIButton!
    @IBOutlet weak var oldButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var messageText: UITextView!
    @IBOutlet weak var transButton: UIButton!
    @IBOutlet weak var down: UIView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "zh-TW"))  // 使用中文
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @IBAction func microphoneButtonTapped(_ sender: UIButton) {
           
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            //microphoneButton.setTitle("開始錄音", for: .normal)
            microphoneButton.tintColor = .systemBlue
        } else {
            startRecording()
            //microphoneButton.setTitle("停止錄音", for: .normal)
            microphoneButton.isEnabled = true
            microphoneButton.tintColor = .systemGray
        }
    }
    
    //傳送
    @IBAction func submitButton(_ sender: UIButton) {
        
        // 創建新的ItemTable對象
        let newItem = ItemTable()
            
        // 計算新的ID
        let newId = getNewId()
        
        // 獲取當前日期和時間
        let currentDate = Date()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"

        let formattedDate = dateFormatter.string(from: currentDate)

        newItem.id = "F\(newId), \(formattedDate)"
            
        // 獲取使用者輸入的名稱和消息
        newItem.name = nameText.text ?? ""
        newItem.message = messageText.text ?? ""
        
        if newItem.message == "" {
            
            // 顯示警告對話框
            let warningAlert = UIAlertController(title: "WARNING", message: "留言訊息不能為空", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "確認", style: .default, handler: nil)
            warningAlert.addAction(okAction)
            present(warningAlert, animated: true, completion: nil)
            return
            
        } else if newItem.name == "" {
            
            newItem.name = "神秘人"
        }
        // 保存新的項目
        saveItem(newItem)
        // 更新idLabel的文本
        idLabel.text = "F\(newId+1), \(formattedDate)："
        
        // 清空輸入框的文本
        nameText.text = ""
        messageText.text = ""
            
        // 重新加載表格視圖以顯示新的項目
        loadItems()
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableViewHeightConstraint.constant = tableView.contentSize.height
            view.layoutIfNeeded()

        
        // 顯示 messageButton
            messageButton.isHidden = false
            // 隱藏 idLabel、nameText 和 messageText
            idLabel.isHidden = true
            nameText.isHidden = true
            messageText.isHidden = true
            // 啟用 messageButton
            messageButton.isEnabled = true
        transButton.isHidden = true
        transButton.isEnabled = false
    }
    
    
    @IBAction func newButtonTapped(_ sender: UIButton) {
        // 將 itemArray 按照由新到舊的順序排序
        itemArray.sort { convertToTimestamp(dateString: $0.id) > convertToTimestamp(dateString: $1.id) }
//        for item in itemArray {
//                print("ID: \(item.id), Timestamp: \(convertToTimestamp(dateString: item.id))")
//            }
        // 重新加載表格視圖
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableViewHeightConstraint.constant = tableView.contentSize.height
            view.layoutIfNeeded()
    }

    @IBAction func oldButtonTapped(_ sender: UIButton) {
        // 將 itemArray 按照由舊到新的順序排序
        itemArray.sort { convertToTimestamp(dateString: $0.id) < convertToTimestamp(dateString: $1.id) }

        // 重新加載表格視圖
        tableView.reloadData()
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableViewHeightConstraint.constant = tableView.contentSize.height
            view.layoutIfNeeded()
    }
    
    @IBAction func messageButtonTapped(_ sender: UIButton) {
        // 隱藏 messageButton
        messageButton.isHidden = true
        
        // 顯示 idLabel、nameText 和 messageText
        idLabel.isHidden = false
        nameText.isHidden = false
        messageText.isHidden = false
        // 禁用 messageButton
        messageButton.isEnabled = false
        transButton.isHidden = false
        transButton.isEnabled = true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        print("這裡啦")
        
        tableView.isScrollEnabled = false
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableViewHeightConstraint.constant = tableView.contentSize.height
            view.layoutIfNeeded()

        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        let item = ItemTable()
//            item.id = "1"
//            item.name = "冰淇淋"
//            item.message = "冰淇淋好好吃"
//            saveItem(item)
//        saveItem(item)
        
        
        let newId = realm.objects(ItemTable.self).count + 1
        // 獲取當前日期和時間
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        let formattedDate = dateFormatter.string(from: currentDate)
            
        // 更新idLabel的文本
        idLabel.text = "F\(newId), \(formattedDate)："
        
        loadItems()
        
        tableView?.register(UINib(nibName: "MainTableViewCell", bundle: nil), forCellReuseIdentifier: MainTableViewCell.identified)
        tableView?.delegate = self
        tableView.dataSource = self
        
        idLabel.isHidden = true
        nameText.isHidden = true
        messageText.isHidden = true
        transButton.isHidden = true
        transButton.isEnabled = false
    }
    //
    func saveItem(_ item: ItemTable) {
        try! realm.write {
            realm.add(item)
        }
    }
    //
    func loadItems() {
        itemArray = Array(realm.objects(ItemTable.self))
    }
    
    func getNewId() -> Int {
        if let ItemTable = realm.objects(ItemTable.self).first {
            try! realm.write {
                ItemTable.sortID += 1
            }
            return ItemTable.sortID
        } else {
            let ItemTable = ItemTable()
            try! realm.write {
                realm.add(ItemTable)
            }
            return 1
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            messageText.resignFirstResponder()
            return true
      }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.view.endEditing(true)
        }
    
    //textviwe隨著你輸入的多行文字，增加行數
        func adTextView (hight: UITextView) {
            hight.translatesAutoresizingMaskIntoConstraints = true
            hight.sizeToFit()
            hight.isScrollEnabled = false
        }
    
    func convertToTimestamp(dateString: String) -> Int {
        // Split the dateString into components
        let components = dateString.split(separator: ",")
        // Check if there are at least 2 components
        if components.count >= 2 {
            // The second component should be the date
            let dateComponent = String(components[1]).trimmingCharacters(in: .whitespaces)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
            if let date = dateFormatter.date(from: dateComponent) {
                return Int(date.timeIntervalSince1970)
            }
        }
        return 0
    }


    
    func startRecording() {
            if recognitionTask != nil {
                recognitionTask?.cancel()
                recognitionTask = nil
            }

            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to set up audio session")
            }

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

            let inputNode = audioEngine.inputNode

            guard let recognitionRequest = recognitionRequest else {
                fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
            }

            recognitionRequest.shouldReportPartialResults = true

            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
                var isFinal = false

                if result != nil {
                    self.messageText.text = result?.bestTranscription.formattedString
                    isFinal = (result?.isFinal)!
                }

                if error != nil || isFinal {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)

                    self.recognitionRequest = nil
                    self.recognitionTask = nil

                    self.microphoneButton.isEnabled = true
                }
            })

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                self.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()

            do {
                try audioEngine.start()
            } catch {
                print("audioEngine couldn't start because of an error.")
            }

            messageText.text = "正在聆聽..."
            microphoneButton.tintColor = .systemGray
            // 隱藏 messageButton
            messageButton.isHidden = true
            
            // 顯示 idLabel、nameText 和 messageText
            idLabel.isHidden = false
            nameText.isHidden = false
            messageText.isHidden = false
            // 禁用 messageButton
            messageButton.isEnabled = false
            transButton.isHidden = false
            transButton.isEnabled = true
        }

        func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
            if available {
                microphoneButton.isEnabled = true
            } else {
                microphoneButton.isEnabled = false
            }
        }

}


extension MainUIViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainTableViewCell.identified, for: indexPath) as! MainTableViewCell
        cell.rankLabel?.text = String(itemArray[indexPath.row].id)
        cell.messageLabel?.text = String(itemArray[indexPath.row].message)
        cell.nameLabel?.text = String(itemArray[indexPath.row].name)
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let realm = try! Realm()

        let editAction = UIContextualAction(style: .normal, title: "編輯") { (action, view, completionHandler) in
            let newId = realm.objects(ItemTable.self)
            let itemToEdit = newId[indexPath.row]

            let alert = UIAlertController(title: "編輯項目", message: "", preferredStyle: .alert)

            alert.addTextField { (messageTextField) in
                messageTextField.text = itemToEdit.message
                messageTextField.placeholder = "更新訊息"
            }

            // first define susses alert controller here
            let susses = UIAlertController(title: "SUSSES", message: "項目已更新成功", preferredStyle: .alert)
            let action2 = UIAlertAction(title: "確認", style: .default) { (action2) in
                self.tableView.reloadData()
                
            }
            susses.addAction(action2)

            // now susses can be used within this action
            let action = UIAlertAction(title: "更新", style: .default) { (action) in
                if let message = alert.textFields?.last?.text {
                    try! realm.write {

                        if !itemToEdit.name.contains("(已編輯)") {
                            itemToEdit.name = "(已編輯) \(itemToEdit.name)"
                        }

                        itemToEdit.message = message
                    }
                    self.present(susses, animated: true, completion: nil) // 顯示"susses"對話框
                    // 重新計算並設定 TableView 高度
                    self.tableView.layoutIfNeeded()
                    self.tableViewHeightConstraint.constant = self.tableView.contentSize.height
                    self.view.layoutIfNeeded()
                }
            }

            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            completionHandler(true)
        }
        editAction.backgroundColor = UIColor.blue
                
            
        
        let reply = UIContextualAction(style: .normal, title: "回覆") { (action, view, completionHandler) in
            // 获取选中的消息
            let selectedMessage = realm.objects(ItemTable.self)[indexPath.row]
            
            // 显示 idLabel、nameText 和 messageText
            self.idLabel.isHidden = false
            self.nameText.isHidden = false
            self.messageText.isHidden = false
            // 禁用 messageButton
            self.messageButton.isEnabled = false
            self.messageButton.isHidden = true
            self.transButton.isHidden = false
            self.transButton.isEnabled = true
            
            let idComponents = selectedMessage.id.split(separator: ",")
            let idBeforeComma = String(idComponents[0])
                
            // 在 messageText 中添加 @+ F \(id) 的文字
            self.messageText.text = "@\(idBeforeComma) - "
                
            
            completionHandler(true)
        }
                
                return UISwipeActionsConfiguration(actions: [editAction, reply])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let realm = try! Realm()
        
        let removeAction = UIContextualAction(style: .normal, title: "移除") { (action, view, completionHandler) in
                            
            let items = realm.objects(ItemTable.self)
            let itemToRemove = items[indexPath.row]
                            
            try! realm.write {
                realm.delete(itemToRemove)
            }
                            

            // 定義成功的提示框
            let successAlert = UIAlertController(title: "SUSSES", message: "項目已成功移除", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "確認", style: .default) { (action) in
                // 在確認按鈕被按下後更新畫面
                self.itemArray.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.tableView.reloadData()
                // 重新計算並設定 TableView 高度
                self.tableView.layoutIfNeeded()
                self.tableViewHeightConstraint.constant = self.tableView.contentSize.height
                self.view.layoutIfNeeded()
            }
            successAlert.addAction(okAction)
            // 顯示成功的提示框
            self.present(successAlert, animated: true, completion: nil)
            completionHandler(true)
        }



        
        removeAction.backgroundColor = UIColor.red
        
                
        let copy = UIContextualAction(style: .normal, title: "複製") { (action, view, completionHandler) in
            // 取得選取值
            let selectedMessage = realm.objects(ItemTable.self)[indexPath.row].message
            // 複製
            UIPasteboard.general.string = selectedMessage
            completionHandler(true)
        }
            return UISwipeActionsConfiguration(actions: [removeAction, copy])
    }
}

