function make_sfx_widg(sfx_id)
  local sfx_addr, empty = 0x3200+68*sfx_id, true

  for n=0,31 do
    if %(0x3200+68*sfx_id + n*2) & 0b0000111000000000 ~= 0 then
      empty = false
      break
    end
  end

  return class:new {
    sfx_id = sfx_id,
    is_empty = empty,

    update = function(_ENV)
      if btn(BTN_B) and btnp_once(BTN_A) then
        -- TODO remove this in favor of the multi selection cut
        reload(sfx_addr, sfx_addr, 68)
        is_empty = true
      end
    end,

    clear = function(_ENV)
      reload(sfx_addr, sfx_addr, 68)
      is_empty = true
    end,

    draw = function(_ENV, is_selected)
      local x, y = 5 + (sfx_id % 8)*15, 28 + (sfx_id\8) * 11

      -- TODO funny but not great
      if not stat(57) and stat(46) == sfx_id then
        y += sin(time()) + 0.5
      end

      local ret_func = is_empty and rect or rectfill

      ret_func(x, y, x+12, y+8, is_selected and 9 or 6)
      print(two_digit_number_str(sfx_id), x+3, y+2, is_empty and (is_selected and 9 or 6) or 0)
    end
  }
end

local SFX_PARAMS = split "speed,loop in,loop out,noiz,buzz,detune,reverb,dampen,edit mode"

sfx_overview = class:new {
  current_sfx = 0,
  sel_start = 0,
  sel_lower = 0,
  sel_upper = 0,
  multi_selection = false,
  copied_sfx = {},
  nb_copied_sfx = 0,
  parameter_select_widg = make_named_input_widget("param", 1, 1, #SFX_PARAMS, nil, nil, nil, SFX_PARAMS),
  panel_selection = 2,

  init = function(_ENV)
    sfx_widgets = {}

    value_widget = make_named_input_widget("value")

    for sfx_id=0,63 do
      add(sfx_widgets, make_sfx_widg(sfx_id))
    end
  end,

  get_current_param_value = function(_ENV)
    local param_name = SFX_PARAMS[parameter_select_widg.value]
    local sfxaddr = 0x3200 + 68*current_sfx + 64

    local byte = @sfxaddr

    if param_name == "speed" then
      return peek(sfxaddr+1)
    elseif param_name == "loop in" then
      return peek(sfxaddr+2) & 0b01111111
    elseif param_name == "loop out" then
      return peek(sfxaddr+3)
    elseif param_name == "noiz" then
      return shr(byte, 1) & 1
    elseif param_name == "buzz" then
      return shr(byte, 2) & 1
    elseif param_name == "detune" then
      return byte\8  % 3
    elseif param_name == "reverb" then
      return byte\24  % 3
    elseif param_name == "dampen" then
      return byte\72  % 3
    elseif param_name == "edit mode" then
      return byte & 1
    end
  end,

  update = function(_ENV)
    -- panes movements
    if handle_move_pane(1) or handle_move_pane(-1) or handle_move_pane(1, true) then
      return
    end

    value_widget(get_current_param_value(_ENV))

    if panel_selection == 1 then
      parameter_select_widg:update()

      if no_action_button() and btnp "3" then
        panel_selection = 2
      end

      return
    end

    if btnp_once(6) and not btn(BTN_A) then
      if is_sound_playing() then
        stop_all_sounds()
      else
        sfx(current_sfx)
      end

      return
    end

    if no_action_button() then
      if btnp "2" then
        if current_sfx >= 8 then
          current_sfx -= 8
        elseif not multi_selection then
          panel_selection = 1
          return
        end
      end
      if btnp "0" and current_sfx % 8 ~= 0 then current_sfx -= 1 end
      if btnp "1" and current_sfx % 8 ~= 7 then current_sfx += 1 end
      if btnp "3" and current_sfx <= 55 then current_sfx += 8 end

      current_sfx = mid(0, current_sfx, 63)
    end

    if multi_selection then
      sel_upper = max(sel_start, current_sfx)
      sel_lower = min(sel_start, current_sfx)

      if btnp_once(BTN_B) then
        copy_selected_sfx(_ENV)
        return
      end

      if btn_double_press(BTN_A) then
        -- cut the selection
        copy_selected_sfx(_ENV)
        for s_id=sel_lower,sel_upper do
          sfx_widgets[s_id+1]:clear()
        end
        send_msg("cut " .. sel_upper - sel_lower + 1 .. " sfx")
        return
      end
    else
      sel_start, sel_upper, sel_lower = current_sfx, current_sfx, current_sfx

      if btn_double_press(BTN_B) then
        multi_selection = true
        sel_start = current_sfx
        send_msg "select mode"
        return
      end

      if btn(BTN_A) and btnp_once(6) then
        -- paste the selection
        local i, max_sfx = 1, min(current_sfx+ nb_copied_sfx - 1, 63)
        for s_id=current_sfx,max_sfx do
          for j=0,67 do
            poke(0x3200 + 68*s_id + j, copied_sfx[i])
            i += 1
          end
        end

        send_msg("pasted " .. max_sfx - current_sfx + 1 .. " sfx")

        init(_ENV)
        return
      end
    end

    for s_id=sel_lower,sel_upper do
      sfx_widgets[s_id+1]:update()
    end
  end,

  copy_selected_sfx = function(_ENV)
    nb_copied_sfx = sel_upper - sel_lower + 1
    copied_sfx = pack(peek(0x3200 + 68*sel_lower, 68*nb_copied_sfx))
    current_sfx = sel_lower
    multi_selection = false
    send_msg("copied " .. nb_copied_sfx .. " sfx")
  end,

  draw = function(_ENV)
    shadow_print("sfx overview", 1, 1)

    parameter_select_widg:draw(2, 12, panel_selection == 1)

    value_widget:draw(2, 19, panel_selection == 2 and btn(BTN_A))
    -- print("value:" .. tostring(get_current_param_value(_ENV)), 2, 19, 0)

    for w in all(sfx_widgets) do
      w:draw(panel_selection == 2 and is_in_range(w.sfx_id, sel_lower, sel_upper))
    end
  end
}
