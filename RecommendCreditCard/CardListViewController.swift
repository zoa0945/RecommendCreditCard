//
//  CardListViewController.swift
//  RecommendCreditCard
//
//  Created by Mac on 2022/01/11.
//

import UIKit
import Kingfisher
import FirebaseDatabase
import FirebaseFirestore

class CardListViewController: UITableViewController {
    var ref: DatabaseReference! // Firebase Realtime Database
    let db = Firestore.firestore()
    var creditCardList: [CreditCard] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UITableView Cell Register
        let nibName = UINib(nibName: "CardListCell", bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: "CardListCell")
        
        // 실시간 데이터베이스 (Realtime Database) 읽기
        ref = Database.database().reference()

        ref.observe(.value) { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else { return }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: value)
                let cardData = try JSONDecoder().decode([String: CreditCard].self, from: jsonData)
                let cardList = Array(cardData.values)
                self.creditCardList = cardList.sorted { $0.rank < $1.rank }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch let error {
                print("ERROR JSON PARSING \(error.localizedDescription)")
            }
        }
        
        // Firestore Database 읽기
//        db.collection("creditCardList").addSnapshotListener { snapshot, error in
//            guard let document = snapshot?.documents else {
//                print("ERROR Firestore fetching document \(String(describing: error))")
//                return
//            }
//            self.creditCardList = document.compactMap({ doc -> CreditCard? in
//                do {
//                    let jsonData = try JSONSerialization.data(withJSONObject: doc.data(), options: [])
//                    let creditCard = try JSONDecoder().decode(CreditCard.self, from: jsonData)
//                    return creditCard
//                } catch let error {
//                    print("ERROR JSON PARSING \(error.localizedDescription)")
//                    return nil
//                }
//            }).sorted { $0.rank < $1.rank }
//
//            DispatchQueue.main.async {
//                self.tableView.reloadData()
//            }
//        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return creditCardList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CardListCell", for: indexPath) as? CardListCell else { return UITableViewCell() }
        
        cell.rankLabel.text = "\(creditCardList[indexPath.row].rank)위"
        cell.promotionLabel.text = "\(creditCardList[indexPath.row].promotionDetail.amount)만원 증정"
        cell.cardNameLabel.text = "\(creditCardList[indexPath.row].name)"
        
        let imageURL = URL(string: creditCardList[indexPath.row].cardImageURL)
        cell.cardImageView.kf.setImage(with: imageURL)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 상세화면 전달
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let detailViewController = storyboard.instantiateViewController(withIdentifier: "CardDetailViewController") as? CardDetailViewController else { return }
        detailViewController.promotionDetail = creditCardList[indexPath.row].promotionDetail
        self.show(detailViewController, sender: nil)
        
        // 실시간 데이터베이스 (Realtime Database) 쓰기
        // 데이터베이스 객체의 key값(여기서는 Item0, 1, 2, ...)을 알 수 있을 때
        let cardId = creditCardList[indexPath.row].id
        ref.child("Item\(cardId)/isSelected").setValue(true)
        
        // 데이터베이스 객체의 key값(여기서는 Item0, 1, 2, ...)을 알 수 없을 때
        ref.queryOrdered(byChild: "id").queryEqual(toValue: cardId).observe(.value) {
            [weak self] snapshot in
            guard let self = self,
                  let value = snapshot.value as? [String: [String: Any]],
                  let key = value.keys.first else { return }

            self.ref.child("\(key)/isSelected").setValue(true)
        }
        
        // Firestore Database 쓰기
//        // 데이터베이스 객체의 key값(여기서는 Item0, 1, 2, ...)을 알 수 있을 때
//        let cardId = creditCardList[indexPath.row].id
////        db.collection("creditCardList").document("card\(cardId)").updateData(["isSelected": true])
//
//        // 데이터베이스 객체의 key값(여기서는 Item0, 1, 2, ...)을 알 수 없을 때
//        db.collection("creditCardList").whereField("id", isEqualTo: cardId).getDocuments { snapshot, error in
//            guard let document = snapshot?.documents.first else {
//                print("ERROR fetching document")
//                return
//            }
//
//            document.reference.updateData(["isSelected": true])
//        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // 실시간 데이터베이스 (Realtime Database) 삭제
            // 데이터베이스 객체의 key값(여기서는 Item0, 1, 2, ...)을 알 수 있을 때
            let cardId = creditCardList[indexPath.row].id
            ref.child("Item\(cardId)").removeValue()
            
            // 데이터베이스 객체의 key값(여기서는 Item0, 1, 2, ...)을 알 수 없을 때
            ref.queryOrdered(byChild: "id").queryEqual(toValue: cardId).observe(.value) { [weak self] snapshot in
                guard let self = self,
                      let value = snapshot.value as? [String: [String: Any]],
                      let key = value.keys.first else { return }
                self.ref.child(key).removeValue()
            }
            
            // Firestore Database 삭제
            // 데이터베이스 객체의 key값(여기서는 Item0, 1, 2, ...)을 알 수 있을 때
//            let cardId = creditCardList[indexPath.row].id
////            db.collection("creditCardList").document("card\(cardId)").delete()
//
//            // 데이터베이스 객체의 key값(여기서는 Item0, 1, 2, ...)을 알 수 없을 때
//            db.collection("creditCardList").whereField("id", isEqualTo: cardId).getDocuments{ snapshot, error in
//                guard let document = snapshot?.documents.first else {
//                    print("ERROR fetching document")
//                    return
//                }
//                document.reference.delete()
//            }
        }
    }
}
