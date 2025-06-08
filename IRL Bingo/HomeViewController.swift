//
//  HomeViewController.swift
//  IRL Bingo
//
//  Created by Amrith Gandham on 6/6/25.
//

import UIKit
import SwiftUI

// Local Storage Only
@MainActor
class BingoBoardManager: ObservableObject {
    @Published var userBoards: [BingoBoard] = []
    @Published var communityBoards: [BingoBoard] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadLocalBoards()
        loadSampleCommunityBoards()
    }
    
    func loadUserBoards() {
        loadLocalBoards()
    }
    
    func loadCommunityBoards() {
        loadSampleCommunityBoards()
    }
    
    private func loadLocalBoards() {
        // For now, create some sample boards
        userBoards = [
            BingoBoard(
                title: "My First Board",
                cells: createSampleCells(),
                creater: "currentUser"
            ),
            BingoBoard(
                title: "Weekend Fun",
                cells: createSampleCells(),
                creater: "currentUser"
            )
        ]
    }
    
    private func loadSampleCommunityBoards() {
        communityBoards = [
            BingoBoard(
                title: "Public Board 1",
                cells: createSampleCells(),
                creater: "otherUser"
            ),
            BingoBoard(
                title: "Community Challenge",
                cells: createSampleCells(),
                creater: "anotherUser"
            )
        ]
    }
    
    private func createSampleCells() -> [[BingoCell]] {
        var cells: [[BingoCell]] = []
        
        for row in 0..<5 {
            var rowCells: [BingoCell] = []
            for col in 0..<5 {
                // Center cell (2,2) is the FREE space
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
    
    func saveBoard(_ board: BingoBoard) async -> Bool {
        // Add to local storage
        userBoards.append(board)
        return true
    }
}

struct BingoHomeView: View {
    @StateObject private var boardManager = BingoBoardManager()
    @State private var showingCreateBoard = false
    @State private var showingCommunityBoards = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Action Buttons
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
                        Text("Prototype Cells")
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
                                Text("Prototype Content")
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
                                        NavigationLink(destination: PlayBoardView(board: board)) {
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
                
                Text("Prototype Content")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Home") {
                        dismiss()
                    }
                }
            }
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
            creater: "currentUser"  // Using "creater" as in your model
        )
        
        Task {
            let success = await boardManager.saveBoard(newBoard)
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
                        NavigationLink(destination: PlayBoardView(board: board)) {
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
    
    init(board: BingoBoard) {
        _board = State(initialValue: board)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
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
                                        // Don't edit the free space
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
                            .frame(width: 60, height: 60) // Fixed size for all cells
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Home") {
                }
            }
        }
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
            return Color.green.opacity(0.3)
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
