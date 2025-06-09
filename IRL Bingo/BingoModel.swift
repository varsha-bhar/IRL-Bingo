//
//  BingoModel.swift
//  IRL Bingo
//
//  Created by Juan Garcia on 6/5/25.
//

import Foundation
import UIKit
import FirebaseFirestore


struct BingoCell: Codable {
    var title: String
    var isMarked: Bool
}

struct BingoBoard: Codable {
    var documentId: String?   // optional, because it might not exist at creation
    var title: String
    var cells: [[BingoCell]]
    var creater: String?
    
    // Computed property to return documentId or generate new UUID string if nil
    var id: String {
        documentId ?? UUID().uuidString
    }
}
