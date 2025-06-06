//
//  utils.swift
//  IRL Bingo
//
//  Created by Juan Garcia on 6/5/25.
//

import Foundation
import UIKit

// Must have at least 5 cells marked for this to be called (for time purposes)
// And would be quicker to check from last placed marker so we don't
// have to check every cell when one is clicked


func checkForBingo(_ cells: [[BingoCell]], row: Int, col: Int) -> Bool {
    // Return true if any row, column, or diagonal is fully marked
    //
    return
        checkRow(cells, row:row, col:col) ||
        checkCol(cells, row:row, col:col) ||
        checkDiagonal(cells, row: row, col: col)
}


func checkRow(_ cells: [[BingoCell]], row: Int, col: Int) -> Bool {
    //start at all the way left and check if the row is filled by iterating through columns
    for i in 0..<cells.count {
        if !cells[row][i].isMarked {
            return false
        }
    }
    
    return true
}

func checkCol(_ cells: [[BingoCell]], row: Int, col: Int) -> Bool {
    
    for i in 0..<cells.count {
        if !cells[i][col].isMarked {
            return false
        }
    }
    
    return true
}

func checkDiagonal(_ cells: [[BingoCell]], row: Int, col: Int) -> Bool {
    // Gotta check both diagonal ways (bottom left to top right, top left to bottom right)
    
    // top left check
    var topLeftBingo = true
    var topRightBingo = true
    
    for i in 0..<cells.count {
        if !cells[i][i].isMarked {
            topLeftBingo = false
        }
        
        if !cells[cells.count - i - 1][i].isMarked {
            topRightBingo = false
        }
    }
    
    
    
    return topLeftBingo || topRightBingo
}
