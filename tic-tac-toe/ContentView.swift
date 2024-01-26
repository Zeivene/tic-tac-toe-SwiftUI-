import SwiftUI


// Main view of the app
struct ContentView: View {
    var body: some View {
        MainView()
        .padding()
    }
}


// Represents the main screen of the game
struct MainView: View {
    @State private var isGridVisible = false
    @State private var chosenSymbol: CellState = .empty

    var body: some View {
        VStack {
            if isGridVisible {
                gameView
            } else {
                selectionView
            }
        }
    }
    
    // View for the Tic-Tac-Toe game
    private var gameView: some View {
        GameGridView(initialSymbol: chosenSymbol, onReset: { isGridVisible = false })
    }

    // View for selecting X or O
    private var selectionView: some View {
        SelectionView(onXSelected: { selectSymbol(.x) }, onOSelected: { selectSymbol(.o) })
    }

    // Updates the symbol and shows the game grid
    private func selectSymbol(_ symbol: CellState) {
        chosenSymbol = symbol
        isGridVisible = true
    }
}


// View for selecting either X or O
struct SelectionView: View {
    var onXSelected: () -> Void
    var onOSelected: () -> Void

    var body: some View {
        VStack {
            TitleText(text: "Choose your symbol")
            SymbolButtonRow(onXSelected: onXSelected, onOSelected: onOSelected)
        }
    }
}


// Row of buttons for selecting X or O
struct SymbolButtonRow: View {
    var onXSelected: () -> Void
    var onOSelected: () -> Void

    var body: some View {
        HStack {
            SymbolButton(symbol: "X", action: onXSelected)
            SymbolButton(symbol: "O", action: onOSelected)
        }
    }
}


// View for displaying the title text
struct TitleText: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.title)
            .padding()
    }
}


// View for a symbol button (X or O)
struct SymbolButton: View {
    var symbol: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(symbol)
                .symbolButtonStyle()
        }
    }
}


// Custom styling extension for the symbol buttons
extension Text {
    func symbolButtonStyle() -> some View {
        self
            .font(.largeTitle)
            .frame(width: 100, height: 100)
            .foregroundColor(.white)
            .background(Color.black)
            .cornerRadius(50)
    }
}


// Enumeration representing the state of a cell in the game grid
enum CellState {
    case empty, x, o
}

// View for the Tic-Tac-Toe grid
struct GameGridView: View {
    @State private var cellStates = Array(repeating: CellState.empty, count: 9)
    @State private var currentSymbol: CellState
    @State private var gameState = GameState.active
    
    var onReset: () -> Void

    init(initialSymbol: CellState, onReset: @escaping () -> Void) {
        _currentSymbol = State(initialValue: initialSymbol)
        self.onReset = onReset
    }

    var body: some View {
        VStack {
            gameGrid
            Spacer()
            gameStateText
            ResetButton(action: resetGame)
        }
        .padding()
    }

    // Generates the grid for the game
    private var gameGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(0..<9, id: \.self) { index in
                GridCell(state: cellStates[index], action: { updateCell(at: index) })
            }
        }
        .disabled(gameState != .active)
    }

    // Displays text based on the current game state
    private var gameStateText: some View {
        Group {
            if gameState != .active {
                Text(gameState.text)
                    .font(.title)
                    .padding()
            }
        }
    }

    // Updates the cell and checks for a winner or draw
    private func updateCell(at index: Int) {
        guard gameState == .active else { return }
        
        if cellStates[index] == .empty {
            cellStates[index] = currentSymbol
            checkForWinner()
            currentSymbol = (currentSymbol == .x) ? .o : .x
        }
    }

    // Checks if there's a winner or if the game is a draw
    private func checkForWinner() {
        let winPatterns = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
            [0, 4, 8], [2, 4, 6]             // Diagonals
        ]

        for pattern in winPatterns {
            if cellStates[pattern[0]] != .empty &&
                cellStates[pattern[0]] == cellStates[pattern[1]] &&
                cellStates[pattern[1]] == cellStates[pattern[2]] {
                gameState = cellStates[pattern[0]] == .x ? .xWon : .oWon
                return
            }
        }

        if !cellStates.contains(.empty) {
            gameState = .draw
        }
    }

    // Resets the game to its initial state
    private func resetGame() {
        cellStates = Array(repeating: .empty, count: 9)
        currentSymbol = .x
        onReset()
    }
}


// View for a single cell in the game grid
struct GridCell: View {
    let state: CellState
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(symbolForState(state))
                .font(.largeTitle)
                .foregroundColor(colorForState(state))
                .frame(width: 100, height: 120)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
        }
    }

    // Returns the symbol based on the cell state
    private func symbolForState(_ state: CellState) -> String {
        switch state {
        case .x: return "X"
        case .o: return "O"
        case .empty: return ""
        }
    }

    // Returns the color based on the cell state
    private func colorForState(_ state: CellState) -> Color {
        switch state {
        case .o: return .red
        default: return .blue
        }
    }
}


// Enumeration representing the game state
enum GameState {
    case active, draw, xWon, oWon

    var text: String {
        switch self {
        case .active: return "Game in Progress"
        case .xWon: return "X Wins!"
        case .oWon: return "O Wins!"
        case .draw: return "It's a Draw!"
        }
    }
}


// View for the reset game button
struct ResetButton: View {
    var action: () -> Void

    var body: some View {
        Button("Reset Game", action: action)
            .resetButtonStyle()
    }
}


// Custom styling extension for the reset button
extension Button {
    func resetButtonStyle() -> some View {
        self
            .padding()
            .frame(width: 130, height: 40)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(5)
    }
}



#Preview {
    ContentView()
}
