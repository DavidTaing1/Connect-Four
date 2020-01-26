defmodule Game do
  def start do
    IO.puts("Vier Gewinnt!")

    player1 = :global.whereis_name(:player1)
    player2 = :global.whereis_name(:player2)

    random_number = :rand.uniform(2)

    beginner = if random_number == 1, do: true, else: false

    game_loop([[], [], [], [], [], [], []], player1, player2, beginner)
  end

  def game_loop(current_board, player1, player2, turn) do
    send player1, {self(), current_board, turn}
    send player2, {self(), current_board, !turn}

    receive do
      {player, column} ->
        {new_board, win} = process_turn(current_board, player, column)
        cond do
          win == :draw ->
            send player1, {new_board, :draw}
            send player2, {new_board, :draw}
          win and player == :player1 ->
            send player1, {new_board, :win}
            send player2, {new_board, :lose}
          win and player == :player2 ->
            send player1, {new_board, :lose}
            send player2, {new_board, :win}
          !win ->
            game_loop(new_board, player1, player2, !turn)
        end
    end
  end

  def process_turn(board, player, column) do
    selected_col = Enum.at(board, column - 1)

    col_length = length(selected_col)

    # place different symbol according to player
    symbol = if player == :player1, do: "x", else: "o"


    new_col = List.insert_at(selected_col, col_length, symbol)
    new_board = List.replace_at(board, column - 1, new_col)

    {new_board, check_board(new_board)}
  end

  # only board checking after this

  def check_board(board) do
    cond do
      check_win(board) ->
        true
      check_draw(board) ->
        :draw
      true ->
        false
    end
  end

  def check_win(board) do
    check_diagonal(board)
    or
    check_rows(board, 0)
    or
    check_cols(board, 0)
  end

  # check wether every col is full
  def check_draw(board) do
    [head | tail] = board
    cond do
      length(head) < 6 ->
        false
      length(board) == 1 ->
        true
      true ->
        check_draw(tail)
    end
  end

  def check_diagonal(board) do
    lines1 = [{3, 0}, {4, 0}, {5, 0}, {5, 1}, {5, 2}, {5, 3}]
    lines2 = [{2, 0}, {1, 0}, {0, 0}, {0, 1}, {0, 2}, {0, 3}]
    check_diagonal_help(board, lines1, true)
    or
    check_diagonal_help(board, lines2, false)
  end

  def check_diagonal_help(board, lines, mode) do
    if length(lines) > 0 do
      [head | tail] = lines
      {row, col} = head
      win = if mode,
               do: check_diagonal_rek1(board, "", 0, row, col),
               else: check_diagonal_rek2(board, "", 0, row, col)
      cond do
        win ->
          true
        !win ->
          check_diagonal_help(board, tail, mode)
      end
    else
      false
    end
  end

  def check_diagonal_rek1(board, symbol, number, row, col) do
    current_col = Enum.at(board, col)

    disks_possible_col = 7 - col + number

    disks_possible_row = 6 - row + number

    cond do
      disks_possible_col < 4 or disks_possible_row < 4 ->
        false
      # out of bounds check
      row < length(current_col) ->
        current_symbol = Enum.at(current_col, row)
        cond do
          current_symbol == symbol and number >= 3 ->
            true
          current_symbol == symbol and row - 1 >= 0 and col + 1 < 7 ->
            check_diagonal_rek1(board, symbol, number + 1, row - 1, col + 1)
          current_symbol != symbol ->
            check_diagonal_rek1(board, current_symbol, 1, row - 1, col + 1)
          true ->
            false
        end
      true -> check_diagonal_rek1(board, "", 0, row - 1, col + 1)
    end
  end

  def check_diagonal_rek2(board, symbol, number, row, col) do
    current_col = Enum.at(board, col)

    disks_possible_col = 7 - col + number

    disks_possible_row = 6 - row + number

    cond do
      disks_possible_col < 4 or disks_possible_row < 4 ->
        false
      # out of bounds check
      row < length(current_col) ->
        current_symbol = Enum.at(current_col, row)
        cond do
          current_symbol == symbol and number >= 3 ->
            true
          current_symbol == symbol and row + 1 < 6 and col + 1 < 7 ->
            check_diagonal_rek2(board, symbol, number + 1, row + 1, col + 1)
          current_symbol != symbol ->
            check_diagonal_rek2(board, current_symbol, 1, row + 1, col + 1)
          true ->
            false
        end
      true ->
        check_diagonal_rek2(board, "", 0, row + 1, col + 1)
    end
  end

  def check_rows(board, row) do
    win = check_rows_rek(board, "", 0, row, 0)

    cond do
      !win and row < 5 ->
        check_rows(board, row + 1)
      true ->
        win
    end
  end

  def check_rows_rek(board, symbol, number, row, col) do
    current_col = Enum.at(board, col)

    disks_possible = 7 - col + number

    cond do
      # row doesn't have enough disks left to win
      disks_possible < 4 ->
        false
      # out of bounds check
      row < length(current_col) ->
        current_symbol = Enum.at(current_col, row)
        if current_symbol == symbol do
          if number >= 3,
             do: true,
             else: check_rows_rek(board, symbol, number + 1, row, col + 1)
        else
          check_rows_rek(board, current_symbol, 1, row, col + 1)
        end
      true ->
        check_rows_rek(board, "", 0, row, col + 1)
    end
  end

  def check_cols(board, col) do
    current_col = Enum.at(board, col)

    win = check_cols_rek(current_col, "", 0)

    cond do
      !win and col < 6 ->
        check_cols(board, col + 1)
      true ->
        win
    end

  end

  def check_cols_rek(column, symbol, number) do
    cond do
      # column doesn't have enough disks left to win
      length(column) + number < 4 ->
        false

      List.first(column) == symbol ->
        [_ | tail] = column
        # check if it's the fourth symbol in a row
        if number >= 3, do: true, else: check_cols_rek(tail, symbol, number + 1)

      true ->
        [current_symbol | tail] = column
        check_cols_rek(tail, current_symbol, 1)
    end
  end
end