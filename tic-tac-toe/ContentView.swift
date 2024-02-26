import SwiftUI


// Main view of the app
struct ContentView: View {
    @State private var currentView: CurrentView = .mainSelection

    var body: some View {
        Group {
            switch currentView {
            case .mainSelection:
                MainSelectionView { selectedGameMode in
                    currentView = .selectionView(gameMode: selectedGameMode)
                }
            case .selectionView(let gameMode):
                SelectionView { selectedSymbol in
                    currentView = .gameView(gameMode: gameMode, initialSymbol: selectedSymbol)
                }
            case .gameView(let gameMode, let initialSymbol):
                MainView(initialSymbol: initialSymbol, gameMode: gameMode) {
                    currentView = .mainSelection
                }
            }
        }
    }
}


enum CurrentView {
    case mainSelection
    case selectionView(gameMode: GameMode)
    case gameView(gameMode: GameMode, initialSymbol: CellState)
}


enum GameMode {
    case playerVsPlayer, playerVsComputer
}


// Main selection screen
struct MainSelectionView: View {
    var onGameModeSelected: (GameMode) -> Void

    var body: some View {
        VStack(spacing: 30) {
            TitleText(text: "Play Against..", fontSize: 35)
            Button("Player") {
                onGameModeSelected(.playerVsPlayer)
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Computer") {
                onGameModeSelected(.playerVsComputer)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}


// Represents the main screen of the game
struct MainView: View {
    var initialSymbol: CellState
    var gameMode: GameMode
    var onReset: () -> Void

    var body: some View {
        GameGridView(initialSymbol: initialSymbol, gameMode: gameMode, onReset: onReset)
    }
}


// Main selection buttons
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .font(.title)
            .frame(width: 200, height: 80)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}


// View for selecting either X or O
struct SelectionView: View {
    var onSymbolSelected: (CellState) -> Void

    var body: some View {
        VStack {
            TitleText(text: "Choose your symbol", fontSize: 30)
            SymbolButtonRow(onXSelected: { onSymbolSelected(.x) }, onOSelected: { onSymbolSelected(.o) })
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
    var fontSize: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
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
            .frame(width: 120, height: 120)
            .foregroundColor(.white)
            .background(Color.black)
            .cornerRadius(60)
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
    @State private var isComputerThinking = false
    let gameMode: GameMode
    let onReset: () -> Void

    init(initialSymbol: CellState, gameMode: GameMode, onReset: @escaping () -> Void) {
        _currentSymbol = State(initialValue: initialSymbol)
        self.gameMode = gameMode
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
        .onAppear(perform: performComputerFirstMoveIfNeeded)
    }

    private var gameGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
            ForEach(0..<9) { index in
                GridCell(state: cellStates[index]) { updateCell(at: index) }
            }
        }
        .disabled(gameState != .active)
    }

    private var gameStateText: some View {
        Text(gameState.text)
            .font(.title)
            .padding()
            .opacity(gameState != .active ? 1 : 0)
    }

    private func updateCell(at index: Int) {
        guard gameState == .active, cellStates[index] == .empty, !isComputerThinking else { return }
        
        cellStates[index] = currentSymbol
        checkForWinner()
        toggleCurrentSymbol()
        
        if gameMode == .playerVsComputer {
            isComputerThinking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.computerMove()
                self.isComputerThinking = false
            }
        }
    }

    private func computerMove() {
        guard gameMode == .playerVsComputer, gameState == .active else { return }

        if let randomIndex = cellStates.indices.filter({ cellStates[$0] == .empty }).randomElement() {
            cellStates[randomIndex] = currentSymbol
            checkForWinner()
            toggleCurrentSymbol()
        }
    }

    private func performComputerFirstMoveIfNeeded() {
        guard gameMode == .playerVsComputer, currentSymbol == .o else { return }
        performComputerFirstMove()
    }

    private func performComputerFirstMove() {
        isComputerThinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentSymbol = self.currentSymbol == .x ? .o : .x
            self.computerMove()
            self.isComputerThinking = false
        }
    }

    private func toggleCurrentSymbol() {
        currentSymbol = currentSymbol == .x ? .o : .x
    }

    private func processGameUpdate() {
        checkForWinner()
        currentSymbol = currentSymbol.opposite
    }

    private func checkForWinner() {
        let winPatterns: [[Int]] = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8],
            [0, 3, 6], [1, 4, 7], [2, 5, 8],
            [0, 4, 8], [2, 4, 6]
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

    private func resetGame() {
        cellStates = .init(repeating: .empty, count: 9)
        gameState = .active
        onReset()
    }
}

extension CellState {
    var opposite: CellState {
        switch self {
        case .x: return .o
        case .o: return .x
        default: return self
        }
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
