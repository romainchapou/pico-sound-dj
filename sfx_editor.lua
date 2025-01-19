function make_last_edited_note()
  local note = make_note_widget()
  note.volume(5)
  note.pitch(24) -- C2

  return note
end

sfx_editor = class:new {
  copied_notes = {},
  whole_copy = {},
  last_edited_note = make_last_edited_note(),

  init = function(_ENV)
    sfx_id = sfx_overview.current_sfx
    sfx_addr = 0x3200 + 68*sfx_id

    this_sfx_settings = sfx_settings[sfx_id+1]

    settings_widgets = {}
    for w in all(this_sfx_settings.widgets) do
      add(settings_widgets, w)
    end

    -- save the neighbour sfx data as we will be using it to play note previews
    -- we will need to restore this data when quitting this sfx
    neighbour_sfx_id = max((sfx_id+1)%64, 8)
    memcpy(0x4300, 0x3200+68*neighbour_sfx_id, 68)

    ----- regular note editing mode params -----

    -- 0 for the note panel, 1 for the settings panel
    n_panel_selection = 0

    n_settings_selection = 0

    n_multi_selection = false

    n_current_note = 1
    n_selection_start = 1

    n_selection_upper = 1
    n_selection_lower = 1

    n_sub_selection = 1

    notes = {}


    ----- waveform editing mode params -----

    waveform_values = {}

    w_panel_selection = 1
    w_top_settings_selection = 1
    w_bottom_settings_col = 1
    w_bottom_settings_selection = 1

    w_cur_col = 32


    ----- settings widgets, mostly shared between the two modes -----

    waveform_edit_btn = make_btn_pushed_widget("∧", function()
      local old_waveform_edit_mode = this_sfx_settings.waveform_edit_mode

      this_sfx_settings.waveform_edit_mode = not old_waveform_edit_mode
      sfx_editor:store_sfx_in_memory(old_waveform_edit_mode)
      sfx_editor:load_sfx_from_memory()

      if not old_waveform_edit_mode then
        -- entering waveform edit mode, reset the bass value
        this_sfx_settings.wave_do_bass(0)
      end
    end)

    wave_zoom    = make_named_input_widget("zoom", 1, 1, 3)

    w_sfx_settings_top = {
      wave_zoom, this_sfx_settings.wave_do_bass, waveform_edit_btn
    }

    if sfx_id < 8 then
      add(settings_widgets, waveform_edit_btn)
    end

    load_sfx_from_memory(_ENV)
  end,

  update = function(_ENV)
    check_if_modification()

    -- pane movement
    if btn(BTN_B) then
      if handle_move_pane(-1) then
        restore_neighbour_sfx(_ENV)
        return
      end

      if btnp "2" then change_sfx(_ENV, sfx_id-1) end
      if btnp "3" then change_sfx(_ENV, sfx_id+1) end
    end

    -- play/pause on this sfx
    if btnp_once(6) and not btn(BTN_A) then
      if is_sound_playing() then
        stop_all_sounds()
      else
        play_sfx(_ENV)
      end

      return
    end

    if this_sfx_settings.waveform_edit_mode then
      update_waveform(_ENV)
    else
      if n_panel_selection == 0 then
        update_note_panel(_ENV)
      elseif n_panel_selection == 1 then
        update_settings_panel(_ENV)
      end
    end

    -- sync the RAM representation with ours every frame.
    -- not the most efficient but simpler than the alternative
    store_sfx_in_memory(_ENV, this_sfx_settings.waveform_edit_mode)
  end,

  draw = function(_ENV)
    local extra_txt = this_sfx_settings.waveform_edit_mode and " -- waveform" or ""
    shadow_print("sfx " .. two_digit_number_str(sfx_id) .. extra_txt, 1, 1)

    if this_sfx_settings.waveform_edit_mode then
      draw_waveform_editor(_ENV)
    else
      draw_note_editor(_ENV)
    end
  end,

  post_draw = function(_ENV)
    if this_sfx_settings.waveform_edit_mode then
      rectfill(0, 110, 128, 128, 7)

      for i=1,6 do
        local b = bool_to_num(i>3)
        -- bottom settings for wave edition (noise to edit mode)
        settings_widgets[i+3]:draw(i*33 - 28 - 99*b, 113 + 7*b,
                                   w_panel_selection >= 2 and
                                   w_bottom_settings_selection == i)
      end
    end
  end,

  -- update functions

  post_update = function(_ENV)
    if n_multi_selection then
      n_selection_upper = max(n_selection_start, n_current_note)
      n_selection_lower = min(n_selection_start, n_current_note)
    else
      n_selection_start = n_current_note
      n_selection_upper = n_current_note
      n_selection_lower = n_current_note
    end
  end,

  update_note_panel = function(_ENV)
    if btnp_once(6) and btn(BTN_A) and not n_multi_selection then
      paste_selection(_ENV)
      notes[n_current_note]:play_note_preview()

      return
    end

    -- sel modifier
    if not n_multi_selection then
      if btn_double_press(BTN_B) then
        n_multi_selection = true
        send_msg "select mode"
        return
      end
    else
      if btnp_once(BTN_B) then
        copy_selected_notes(_ENV)
        return
      elseif btn_double_press(BTN_A) then
        cut_selected_notes(_ENV)
        return
      end
    end

    -- moving the cursor around
    if no_action_button() then
      n_sub_selection += nudge()
      n_current_note += nudge(true)

      -- TODO see if we can handle the n_multi_selection case better
      if not n_multi_selection then
        -- move from one note column to the other
        if n_sub_selection < 1 and n_current_note > 16 then
          n_sub_selection = 4
          n_current_note -= 16
        elseif n_sub_selection > 4 and n_current_note <= 16 then
          n_sub_selection = 1
          n_current_note += 16
        elseif n_sub_selection > 4 and n_current_note > 16 then
          n_panel_selection = 1
        end
      end

      n_sub_selection = mid(1, n_sub_selection, 4)
    end

    n_current_note = (n_current_note-1)%32+1

    post_update(_ENV)

    local are_all_selected_notes_volume_0 = true
    for i=n_selection_lower,n_selection_upper do
      if notes[i].volume.value ~= 0 then
        are_all_selected_notes_volume_0 = false
        break
      end
    end

    -- update each selected note widget
    for i=n_selection_lower,n_selection_upper do
      notes[i]:update(n_sub_selection, are_all_selected_notes_volume_0)
    end
  end,

  update_waveform = function(_ENV)
    if btn(BTN_B) then return end

    if not btn(BTN_A) then
      w_panel_selection = mid(0, w_panel_selection + nudge(true), 3)
    end

    if w_panel_selection == 0 then
      if not btn(BTN_A) then
        w_top_settings_selection = mid(1, w_top_settings_selection + nudge(), 3)
      end

      w_sfx_settings_top[w_top_settings_selection]:update()

    elseif w_panel_selection == 1 then
      -- actual waveform update
      local id_to_change = mid(1, w_cur_col + nudge(), 64)

      if btn(BTN_A) then
        waveform_values[id_to_change] = mid(-128,
                                            waveform_values[w_cur_col] + nudge(true),
                                            127)
      end

      w_cur_col = id_to_change
    else
      if not btn(BTN_A) then
        w_bottom_settings_col = mid(1, w_bottom_settings_col + nudge(), 3)
      end

      w_bottom_settings_selection = w_bottom_settings_col + (w_panel_selection == 3 and 3 or 0)

      -- bottom settings for wave edition (noise to edit mode)
      settings_widgets[w_bottom_settings_selection+3]:update()
    end
  end,

  update_settings_panel = function(_ENV)
    if btnp_once(6) and btn(BTN_A) and #whole_copy ~= 0 then
      paste_selection(_ENV)
      return
    end

    if btn_double_press(BTN_B) then
      copy_whole_sfx(_ENV)
      return
    end

    settings_widgets[n_settings_selection+1]:update()

    if no_action_button() then
      if btnp "0" then n_panel_selection = 0 end

      n_settings_selection = mid(0, n_settings_selection + nudge(true), #settings_widgets-1)
    end
  end,

  send_notes_msg = function(_ENV, act)
    send_msg(act .. #copied_notes .. " note" .. s_if_plural(copied_notes))
  end,

  copy_selected_notes = function(_ENV)
    whole_copy = {}
    copied_notes = {}

    for i=n_selection_lower,n_selection_upper do
      add(copied_notes, copy_note(notes[i]))
    end
    n_current_note = n_selection_lower
    n_multi_selection = false

    send_notes_msg(_ENV, "copied ")
  end,

  cut_selected_notes = function(_ENV)
    copy_selected_notes(_ENV)
    -- n_multi_selection is false after the copy, but the note selection
    -- lower and upper are not yet reset
    for i=n_selection_lower,n_selection_upper do
      notes[i].volume(0)
    end

    send_notes_msg(_ENV, "cut ")
  end,

  paste_selection = function(_ENV)
    if #whole_copy ~= 0 then
      poke(sfx_addr, unpack(whole_copy))
      load_sfx_from_memory(_ENV)

      send_msg "pasted whole sfx"
    else
      local max_note = min(n_current_note+#copied_notes-1,32)

      for i=n_current_note,max_note do
        notes[i] = copy_note(copied_notes[i-n_current_note+1])
      end

      send_msg("pasted " .. max_note - n_current_note + 1 .. " note" .. s_if_plural(max_note))
    end
  end,

  copy_whole_sfx = function(_ENV)
    whole_copy = {}
    copied_notes = {}

    whole_copy = pack(peek(sfx_addr, 68))

    send_msg "copied whole sfx"
  end,

  play_sfx = function(_ENV)
    if this_sfx_settings.waveform_edit_mode then
      local waveform_preview = make_note_widget()
      waveform_preview.pitch(24)
      waveform_preview.waveform(8 + sfx_id)
      waveform_preview.volume(5)

      local saved_speed = this_sfx_settings.speed.value
      this_sfx_settings.speed(32)
      waveform_preview:play_note_preview()
      this_sfx_settings.speed(saved_speed)

      return
    end

    sfx(sfx_editor.sfx_id, 0, btn(BTN_B) and n_current_note-1 or 0)
  end,

  change_sfx = function(_ENV, new_sfx_id)
    n_multi_selection = false
    new_sfx_id = mid(0, new_sfx_id, 63)

    if new_sfx_id == sfx_id then return end

    restore_neighbour_sfx(_ENV)

    sfx_overview.current_sfx = new_sfx_id
    init(_ENV)
  end,

  restore_neighbour_sfx = function(_ENV)
    memcpy(0x3200+68*neighbour_sfx_id, 0x4300, 68)
    sfx_settings[neighbour_sfx_id+1]:load_from_mem()
  end,

  -- IO / memory synchronisation

  store_sfx_in_memory = function(_ENV, store_waveform)
    -- compute address of sfx
    local sfxaddr = sfx_addr

    for i=0,31 do
      if store_waveform then
        for j=0,1 do
          local v = waveform_values[2*i+j+1]
          poke(sfxaddr+j, v < 0 and v + 256 or v)
        end
      else
        notes[i+1]:store_in_mem(sfxaddr)
      end
      sfxaddr += 2
    end

    sfx_settings[sfx_id+1]:store_in_mem(store_waveform, sfxaddr)
  end,

  load_sfx_from_memory = function(_ENV)
    local sfxaddr = sfx_addr

    waveform_values = {}
    notes = {}

    for i=1,32 do
      add(notes, make_note_widget())
      notes[i]:load_from_mem(sfxaddr)

      for j=0,1 do
        local v = peek(sfxaddr+j)
        add(waveform_values, v > 127 and v - 256 or v)
      end

      sfxaddr += 2
    end

    sfx_settings[sfx_id+1]:load_from_mem()
  end,

  -- draw functions

  draw_note_editor = function(_ENV)
    local start_x, start_y, col_x_diff = 10, 14, 48

    for i=0,1 do
      local left_x = start_x + i*col_x_diff

      spr(11+i, left_x - 10, start_y - 3)

      for inst in all(split "♪:2,i:18,v:24,e:30") do
        local str, v = unpack(split(inst, ":"))
        print(str, left_x + tonum(v), start_y - 2, 6)
      end

      fillp(0b01011010.1)
      line(left_x + 14, start_y + 5, left_x + 14, start_y + 101, 6)
      fillp()

      -- draw the note number column
      sspr(0, 8, 5, 95, left_x - 10, start_y+6)
    end

    -- draw the notes
    for i=0,31 do
      local note_id = i+1
      local next_note = notes[note_id+1]

      notes[note_id]:draw(start_x + (i\16)*col_x_diff, start_y + 6 + (i%16)*6,
                         -- test is note highlighted
                         n_panel_selection == 0 and note_id >= n_selection_lower
                                                and note_id <= n_selection_upper,
                         n_sub_selection,

                         -- test if next note has slide
                         next_note and next_note.effect.value == 1
                                   and next_note.volume.value > 0)
    end

    -- draw the playhead
    for ch_id=0,3 do
      local note_nb = stat(50+ch_id)

      if stat(46+ch_id) == sfx_id and note_nb >= 0 then
        spr(1, start_x - 4 + note_nb\16 * col_x_diff, start_y + 6 + note_nb%16 * 6)
      end
    end

    local function setting_selected(i)
      return n_panel_selection == 1 and n_settings_selection == tonum(i)
    end

    -- draw the settings
    this_sfx_settings.speed:draw(start_x + 89, start_y - 2, setting_selected "0")

    print("-loop-", start_x + 89, start_y + 9, 6)

    this_sfx_settings.loop_in:draw(start_x + 93, start_y + 15, setting_selected "1")
    this_sfx_settings.loop_out:draw(start_x + 89, start_y + 21, setting_selected "2")

    for i=4,9 do
      settings_widgets[i]:draw(start_x + 89, start_y + 8 + i*6, setting_selected(i-1))
    end

    if sfx_id < 8 then
      print("edit as\n wave:", start_x + 89, start_y + 73, setting_selected "9" and 0 or 6)

      waveform_edit_btn:draw(start_x + 99, start_y + 86, setting_selected "9")
    end
  end,

  draw_waveform_editor = function(_ENV)
    local start_y = -2

    function is_top_selected(i)
      return w_panel_selection == 0 and w_top_settings_selection == i
    end

    for i,x_pos in ipairs(split "2,31,117") do
      w_sfx_settings_top[i]:draw(tonum(x_pos), start_y + 11, is_top_selected(i))
    end

    print("edit as notes:", 60, start_y + 11, is_top_selected(3) and 0 or 6)

    local editor_cursor_color = w_panel_selection == 1 and 9 or 6

    clip(0, start_y + 21, 128, start_y + 87)

    for i=1,64 do
      local xpos = 2*(i-1)
      line(xpos, 64, xpos, 64+waveform_values[i] / wave_zoom.value,
           i == w_cur_col and editor_cursor_color or 6)

      if abs(waveform_values[i]) > 43*wave_zoom.value then
        pset(xpos, start_y + 64+sgn(waveform_values[i])*43, 0)
      end
    end

    local v = waveform_values[w_cur_col]

    local cur_x_pos, cur_y_pos = 2*(w_cur_col-1), 64+v/wave_zoom.value
    rect(cur_x_pos-1, start_y + cur_y_pos-1, cur_x_pos+1, start_y + cur_y_pos+1, editor_cursor_color)
    pset(cur_x_pos, start_y + cur_y_pos, 7)

    local print_str = tostr(v)

    if abs(v) > 43*wave_zoom.value and w_panel_selection == 1 then
      local px, py = cur_x_pos - #print_str*2+1, v <= 0 and 67 + start_y or 58 + start_y
      px = mid(0, px, 129 - #print_str*4)
      rectfill(px-1, py-1, px + #print_str*4 - 1, py+5, 7)
      print(v, px, py, editor_cursor_color)
    end

    clip()

    fillp(0b0101101001011010.1)
    draw_horiz_line(start_y + 18)
    draw_horiz_line(start_y + 110)
    fillp()

    draw_horiz_line(start_y + 19)
    draw_horiz_line(start_y + 109)

    -- bottom settings done in post_draw to draw over the project file name
  end
}
