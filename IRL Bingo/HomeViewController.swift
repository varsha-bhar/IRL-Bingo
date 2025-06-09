//
//  HomeViewController.swift
//  IRL Bingo
//

import UIKit
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// Firebase Storage
@MainActor
class BingoBoardManager: ObservableObject {
    @Published var userBoards: [BingoBoard] = []
    @Published var communityBoards: [BingoBoard] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    init() {
        loadUserBoards()
        loadCommunityBoards()
    }
    
    func loadUserBoards() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No authenticated user")
            return
        }
        
        getUserUsername(userId: currentUser.uid) { [weak self] username in
            guard let username = username else {
                print("Could not find username for user")
                return
            }
            
            self?.loadBoardsForUser(username: username)
        }
    }
    
    private func getUserUsername(userId: String, completion: @escaping (String?) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let username = document.data()?["username"] as? String
                completion(username)
            } else {
                completion(nil)
            }
        }
    }
    
    private func loadBoardsForUser(username: String) {
        isLoading = true
        
        db.collection("bingo_boards")
            .whereField("creater", isEqualTo: username)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        print("Error loading user boards: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.userBoards = []
                        return
                    }
                    
                    self?.userBoards = documents.compactMap { doc -> BingoBoard? in
                        let data = doc.data()
                        
                        guard let title = data["title"] as? String,
                              let creater = data["creater"] as? String,
                              let cellsData = data["cells"] as? [[String: Any]] else {
                            return nil
                        }
                        
                        let cells = self?.parseCellsData(cellsData) ?? self?.createEmptyCells() ?? []
                        let timestamp = data["createdAt"] as? Timestamp
                        let createdAt = timestamp?.dateValue()
                        
                        return BingoBoard(title: title, cells: cells, creater: creater, documentId: doc.documentID, createdAt: createdAt)
                    }
                }
            }
    }
    
    func loadCommunityBoards() {
        isLoading = true
        
        db.collection("bingo_boards")
            .whereField("isPublic", isEqualTo: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.communityBoards = []
                        return
                    }
                    
                    self?.communityBoards = documents.compactMap { doc -> BingoBoard? in
                        let data = doc.data()
                        
                        guard let title = data["title"] as? String,
                              let creater = data["creater"] as? String,
                              let cellsData = data["cells"] as? [[String: Any]] else {
                            return nil
                        }
                        
                        let cells = self?.parseCellsData(cellsData) ?? self?.createEmptyCells() ?? []
                        let timestamp = data["createdAt"] as? Timestamp
                        let createdAt = timestamp?.dateValue()
                        
                        return BingoBoard(title: title, cells: cells, creater: creater, documentId: doc.documentID, createdAt: createdAt)
                    }
                }
            }
    }

    func updateBoard(_ board: BingoBoard) async -> Bool {
    guard let documentID = board.documentId else {
        errorMessage = "Cannot update board without document ID"
        return false
    }
    
    return await withCheckedContinuation { continuation in
        let boardData: [String: Any] = [
            "cells": convertCellsToFirebaseFormat(board.cells),
            "updatedAt": Timestamp()
        ]
        
        db.collection("bingo_boards").document(documentID).updateData(boardData) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                continuation.resume(returning: false)
            } else {
                continuation.resume(returning: true)
            }
        }
    }
}
    
    
    private func parseCellsData(_ cellsData: [[String: Any]]) -> [[BingoCell]] {
        var result: [[BingoCell]] = []
        
        for rowDict in cellsData {
            
            let sortedKeys = rowDict.keys.sorted { (a, b) -> Bool in
                (Int(a) ?? 0) < (Int(b) ?? 0)
            }
            
            var row: [BingoCell] = []
            for key in sortedKeys {
                if let cellDict = rowDict[key] as? [String: Any],
                   let title = cellDict["title"] as? String,
                   let isMarked = cellDict["isMarked"] as? Bool {
                    row.append(BingoCell(title: title, isMarked: isMarked))
                }
            }
            result.append(row)
        }
        
        return result
    }
    
    private func createEmptyCells() -> [[BingoCell]] {
        var cells: [[BingoCell]] = []
        
        for row in 0..<5 {
            var rowCells: [BingoCell] = []
            for col in 0..<5 {
                if row == 2 && col == 2 {
                    rowCells.append(BingoCell(title: "FREE", isMarked: true))
                } else {
                    rowCells.append(BingoCell(title: "", isMarked: false))
                }
            }
            cells.append(rowCells)
        }
        
        return cells
    }
    
    func saveBoard(_ board: BingoBoard, isPublic: Bool) async -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "No authenticated user"
            return false
        }
        
        return await withCheckedContinuation { continuation in
            getUserUsername(userId: currentUser.uid) { [weak self] username in
                guard let username = username else {
                    self?.errorMessage = "Could not find username"
                    continuation.resume(returning: false)
                    return
                }
                
                let boardData: [String: Any] = [
                    "title": board.title,
                    "creater": username,
                    "cells": self?.convertCellsToFirebaseFormat(board.cells) ?? [],
                    "isPublic": isPublic,
                    "createdAt": Timestamp(),
                    "userId": currentUser.uid
                ]
                
                self?.db.collection("bingo_boards").addDocument(data: boardData) { error in
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        continuation.resume(returning: false)
                    } else {
                        continuation.resume(returning: true)
                    }
                }
            }
        }
    }
    
    private func convertCellsToFirebaseFormat(_ cells: [[BingoCell]]) -> [[String: [String: Any]]] {
        return cells.map { row in
            var rowDict: [String: [String: Any]] = [:]
            for (index, cell) in row.enumerated() {
                rowDict["\(index)"] = [
                    "title": cell.title,
                    "isMarked": cell.isMarked
                ]
            }
            return rowDict
        }
    }
}

struct BingoHomeView: View {
    @StateObject private var boardManager = BingoBoardManager()
    @State private var showingCreateBoard = false
    @State private var showingCommunityBoards = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Button(action: {
                        showingCreateBoard = true
                    }) {
                        Text("Create New Board")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingCommunityBoards = true
                    }) {
                        Text("Browse Community Boards")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your Boards")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    HStack {
                        Text("Board Title")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 0) {
                        if boardManager.userBoards.isEmpty {
                            VStack(spacing: 8) {
                                Text("No Boards Yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Create your first board to get started!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(Array(boardManager.userBoards.enumerated()), id: \.element.title) { index, board in
                                        NavigationLink(destination: PlayBoardView(board: board, boardManager: boardManager)) {
                                            BoardRowView(board: board)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        if index < boardManager.userBoards.count - 1 {
                                            Divider()
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                boardManager.loadUserBoards()
                boardManager.loadCommunityBoards()
            }
            .sheet(isPresented: $showingCreateBoard) {
                CreateBoardView(boardManager: boardManager)
            }
            .sheet(isPresented: $showingCommunityBoards) {
                CommunityBoardsView(boardManager: boardManager)
            }
        }
    }
}

struct BoardRowView: View {
    let board: BingoBoard
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(board.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let createdAt = board.createdAt {
                    Text("Created on \(formattedDate(createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.clear)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct CreateBoardView: View {
    @Environment(\.dismiss) private var dismiss
    let boardManager: BingoBoardManager
    
    @State private var boardTitle = ""
    @State private var isPublic = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter Board Title")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Title", text: $boardTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                HStack {
                    Text("Make this board public?")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isPublic)
                        .labelsHidden()
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    saveBoard()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save Board")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(boardTitle.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .disabled(boardTitle.isEmpty || isLoading)
            }
            .navigationTitle("Create Board")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveBoard() {
        isLoading = true
        
        let emptyCells = (0..<5).map { row in
            (0..<5).map { col in
                if row == 2 && col == 2 {
                    return BingoCell(title: "FREE", isMarked: true)
                } else {
                    return BingoCell(title: "", isMarked: false)
                }
            }
        }
        
        let newBoard = BingoBoard(
            title: boardTitle,
            cells: emptyCells,
            creater: ""
        )
        
        Task {
            let success = await boardManager.saveBoard(newBoard, isPublic: isPublic)
            await MainActor.run {
                isLoading = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

struct CommunityBoardsView: View {
    @Environment(\.dismiss) private var dismiss
    let boardManager: BingoBoardManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(boardManager.communityBoards.enumerated()), id: \.element.title) { index, board in
                        NavigationLink(destination: PlayBoardView(board: board, boardManager: boardManager)) {
                            CommunityBoardRowView(board: board)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Community Boards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CommunityBoardRowView: View {
    let board: BingoBoard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(board.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Text("By: \(board.creater ?? "Anonymous")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Public")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PlayBoardView: View {
    @State private var board: BingoBoard
    @State private var showingBingo = false
    @State private var showingReset = false
    @State private var isEditMode = false
    @State private var editingCell: (row: Int, col: Int)? = nil
    @State private var editText = ""

    let boardManager: BingoBoardManager
    
    init(board: BingoBoard, boardManager: BingoBoardManager) {
        _board = State(initialValue: board)
        self.boardManager = boardManager
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    if isEditMode {
                        saveChanges()
                    }
                    isEditMode.toggle()
                }) {
                    Text(isEditMode ? "Done Editing" : "Edit Cards")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(isEditMode ? .white : .blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(isEditMode ? Color.green : Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isEditMode ? Color.green : Color.blue.opacity(0.3), lineWidth: 1)
                        )
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { col in
                            BingoCellView(
                                cell: $board.cells[row][col],
                                isEditMode: isEditMode,
                                isFreeSpace: (row == 2 && col == 2),
                                onTap: {
                                    if isEditMode {
                                        if row == 2 && col == 2 {
                                            return
                                        }
                                        editingCell = (row: row, col: col)
                                        editText = board.cells[row][col].title
                                    } else {
                                        cellTapped(row: row, col: col)
                                    }
                                }
                            )
                            .frame(width: 60, height: 60)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
                        
            Spacer()
            
            if !isEditMode {
                Button(action: {
                    showingReset = true
                }) {
                    Text("Reset Board")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(isEditMode ? "Edit Board" : "Play Board")
        .navigationBarTitleDisplayMode(.inline)

        .alert("Edit Card", isPresented: Binding<Bool>(
            get: { editingCell != nil },
            set: { if !$0 { editingCell = nil } }
        )) {
            TextField("Enter card text", text: $editText)
            Button("Cancel", role: .cancel) {
                editingCell = nil
            }
            Button("Save") {
                if let cell = editingCell {
                    board.cells[cell.row][cell.col].title = editText
                    editingCell = nil

                    saveChanges()
                }
            }
        } message: {
            Text("Enter what should be on this bingo card")
        }
        .alert("BINGO!", isPresented: $showingBingo) {
            Button("Continue Playing") { }
        } message: {
            Text("Congratulations! You got a BINGO!")
        }
        .alert("Reset Board", isPresented: $showingReset) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetBoard()
            }
        } message: {
            Text("Are you sure you want to reset this board? All progress will be lost.")
        }
    }
    
    private func cellTapped(row: Int, col: Int) {
        if row == 2 && col == 2 {
            return
        }
        
        board.cells[row][col].isMarked.toggle()

        saveChanges()
        
        if board.cells[row][col].isMarked {
            if checkForBingo(board.cells, row: row, col: col) {
                showingBingo = true
            }
        }
    }
    
    private func resetBoard() {
        for row in 0..<board.cells.count {
            for col in 0..<board.cells[row].count {
                if row == 2 && col == 2 {
                    board.cells[row][col].isMarked = true
                } else {
                    board.cells[row][col].isMarked = false
                }
            }
        }

        saveChanges()
    }

    private func saveChanges() {
        Task {
            let success = await boardManager.updateBoard(board)
            if !success {
                print("Failed to save board changes")
            }
        }
    }
}

struct BingoCellView: View {
    @Binding var cell: BingoCell
    var isEditMode: Bool = false
    var isFreeSpace: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(cellBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(cellBorderColor, lineWidth: 1)
                    )
                
                if isEditMode && !isFreeSpace {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        Spacer()
                    }
                    .padding(4)
                }
                
                Text(displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .padding(4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var displayText: String {
        if isFreeSpace {
            return "FREE"
        }
        if isEditMode && cell.title.isEmpty {
            return "Tap to edit"
        }
        return cell.title.isEmpty ? "" : cell.title
    }
    
    private var cellBackgroundColor: Color {
        if isFreeSpace {
            return Color.green.opacity(0.7)
        } else if cell.isMarked {
            return Color.blue
        } else if isEditMode && cell.title.isEmpty {
            return Color.yellow.opacity(0.2)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var cellBorderColor: Color {
        if isEditMode && !isFreeSpace {
            return Color.blue.opacity(0.5)
        }
        return Color(.systemGray4)
    }
    
    private var textColor: Color {
        if cell.isMarked {
            return .white
        } else if cell.title.isEmpty && isEditMode {
            return .secondary
        } else {
            return .primary
        }
    }
}

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUIView()
    }
    
    private func setupSwiftUIView() {
        let swiftUIView = BingoHomeView()
        let hostingController = UIHostingController(rootView: swiftUIView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension Data {
    func decoded<T: Decodable>() throws -> T {
        return try JSONDecoder().decode(T.self, from: self)
    }
}
