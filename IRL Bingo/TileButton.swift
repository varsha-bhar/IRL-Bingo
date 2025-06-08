//
//  TileButton.swift
//  IRL Bingo
//
//  Created by Iverson Li on 6/5/25.
//


import UIKit

class TileButton: UIButton {
    let textLabel = UILabel()
    let xLabel = UILabel()

    var isMarked: Bool = false {
        didSet {
            xLabel.isHidden = !isMarked
        }
    }

    var row: Int = 0
    var col: Int = 0

    init(row: Int, col: Int) {
        super.init(frame: .zero)
        self.row = row
        self.col = col
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        // Text label
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.font = .systemFont(ofSize: 14)
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        // X overlay
        xLabel.text = "❌"
        xLabel.textColor = .red
        xLabel.font = .boldSystemFont(ofSize: 36)
        xLabel.textAlignment = .center
        xLabel.translatesAutoresizingMaskIntoConstraints = false
        xLabel.isHidden = true

        addSubview(textLabel)
        addSubview(xLabel)

        // Layout both labels to fill button
        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            textLabel.topAnchor.constraint(equalTo: topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            xLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            xLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        layer.borderWidth = 2
        layer.borderColor = UIColor.black.cgColor
        backgroundColor = .white
    }

    func setTileText(_ text: String) {
        textLabel.text = text
        accessibilityLabel = text
    }

    func toggleMark() {
        isMarked.toggle()
    }

    func unmark() {
        isMarked = false
    }
}
