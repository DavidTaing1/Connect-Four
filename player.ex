defmodule Player do
  def init(player_number) do
    IO.puts("Warten auf Server...")
    Node.connect(:game@localhost)

    spawn(Player, game(player_number), [])
  end

  def game(player_number) do
    player_name = if player_number == 1, do: :player1, else: :player2

    :global.register_name(player_name, self())
    game_loop(player_name)
  end

  def game_loop(player_name) do
    receive do
      {from, current_board, true} ->
        draw_board(current_board)
        next_turn = do_turn(current_board)
        send from, {player_name, next_turn}
      {_, current_board, false} ->
        draw_board(current_board)
        IO.puts("Der Gegner ist am Zug.")
      {current_board, :win} ->
        draw_board(current_board)
        IO.puts("Sie haben gewonnen!\nWarte auf neues Spiel...")
      {current_board, :lose} ->
        draw_board(current_board)
        IO.puts("Sie haben verloren!\nWarte auf neues Spiel...")
      {current_board, :draw} ->
        draw_board(current_board)
        IO.puts("Unentschieden!\nWarte auf neues Spiel...")
    end
    game_loop(player_name)
  end

  def do_turn(board) do
    next_turn = IO.gets("In welche Spalte soll der Stein? ")
                |> String.trim

    next_turn_int = String.to_integer(next_turn)

    cond do
      next_turn_int > 7 or next_turn_int < 1->
        IO.puts("Bitte nur Zahlen zwischen 1 und 7.")
        do_turn(board)
      length(Enum.at(board, next_turn_int - 1)) >= 6 ->
        IO.puts("Spalte ist bereits voll.")
        do_turn(board)
      true -> next_turn_int
    end
  end

  def draw_board(board) do
    draw_rows(board, 5)
    # draw column index
    IO.puts("  1 2 3 4 5 6 7")
  end

  def draw_rows(board, row) do
    # draw row index
    IO.write("#{row + 1} ")
    draw_symbols(board, row, 0)
    IO.puts("")
    # stop at last row
    if row > 0, do: draw_rows(board, row - 1)
  end

  def draw_symbols(board, row, col) do
    current_col = Enum.at(board, col)

    if row < length(current_col) do
      current_symbol = Enum.at(current_col, row)
      IO.write("#{current_symbol} ")
    else
      IO.write("  ")
    end

    # stop at last column
    if col < 6, do: draw_symbols(board, row, col + 1)
  end
end
