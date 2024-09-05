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

    update = function(_ENV, sub_selection)
      if sub_selection < #channels then
        if not pattern_editor.multi_selection then
          if btn(4) then
            if btnp_once(5) then
              -- TODO also copy the channel here (cut behaviour)
              is_channel_activated[sub_selection+1] = false
            end
          else
            if btnp_once(5) then
              -- activate the channel
              is_channel_activated[sub_selection+1] = true
            end
          end
        end

        channels[sub_selection+1]:update()
      else
        get_settings_widgets(_ENV)[sub_selection - #channels + 1]:update()
      end

      if btn() & 0b101111~= 0 then
        store_pattern_in_mem(_ENV)
      end
    end,

    draw = function(_ENV, x, y, is_pattern_seleted, col_sel_start, col_sel_end)
      -- hack: not letting each channel widget handle the visualisation of it
      -- being selected, instead do it here so we can have one continuous
      -- rectangle
      if is_pattern_seleted and col_sel_start < 4 then
        rectfill(x + col_sel_start*CHANNEL_X_OFFSET - 2, y-1,
                 x + col_sel_end*CHANNEL_X_OFFSET   + 8, y+5, 9)
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
      local states = {begin_loop.state, end_loop.state, stop_at_end.state, false}

      for i=1,4 do
        poke(get_pattern_mem_addr(pattern_id)+i-1,
             channels[i].value
             + 64 * bool_to_num(not is_channel_activated[i])
             + 128*bool_to_num(states[i]))
      end
    end,

    load_pattern_from_mem = function(_ENV)
      local addr = get_pattern_mem_addr(pattern_id)

      for i=0,3 do
        local byte = peek(addr + i)
        channels[i+1].value = byte & 0b00111111
        is_channel_activated[i+1] = (byte & 0b01000000) == 0
      end

      begin_loop.state = (peek(addr) & 0b10000000) > 0
      end_loop.state = (peek(addr+1) & 0b10000000) > 0
      stop_at_end.state = (peek(addr+2) & 0b10000000) > 0
    end
  }
end

function get_pattern_mem_addr(pat_id)
  return 0x3100 + pat_id*4
end
