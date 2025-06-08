//
//  BingoBoard.swift
//  IRL Bingo
//
//  Created by Iverson Li on 6/5/25.
//

import UIKit

class BingoViewController: UIViewController {

    let gridSize = 5
    var buttons: [[TileButton]] = []
    var marked: [[Bool]] = Array(repeating: Array(repeating: false, count: 5), count: 5)
    var isEditingMode = false

    let editToggleButton = UIButton(type: .system)
    let newBoardButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupEditToggleButton()
        setupNewBoardButton()
        setupBingoBoard()
    }

    func setupEditToggleButton() {
        editToggleButton.setTitle("Edit Mode: OFF", for: .normal)
        editToggleButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        editToggleButton.translatesAutoresizingMaskIntoConstraints = false
        editToggleButton.addTarget(self, action: #selector(toggleEditMode), for: .touchUpInside)

        view.addSubview(editToggleButton)

        NSLayoutConstraint.activate([
            editToggleButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            editToggleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editToggleButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func setupNewBoardButton() {
        newBoardButton.setTitle("New Board", for: .normal)
        newBoardButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        newBoardButton.translatesAutoresizingMaskIntoConstraints = false
        newBoardButton.addTarget(self, action: #selector(newBoardTapped), for: .touchUpInside)

        view.addSubview(newBoardButton)

        NSLayoutConstraint.activate([
            newBoardButton.centerYAnchor.constraint(equalTo: editToggleButton.centerYAnchor),
            newBoardButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            newBoardButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc func toggleEditMode() {
        isEditingMode.toggle()
        let title = isEditingMode ? "Edit Mode: ON" : "Edit Mode: OFF"
        editToggleButton.setTitle(title, for: .normal)
    }

    @objc func newBoardTapped() {
        // Turn off edit mode if on
        if isEditingMode {
            toggleEditMode()
        }

        // Clear all tiles except middle
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let tile = buttons[row][col]
                if row == 2 && col == 2 {
                    tile.setTileText("Free Space")
                } else {
                    tile.setTileText("")
                }
                tile.unmark()
                marked[row][col] = false
            }
        }
    }

    func setupBingoBoard() {
        let boardStack = UIStackView()
        boardStack.axis = .vertical
        boardStack.alignment = .fill
        boardStack.distribution = .fillEqually
        boardStack.spacing = 4
        boardStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(boardStack)

        NSLayoutConstraint.activate([
            boardStack.topAnchor.constraint(equalTo: editToggleButton.bottomAnchor, constant: 10),
            boardStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            boardStack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            boardStack.heightAnchor.constraint(equalTo: boardStack.widthAnchor)
        ])

        for row in 0..<gridSize {
            var rowButtons: [TileButton] = []
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.alignment = .fill
            rowStack.distribution = .fillEqually
            rowStack.spacing = 4
            boardStack.addArrangedSubview(rowStack)

            for col in 0..<gridSize {
                let tile = TileButton(row: row, col: col)
                let isCenter = (row == 2 && col == 2)
                let label = isCenter ? "Free Space" : ""
                tile.setTileText(label)
                tile.tag = row * gridSize + col
                tile.addTarget(self, action: #selector(tileTapped(_:)), for: .touchUpInside)
                rowButtons.append(tile)
                rowStack.addArrangedSubview(tile)
            }

            buttons.append(rowButtons)
        }
    }

    @objc func tileTapped(_ sender: TileButton) {
        let row = sender.row
        let col = sender.col
        let currentText = sender.accessibilityLabel ?? ""

        if isEditingMode {
            // Edit mode: show alert to change text
            showEditAlert(for: sender)
        } else {
            // Non-edit mode: toggle X only if text is non-empty (locked)
            // If empty text, ignore taps unless in edit mode
            if !currentText.isEmpty {
                sender.toggleMark()
                marked[row][col] = sender.isMarked
                if checkBingo() {
                    showBingoAlert()
                }
            }
        }
    }

    func showEditAlert(for tile: TileButton) {
        let alert = UIAlertController(
            title: "Edit Tile",
            message: "Enter text (empty clears text and mark)",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.text = tile.accessibilityLabel ?? ""
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            let input = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if input.isEmpty {
                tile.setTileText("")
                tile.unmark()
                self.marked[tile.row][tile.col] = false
            } else {
                tile.setTileText(input)
                tile.unmark()
                self.marked[tile.row][tile.col] = false
            }
        }))

        present(alert, animated: true)
    }

    func checkBingo() -> Bool {
        for i in 0..<gridSize {
            if marked[i].allSatisfy({ $0 }) { return true } // row
            if (0..<gridSize).allSatisfy({ marked[$0][i] }) { return true } // col
        }

        // Diagonals
        if (0..<gridSize).allSatisfy({ marked[$0][$0] }) { return true }
        if (0..<gridSize).allSatisfy({ marked[$0][gridSize - 1 - $0] }) { return true }

        return false
    }

    func showBingoAlert() {
        let alert = UIAlertController(title: "Bingo!", message: "You got 5 in a row!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
