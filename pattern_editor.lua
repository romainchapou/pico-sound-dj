pattern_editor = class:new {
  copied_patterns = {},

  init = function(_ENV)
    first_visible_pattern = 0

    cur_line = 0
    cur_col = 0

    -- TODO see about refactoring this in a selector_handler class (after doing
    -- the implem for the sfx browser tab)
    multi_selection = false

    -- TODO @Improve: this selection system is not great, as it is not super
    -- obvious that you are copying whole patterns while selecting only some
    -- colums. For now it works ok
    --
    -- TODO @Unsure about those variable names
    sel_start_line = 0
    sel_start_col = 0

    sel_line_upper = 0
    sel_line_lower = 0
    sel_col_upper = 0
    sel_col_lower = 0

    patterns = {}

    for i=1,64 do
      add(patterns, make_pattern_widget(i-1))
      patterns[i]:load_pattern_from_mem()
    end
  end,

  post_update = function(_ENV)
    if multi_selection then
      sel_line_lower = min(cur_line, sel_start_line)
      sel_line_upper = max(cur_line, sel_start_line)
      sel_col_lower  = min(cur_col, sel_start_col)
      sel_col_upper  = max(cur_col, sel_start_col)
    else
      sel_start_line = cur_line
      sel_start_col  = cur_col

      sel_line_lower = cur_line
      sel_line_upper = cur_line
      sel_col_lower  = cur_col
      sel_col_upper  = cur_col
    end
  end,

  update = function(_ENV)
    -- play/pause
    if btn(6) then
      if stat(57) then
        music(-1)
      else
        -- TODO storing should be done not just here but every time we modify
        -- any pattern (this would not keep in sync if the patterns are
        -- modified while playing back the track)
        store_all_patterns_in_mem(_ENV)

        music(btn(4) and cur_line or 0)
      end
    end

    -- pane movement
    if btn(4) then
      if btnp(0) then
        GLOBAL.current_pane = settings_pane
        return
      end

      if btnp(1) and patterns[cur_line+1].is_channel_activated[cur_col+1] then
        GLOBAL.current_pane = sfx_editor
        sfx_editor:init(patterns[cur_line+1].channels[cur_col+1].value)
        return
      end
    end

    if not multi_selection then
      if btnp_seq(4, 4) and cur_col < 4 then
        multi_selection = true
        send_msg("select mode")
        return
      end

      if btnp_seq(5, 4) then
        paste_selected_patterns(_ENV)
        return
      end
    else
      if btnp_seq(5, 5) then
        cut_selected_patterns(_ENV)
        return
      end

      if btnp_once(4) then
        copy_selected_patterns(_ENV)
        return
      end
    end


    if not btn(4) and not btn(5) then
      cur_col = mid(0, cur_col + nudge(), multi_selection and 3 or 6)

      cur_line += nudge(true)
      cur_line %= 64

      if first_visible_pattern + 15 < cur_line then
        first_visible_pattern = cur_line - 15
      elseif cur_line < first_visible_pattern then
        first_visible_pattern = cur_line
      end
    end

    post_update(_ENV)

    for pat_line=sel_line_lower,sel_line_upper do
      for pat_col=sel_col_lower,sel_col_upper do
        patterns[pat_line+1]:update(pat_col)
      end
    end
  end,

  draw = function(_ENV)
    shadow_print("pattern editor", 1, 1)

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
                              is_in_range(i+first_visible_pattern,
                                          sel_line_lower,
                                          sel_line_upper),
                              sel_col_lower, sel_col_upper)
    end

    local cur_playing_pattern = stat(54)

    if cur_playing_pattern >= first_visible_pattern and cur_playing_pattern < first_visible_pattern+16 then
      palt(0, false)
      palt(14, true)
      spr(1, start_x - 4, start_y + (cur_playing_pattern - first_visible_pattern)%16 * 6)
      palt()
    end
  end,

  -- update functions

  send_pat_msg = function(_ENV, act)
    send_msg(act .. #copied_patterns .. " pattern"
             .. (#copied_patterns == 1 and "" or "s"))
  end,

  copy_selected_patterns = function(_ENV)
    copied_patterns = {}
    store_all_patterns_in_mem(_ENV)

    for pat_id=sel_line_lower,sel_line_upper do
      add(copied_patterns, peek4(get_pattern_mem_addr(pat_id)))
    end
    multi_selection = false

    send_pat_msg(_ENV, "copied ")
  end,

  cut_selected_patterns = function(_ENV)
    copy_selected_patterns(_ENV)

    for pat_id=sel_line_lower,sel_line_upper do
      patterns[pat_id+1] = make_pattern_widget(pat_id)
    end

    store_all_patterns_in_mem(_ENV)

    send_pat_msg(_ENV, "cut ")
  end,

  paste_selected_patterns = function(_ENV)
    for i=1,#copied_patterns do
      if cur_line + i-1 < 64 then
        poke4(get_pattern_mem_addr(cur_line + i-1), copied_patterns[i])
        patterns[cur_line + i]:load_pattern_from_mem()
      end
    end

    send_pat_msg(_ENV, "pasted ")
  end,

  store_all_patterns_in_mem = function(_ENV)
    for p in all(patterns) do
      p:store_pattern_in_mem()
    end
  end
}
