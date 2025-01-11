function make_pattern_widget(pattern_id)
  local channel_draw = function(_ENV, x, y, is_activated)
    if is_activated then
      print(two_digit_number_str(value), x, y, 0)
    else
      print("..", x, y-2, 0)
    end
  end

  local pattern_channels = {}

  for i=1,4 do
    add(pattern_channels, make_input_widget(0, 0, 63, 16, channel_draw))
  end

  return class:new {
    pattern_id = pattern_id,
    channels = pattern_channels,
    is_channel_activated = {false, false, false, false},

    begin_loop = make_button_widget(2),
    end_loop = make_button_widget(3),
    stop_at_end = make_button_widget(4),

    get_settings_widgets = function(_ENV)
      return {begin_loop, end_loop, stop_at_end}
    end,

    -- TODO sub_selection should be 0 based
    update = function(_ENV, sub_selection)
      if sub_selection < #channels then
        if not pattern_editor.multi_selection and btnp_once(BTN_A) then
          if btn(BTN_B) then
            -- TODO also copy the channel here (cut behaviour)
            is_channel_activated[sub_selection+1] = false
            pattern_editor.last_edited_pattern = channels[sub_selection+1].value
          else
            -- activate the channel
            if not is_channel_activated[sub_selection+1] then
              channels[sub_selection+1](pattern_editor.last_edited_pattern)
            end

            is_channel_activated[sub_selection+1] = true
          end
        end

        channels[sub_selection+1]:update()

        if btn(BTN_A) and is_channel_activated[sub_selection+1] then
          pattern_editor.last_edited_pattern = channels[sub_selection+1].value
        end

      elseif not pattern_editor.multi_selection then
        get_settings_widgets(_ENV)[sub_selection - #channels + 1]:update()
      end

      if btn() ~= 0 then
        store_pattern_in_mem(_ENV)
      end
    end,

    draw = function(_ENV, x, y, is_pattern_seleted, col_sel_start, col_sel_end)
      -- hack: not letting each channel widget handle the visualisation of it
      -- being selected, instead do it here so we can have one continuous
      -- rectangle
      if is_pattern_seleted and col_sel_start < 4 then
        local start_x, end_x =
          col_sel_end == 4 and 0 or col_sel_start*CHANNEL_X_OFFSET,
          col_sel_end == 4 and 76 or col_sel_end*CHANNEL_X_OFFSET

        rectfill(x + start_x - 2, y-1, x + end_x + 8, y+5, 9)
      end

      for i, c in ipairs(channels) do
        c:draw(x + CHANNEL_X_OFFSET*(i-1), y,
               -- is_pattern_seleted and is_in_range(i-1, col_sel_start, col_sel_end),
               is_channel_activated[i])
      end

      for i=4,6 do
        get_settings_widgets(_ENV)[i-#channels+1]
        :draw(x + 63 + (i-4)*8, y, is_pattern_seleted
        and is_in_range(i, col_sel_start, col_sel_end))
      end
    end,

    store_pattern_in_mem = function(_ENV)
      for i=1,4 do
        poke(get_pattern_mem_addr(pattern_id)+i-1,
             channels[i].value
             + 64 * bool_to_num(not is_channel_activated[i])
             + 128*bool_to_num(i ~= 4 and get_settings_widgets(_ENV)[i].state)) -- will be false for i == 4
      end
    end,

    get_col = function(_ENV, i)
      return channels[i].value, is_channel_activated[i]
    end,

    set_col = function(_ENV, i, val_and_active)
      channels[i].value, is_channel_activated[i] = unpack(val_and_active)
    end,

    load_pattern_from_mem = function(_ENV)
      local addr = get_pattern_mem_addr(pattern_id)

      for i=1,4 do
        local byte = @(addr + i - 1)
        channels[i](byte & 0b00111111)
        is_channel_activated[i] = byte & 0b01000000 == 0

        if i <= 3 then
          get_settings_widgets(_ENV)[i].state = byte & 0b10000000 > 0
        end
      end
    end
  }
end

function get_pattern_mem_addr(pat_id)
  return 0x3100 + pat_id*4
end
