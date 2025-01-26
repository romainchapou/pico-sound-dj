pattern_editor = class:new {
  copied_patterns_is_full = false,
  copied_patterns = {},

  first_visible_pattern = 0,

  cur_line = 0,
  cur_col = 0,

  last_edited_pattern = 0,

  init = function(_ENV)
    multi_selection = false

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

      -- Hack using that the total number of sfx is the same as the total number of patterns
      -- Note that this is really useful only for the speed display
      sfx_settings[i]:load_from_mem()
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
    check_if_modification()

    if btnp_once(6) then
      if btn(BTN_A) then
        if not multi_selection then
          paste_selected_patterns(_ENV)
        end

        return
      end

      -- play/pause
      if is_sound_playing() then
        stop_all_sounds()
      else
        music(cur_line)
      end
    end

    -- panes movements
    if handle_move_pane(-1) or handle_move_pane(-1, true) then
      return
    end

    if patterns[cur_line+1].is_channel_activated[cur_col+1] and handle_move_pane(1) then
      sfx_overview.current_sfx = patterns[cur_line+1].channels[cur_col+1].value
      return
    end

    if not multi_selection then
      if btn_double_press(BTN_B) then
        if cur_col >= 4 then
          cur_col = 4
          sel_start_col = 0
        end

        multi_selection = true
        send_msg "select mode"
        return
      end
    else
      if btnp_once(BTN_B) then
        copy_selected_patterns(_ENV)
        return
      elseif btn_double_press(BTN_A) then
        cut_selected_patterns(_ENV)
        return
      end
    end


    if no_action_button() then
      -- from channel 0 to first btn widget
      cur_col = mid(0, cur_col + nudge(), multi_selection and 4 or 6)

      cur_line = (btnp_once(2) or btnp_once(3)) and (cur_line + nudge(true)) % 64 or mid(0, cur_line + nudge(true), 63)

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
    shadow_print("patterns", 1, 1)

    local start_x, start_y = 14, 20

    for i=0,3 do
      print("ch" .. tostr(i), start_x - 2 + i*CHANNEL_X_OFFSET, start_y - 8, 6)
    end

    pal(0, 6)

    for i=0,2 do
      -- pattern settings buttons
      spr(2+i, start_x + 63 + i*8, start_y - 8)
    end

    pal(0, 0)

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

    if is_in_range(cur_playing_pattern, first_visible_pattern, first_visible_pattern+15) then
      spr(1, start_x - 4, start_y + (cur_playing_pattern - first_visible_pattern)%16 * 6)
    end

    -- play infos

    local pr = function(txt_left, txt_right, y_diff)
      print(txt_left, 104, 44+y_diff, 6)
      print(txt_right, 116, 44+y_diff, 0)
    end

    pr("pt:", cur_playing_pattern >= 0 and cur_playing_pattern or "---", -18)
    pr("sp:", current_played_speed(), -12)

    for i=0,3 do
      pr("c" .. i .. ":", get_playing_note(i), 6*i)
    end
  end,

  -- update functions

  send_pat_msg = function(_ENV, act)
    send_msg(act .. #copied_patterns .. " pattern"
             .. s_if_plural(copied_patterns)
             .. (not copied_patterns_is_full and " (" .. #copied_patterns[1]
             .. " channel" .. s_if_plural(copied_patterns[1]) .. ")" or ""))
  end,

  copy_selected_patterns = function(_ENV)
    copied_patterns = {}
    copied_patterns_is_full = sel_col_upper == 4

    store_all_patterns_in_mem(_ENV)

    for pat_id=sel_line_lower,sel_line_upper do
      if copied_patterns_is_full then
        -- copy the whole pattern, including the settings
        add(copied_patterns, $get_pattern_mem_addr(pat_id))
      else
        -- copy only some channels
        local pat = {}
        for col=sel_col_lower,sel_col_upper do
          add(pat, pack(patterns[pat_id+1]:get_col(col+1)))
        end
        add(copied_patterns, pat)
      end
    end
    multi_selection = false
    cur_line = sel_line_lower
    cur_col = sel_col_lower

    send_pat_msg(_ENV, "copied ")
  end,

  cut_selected_patterns = function(_ENV)
    copy_selected_patterns(_ENV)

    for pat_id=sel_line_lower,sel_line_upper do
      if copied_patterns_is_full then
        patterns[pat_id+1] = make_pattern_widget(pat_id)
      else
        for col=sel_col_lower,sel_col_upper do
          patterns[pat_id+1].is_channel_activated[col+1] = false
        end
      end
    end

    store_all_patterns_in_mem(_ENV)

    send_pat_msg(_ENV, "cut ")
  end,

  paste_selected_patterns = function(_ENV)
    for i=1,#copied_patterns do
      if cur_line + i-1 < 64 then
        local copied_pat = copied_patterns[i]

        if copied_patterns_is_full then
          poke4(get_pattern_mem_addr(cur_line + i-1), copied_pat)
          patterns[cur_line + i]:load_pattern_from_mem()
        else
          for j=1,min(4 - cur_col, #copied_pat) do
            patterns[cur_line+i]:set_col(cur_col + j, copied_pat[j])
          end
        end
      end
    end

    store_all_patterns_in_mem(_ENV)

    if #copied_patterns == 0 then
      send_msg "no copied pattern to paste"
    else
      send_pat_msg(_ENV, "pasted ")
    end
  end,

  store_all_patterns_in_mem = function(_ENV)
    for p in all(patterns) do
      p:store_pattern_in_mem()
    end
  end
}
