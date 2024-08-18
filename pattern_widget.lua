function make_pattern_widget()
  local channel_draw = function(_ENV, x, y, is_selected, is_activated)
    if is_selected then
      rectfill(x-2, y-1, x+8, y+5, 9)
    end

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
    channels = pattern_channels,
    is_channel_activated = {false, false, false, false},

    begin_loop = make_button_widget(2),
    endloop = make_button_widget(3),
    stop_at_end = make_button_widget(4),

    get_settings_widgets = function(_ENV)
      return {begin_loop, endloop, stop_at_end}
    end,

    update = function(_ENV, sub_selection)
      if sub_selection < #channels then
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

        channels[sub_selection+1]:update()
      else
        get_settings_widgets(_ENV)[sub_selection - #channels + 1]:update()
      end
    end,

    draw = function(_ENV, x, y, is_pattern_seleted, sub_selection)
      for i, c in ipairs(channels) do
        c:draw(x + CHANNEL_X_OFFSET*(i-1), y, is_pattern_seleted and sub_selection == i-1, is_channel_activated[i])
      end

      for i=4,6 do
        get_settings_widgets(_ENV)[i-#channels+1]:draw(x + 63 + (i-4)*8, y,
                                                       is_pattern_seleted and sub_selection == i)
      end
    end,
  }
end
