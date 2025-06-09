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
        var documentId: String?   
        var title: String
        var cells: [[BingoCell]]
        var creater: String?
        var createdAt: Date?
        
        var id: String {
            documentId ?? UUID().uuidString
        }

        init(title: String, cells: [[BingoCell]], creater: String?, documentId: String? = nil, createdAt: Date? = nil) {
            self.title = title
            self.cells = cells
            self.creater = creater
            self.documentId = documentId
            self.createdAt = createdAt
        }
    }
