pattern_editor = class:new {
  init = function(_ENV)
    first_visible_pattern = 0

    line_selection = 0
    column_selection = 0

    patterns = {}

    for i=1,64 do
      add(patterns, make_pattern_widget(i-1))
      patterns[i]:load_pattern_from_mem()
    end
  end,

  update = function(_ENV)
    -- play/pause
    if btnp(5, 1) then
      if stat(57) then
        music(-1)
      else
        for p in all(patterns) do
          p:store_pattern_in_mem()
        end

        music(line_selection)
      end
    end

    -- pane movement
    if btn(4, 1) then
      if btnp(1) and patterns[line_selection+1].is_channel_activated[column_selection+1] then
        GLOBAL.current_pane = sfx_editor
        sfx_editor:init(patterns[line_selection+1].channels[column_selection+1].value)
      end

      return
    end

    if not btn(4) and not btn(5) then
      if btnp(0) then column_selection -= 1 end
      if btnp(1) then column_selection += 1 end

      if btnp(2) then line_selection -= 1 end
      if btnp(3) then line_selection += 1 end

      column_selection = mid(0, column_selection, 6)
      line_selection = mid(0, line_selection, 63)

      if first_visible_pattern + 15 < line_selection then
        first_visible_pattern = line_selection - 15
      elseif line_selection < first_visible_pattern then
        first_visible_pattern = line_selection
      end
    end

    patterns[line_selection+1]:update(column_selection)
  end,

  draw = function(_ENV)
    print("pattern editor", 1, 1, 6)

    local start_x, start_y = 14, 18

    for i=0,3 do
      print("ch" .. tostr(i), start_x - 2 + i*CHANNEL_X_OFFSET, start_y - 8, 6)
    end

    palt(14, true)
    palt(0, false)
    pal(0, 6)

    for i=0,2 do
      -- pattern settings buttons
      spr(2+i, start_x + 63 + i*8, start_y - 8)
    end

    pal()

    for i=0,15 do
      local pat_id = i + first_visible_pattern
      local is_highlight_line = pat_id \ 4 % 2 == 0

      if is_highlight_line then
        rectfill(start_x-14, start_y +i*6,
                 start_x - 6, start_y + i*6 + 4 + bool_to_num(pat_id % 4 ~= 3), 9)
      end

      print(two_digit_number_str(pat_id),
            start_x - 13, start_y + i*6, is_highlight_line and 7 or 6)

      patterns[pat_id+1]:draw(start_x, start_y + i*6,
                              line_selection == i+first_visible_pattern,
                              column_selection)
    end

    local cur_playing_pattern = stat(54)

    if cur_playing_pattern >= first_visible_pattern and cur_playing_pattern < first_visible_pattern+16 then
      palt(0, false)
      palt(14, true)
      spr(1, start_x - 4, start_y + (cur_playing_pattern - first_visible_pattern)%16 * 6)
      palt()
    end
  end,
}
