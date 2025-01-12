function make_last_edited_note()
  local note = make_note_widget()
  note.volume(5)
  note.pitch(24) -- C2

  return note
end

sfx_editor = class:new {
  sfx_id = 0,
  copied_notes = {},
  whole_copy = {},
  last_edited_note = make_last_edited_note(),

  init = function(_ENV, sfx_id)
    _ENV.sfx_id = sfx_id
    sfx_addr = 0x3200 + 68*sfx_id

    waveform_edit_mode = false

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
      local old_waveform_edit_mode = sfx_editor.waveform_edit_mode

      sfx_editor.waveform_edit_mode = not old_waveform_edit_mode
      sfx_editor:store_sfx_in_memory(old_waveform_edit_mode)
      sfx_editor:load_sfx_from_memory()

      if not old_waveform_edit_mode then
        -- entering waveform edit mode, reset the bass value
        wave_do_bass(0)
      end
    end)

    wave_do_bass = make_named_input_widget("bass", 0, 0, 1)
    wave_zoom    = make_named_input_widget("zoom", 1, 1, 3)

    sfx_speed = make_named_input_widget("spd", 16, 1, 255, 4)

    sfx_loop_in   = make_named_input_widget("in",  0, 0, 63, 8)
    sfx_loop_out  = make_named_input_widget("out", 0, 0, 63, 8)

    sfx_noise     = make_named_input_widget("noiz", 0, 0, 1)
    sfx_buzz      = make_named_input_widget("buzz", 0, 0, 1)
    sfx_detune    = make_named_input_widget("detu", 0, 0, 2)
    sfx_reverb    = make_named_input_widget("revb", 0, 0, 2)
    sfx_dampen    = make_named_input_widget("damp", 0, 0, 2)
    sfx_edit_mode = make_named_input_widget("edtm", 1, 0, 1)

    n_sfx_settings = {
      sfx_speed, sfx_loop_in, sfx_loop_out, sfx_noise,
      sfx_buzz, sfx_detune, sfx_reverb, sfx_dampen, sfx_edit_mode
    }

    w_sfx_settings_top = {
      wave_zoom, wave_do_bass, waveform_edit_btn
    }

    w_sfx_settings_bottom = {
      sfx_noise, sfx_buzz, sfx_detune,
      sfx_reverb, sfx_dampen, sfx_edit_mode
    }

    if sfx_id < 8 then
      add(n_sfx_settings, waveform_edit_btn)
    end

    load_sfx_from_memory(_ENV)
  end,

  update = function(_ENV)
    check_if_modification()

    -- pane movement
    if btn(BTN_B) then
      if handle_move_pane(-1) then
        restore_neighbour_sfx(_ENV)
        sfx_overview:init()
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

    if waveform_edit_mode then
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
    store_sfx_in_memory(_ENV, waveform_edit_mode)
  end,

  draw = function(_ENV)
    local extra_txt = waveform_edit_mode and " -- waveform" or ""
    shadow_print("sfx " .. two_digit_number_str(sfx_id) .. extra_txt, 1, 1)

    if waveform_edit_mode then
      draw_waveform_editor(_ENV)
    else
      draw_note_editor(_ENV)
    end
  end,

  post_draw = function(_ENV)
    if waveform_edit_mode then
      rectfill(0, 112, 128, 128, 7)

      for i=1,6 do
        local b = bool_to_num(i>3)
        w_sfx_settings_bottom[i]:draw(i*40 - 28 - 120*b, 113 + 7*b,
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
    if not btn(BTN_B) and not btn(BTN_A) then
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

      w_sfx_settings_bottom[w_bottom_settings_selection]:update()
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

    local cur_setting_widget = n_sfx_settings[n_settings_selection+1]
    local old_setting_value = cur_setting_widget.value

    cur_setting_widget:update()

    if not btn(BTN_B) and not btn(BTN_A) then
      if btnp "0" then n_panel_selection = 0 end

      n_settings_selection = mid(0, n_settings_selection + nudge(true), #n_sfx_settings-1)
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
    if waveform_edit_mode then
      local waveform_preview = make_note_widget()
      waveform_preview.pitch(24)
      waveform_preview.waveform(8 + sfx_id)
      waveform_preview.volume(5)

      local saved_speed = sfx_speed.value
      sfx_speed(32)
      waveform_preview:play_note_preview()
      sfx_speed(saved_speed)

      return
    end

    sfx(sfx_editor.sfx_id, 0, btn(BTN_B) and n_current_note-1 or 0)
  end,

  change_sfx = function(_ENV, new_sfx_id)
    n_multi_selection = false
    new_sfx_id = mid(0, new_sfx_id, 63)

    if new_sfx_id == sfx_id then return end

    restore_neighbour_sfx(_ENV)

    init(_ENV, new_sfx_id)
  end,

  restore_neighbour_sfx = function(_ENV)
    memcpy(0x3200+68*neighbour_sfx_id, 0x4300, 68)
  end,

  -- IO / memory synchronisation

  store_sfx_settings = function(_ENV, addr, store_waveform)
    -- editor mode and filter switches
    poke(addr, sfx_edit_mode.value
               + shl(sfx_noise.value, 1)
               + shl(sfx_buzz.value, 2)
               + sfx_detune.value * 8
               + sfx_reverb.value * 24
               + sfx_dampen.value * 72)

    poke(addr+1, store_waveform and (sfx_speed.value & 0b11111110)
                 + wave_do_bass.value or sfx_speed.value)
  end,

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

    store_sfx_settings(_ENV, sfxaddr, store_waveform)

    poke(sfxaddr+2, sfx_loop_in.value + bool_to_num(waveform_edit_mode)*128)
    poke(sfxaddr+3, sfx_loop_out.value)
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

    -- following byte, editor mode and filter switches
    local byte = @sfxaddr
    sfx_edit_mode(byte & 1)
    sfx_noise(shr(byte, 1) & 1)
    sfx_buzz(shr(byte, 2) & 1)
    sfx_detune(byte\8  % 3)
    sfx_reverb(byte\24 % 3)
    sfx_dampen(byte\72 % 3)

    wave_do_bass(peek(sfxaddr+1) & 0b00000001)
    waveform_edit_mode = (peek(sfxaddr+2) & 0b10000000) == 128

    sfx_speed(peek(sfxaddr+1))
    sfx_loop_in(peek(sfxaddr+2) & 0b01111111)
    sfx_loop_out(peek(sfxaddr+3))
  end,

  -- draw functions

  draw_note_editor = function(_ENV)
    local start_x, start_y, col_x_diff = 10, 14, 48

    for i=0,1 do
      rectfill(start_x + i*col_x_diff - 10, start_y - 3, start_x + i*col_x_diff - 6, start_y + 3, 6)

      print(i,   start_x -  9 + i*col_x_diff, start_y - 2, 7)
      print("♪", start_x +  2 + i*col_x_diff, start_y - 2, 6)
      print("i", start_x + 18 + i*col_x_diff, start_y - 2, 6)
      print("v", start_x + 24 + i*col_x_diff, start_y - 2, 6)
      print("e", start_x + 30 + i*col_x_diff, start_y - 2, 6) -- TODO maybe "f"

      fillp(0b01011010.1)
      line(start_x + 16 + i*col_x_diff -2, start_y + 5,
           start_x + 16 + i*col_x_diff -2, start_y + 101, 6)
      fillp()
    end

    rectfill(start_x-10, start_y+6,  start_x-6, start_y+28, 9)
    rectfill(start_x-10, start_y+54, start_x-6, start_y+76, 9)

    rectfill(start_x-10+col_x_diff, start_y+6,  start_x-6+col_x_diff, start_y+28, 9)
    rectfill(start_x-10+col_x_diff, start_y+54, start_x-6+col_x_diff, start_y+76, 9)

    local test_next_note_has_slide = function(note_id)
      local n = notes[note_id+1]
      return n and n.effect.value == 1 and n.volume.value > 0
    end

    local is_note_highlighted = function(note_id)
      return n_panel_selection == 0 and
          note_id >= n_selection_lower and
          note_id <= n_selection_upper
    end

    -- draw the notes
    for i=1,16 do
      local x, y = start_x, start_y + i*6

      print(HEX_VALUES[i], x-9, y, (i-1)\4 % 2 == 0 and 7 or 6)

      notes[i]:draw(x, y, is_note_highlighted(i), n_sub_selection, test_next_note_has_slide(i))
      x += col_x_diff

      print(HEX_VALUES[i], x-9, y, (i-1)\4 % 2 == 0 and 7 or 6)

      local note_id = i+16
      notes[note_id]:draw(x, y, is_note_highlighted(note_id), n_sub_selection, test_next_note_has_slide(note_id))
    end

    -- draw the playhead
    for i=0,3 do
      local note_nb = stat(50+i)

      if stat(46+i) == sfx_id and note_nb >= 0 then
        spr(1, start_x - 4 + note_nb\16 * col_x_diff, start_y + 6 + note_nb%16 * 6)
      end
    end

    local function setting_selected(i)
      return n_panel_selection == 1 and n_settings_selection == i
    end

    -- draw the settings
    sfx_speed:draw(start_x + 89, start_y - 2, setting_selected(0))

    print("-loop-", start_x + 89, start_y + 10, 6)

    sfx_loop_in:draw(start_x + 93, start_y + 16, setting_selected(1))
    sfx_loop_out:draw(start_x + 89, start_y + 22, setting_selected(2))

    for i=4,9 do
      n_sfx_settings[i]:draw(start_x + 89, start_y + 10 + i*6, setting_selected(i-1))
    end

    if sfx_id < 8 then
      print("edit as\n wave:", start_x + 89, start_y + 76, setting_selected(9) and 0 or 6)

      waveform_edit_btn:draw(start_x + 99, start_y + 89, setting_selected(9))
    end
  end,

  draw_waveform_editor = function(_ENV)
    function is_top_selected(i)
      return w_panel_selection == 0 and w_top_settings_selection == i
    end

    wave_zoom:draw(2, 11, is_top_selected(1))
    wave_do_bass:draw(31, 11, is_top_selected(2))
    waveform_edit_btn:draw(117, 11, is_top_selected(3))

    print("edit as notes:", 60, 11, is_top_selected(3) and 0 or 6)

    local editor_cursor_color = w_panel_selection == 1 and 9 or 6

    clip(0, 21, 128, 87)

    for i=1,64 do
      local xpos = 2*(i-1)
      line(xpos, 64, xpos, 64+waveform_values[i] / wave_zoom.value,
           i == w_cur_col and editor_cursor_color or 6)

      if abs(waveform_values[i]) > 43*wave_zoom.value then
        pset(xpos, 64+sgn(waveform_values[i])*43, 0)
      end
    end

    local v = waveform_values[w_cur_col]

    local cur_x_pos, cur_y_pos = 2*(w_cur_col-1), 64+v/wave_zoom.value
    rect(cur_x_pos-1, cur_y_pos-1, cur_x_pos+1, cur_y_pos+1, editor_cursor_color)
    pset(cur_x_pos, cur_y_pos, 7)

    local print_str = tostr(v)

    if abs(v) > 43*wave_zoom.value and w_panel_selection == 1 then
      local px, py = cur_x_pos - #print_str*2+1, v <= 0 and 67 or 58
      px = mid(0, px, 129 - #print_str*4)
      rectfill(px-1, py-1, px + #print_str*4 - 1, py+5, 7)
      print(v, px, py, editor_cursor_color)
    end

    clip()

    fillp(0b0101101001011010.1)
    draw_horiz_line(18)
    draw_horiz_line(110)
    fillp()

    draw_horiz_line(19)
    draw_horiz_line(109)

    -- bottom settings done in post_draw to draw over the project file name
  end
}
