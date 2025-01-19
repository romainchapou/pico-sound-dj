function make_sfx_widg(sfx_id)
  sfx_settings[sfx_id+1]:load_from_mem()

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

    update = function(_ENV, parameter_id)
      sfx_settings[sfx_id+1].widgets[parameter_id]:update()

      if not sfx_overview.multi_selection and btn(BTN_B) and btnp_once(BTN_A) then
        sfx_overview:cut_selected_sfx()
      end

      sfx_settings[sfx_id+1]:store_in_mem(false)
    end,

    clear = function(_ENV)
      reload(sfx_addr, sfx_addr, 68)
      is_empty = true
      sfx_settings[sfx_id+1]:load_from_mem()
    end,

    draw = function(_ENV, is_selected, show_setting_value, parameter_id)
      local x, y = 5 + (sfx_id % 8)*15, 28 + (sfx_id\8) * 11

      -- TODO funny but not great
      if not stat(57) and stat(46) == sfx_id then
        y += sin(time()) + 0.5
      end

      local ret_func = is_empty and rect or rectfill

      local txt_color = 0
      if is_empty then
        if is_selected then
          txt_color = show_setting_value and 7 or 9
        elseif show_setting_value then
          txt_color = 7
        else
          txt_color = 6
        end
      end

      local bg_color = is_selected and sfx_overview.panel_selection == 2 and 9 or 6

      ret_func(x, y, x+12, y+8, bg_color)

      if show_setting_value then
        rectfill(x-1, y+1, x+13, y+7, bg_color)
      end

      local v_to_print = show_setting_value and sfx_settings[sfx_id+1].widgets[parameter_id].value
                         or two_digit_number_str(sfx_id)

      print_centered(v_to_print, x+6, y+2, txt_color)
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

    for sfx_id=0,63 do
      add(sfx_widgets, make_sfx_widg(sfx_id))
    end
  end,

  update = function(_ENV)
    -- panes movements
    if handle_move_pane(1) or handle_move_pane(-1) or handle_move_pane(1, true) then
      return
    end

    if panel_selection == 1 then
      parameter_select_widg:update()

      if no_action_button() and btnp "3" then
        panel_selection = 2
      end

      return
    end

    -- only check if in lower panel (sfx widgets may be modified)
    check_if_modification()

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
        cut_selected_sfx(_ENV)
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
      sfx_widgets[s_id+1]:update(parameter_select_widg.value)
    end

    if btn(BTN_A) and btnp() & 0b1111 ~= 0 then
      send_msg("changed " .. SFX_PARAMS[parameter_select_widg.value] ..
               " for sfx " .. format_select_range(_ENV), false)
    end
  end,

  format_select_range = function(_ENV)
    return sel_lower == sel_upper and sel_lower or (tostring(sel_lower) .. "-" .. tostring(sel_upper))
  end,

  cut_selected_sfx = function(_ENV)
    copy_selected_sfx(_ENV)
    for s_id=sel_lower,sel_upper do
      sfx_widgets[s_id+1]:clear()
    end
    send_msg("cut " .. sel_upper - sel_lower + 1 .. " sfx (" .. format_select_range(_ENV) .. ")")
  end,

  copy_selected_sfx = function(_ENV)
    nb_copied_sfx = sel_upper - sel_lower + 1
    copied_sfx = pack(peek(0x3200 + 68*sel_lower, 68*nb_copied_sfx))
    current_sfx = sel_lower
    multi_selection = false
    send_msg("copied " .. nb_copied_sfx .. " sfx (" .. format_select_range(_ENV) .. ")")
  end,

  draw = function(_ENV)
    shadow_print("sfx overview", 1, 1)

    parameter_select_widg:draw(2, 12, panel_selection == 1 or btn(BTN_A))

    for w in all(sfx_widgets) do
      local is_in_selection = panel_selection == 2 and is_in_range(w.sfx_id, sel_lower, sel_upper)

      w:draw(is_in_selection,
             btn(BTN_A) and (is_in_selection or panel_selection == 1),
             parameter_select_widg.value)
    end
  end
}
