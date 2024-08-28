function make_last_edited_note()
  local note = make_note_widget()
  note.volume.value = 5
  note.pitch.value = 24

  return note
end

sfx_editor = class:new {
  sfx_id = 0,
  copied_notes = {},
  last_edited_note = make_last_edited_note(),

  init = function(_ENV, sfx_id)
    _ENV.sfx_id = sfx_id

    -- 0 for the note panel, 1 for the settings panel
    panel_selection = 0

    settings_selection = 0

    multi_selection = false

    current_note = 1
    selection_start = 1

    selection_upper = 1
    selection_lower = 1

    sub_selection = 1

    sfx_speed = make_named_input_widget("spd", 16, 1, 255, 4)

    sfx_loop_in   = make_named_input_widget("in",  0, 0, 63, 8)
    sfx_loop_out  = make_named_input_widget("out", 0, 0, 63, 8)

    sfx_noise  = make_named_input_widget("noiz", 0, 0, 1)
    sfx_buzz   = make_named_input_widget("buzz", 0, 0, 1)
    sfx_detune = make_named_input_widget("detu", 0, 0, 2)
    sfx_reverb = make_named_input_widget("revb", 0, 0, 2)
    sfx_dampen = make_named_input_widget("damp", 0, 0, 2)

    sfx_settings = {
      sfx_speed, sfx_loop_in, sfx_loop_out, sfx_noise, sfx_buzz, sfx_detune, sfx_reverb, sfx_dampen
    }

    notes = {}
    load_sfx_from_memory(_ENV)
  end,

  update = function(_ENV)
    -- pane movement
    if btn(4, 1) and btnp(0) then
      GLOBAL.current_pane = pattern_editor
      return
    end

    -- play/pause on this sfx
    if btnp_once(5, 1) then
      if stat(46) ~= sfx_id then
        play_sfx(_ENV)
      else
        -- already playing, stop the playback
        sfx(sfx_id, -2)
      end
    end

    if not btn(4, 1) and btn(4) then
      if btnp(0) then panel_selection -= 1 end
      if btnp(1) then panel_selection += 1 end

      panel_selection = mid(0, panel_selection, 1)

      if btnp_once(2) then change_sfx(_ENV, sfx_id-1) end
      if btnp_once(3) then change_sfx(_ENV, sfx_id+1) end
    end

    if panel_selection == 0 then
      update_note_panel(_ENV)
    elseif panel_selection == 1 then
      update_settings_panel(_ENV)
    end

    -- sync the RAM representation with ours every frame.
    -- not the most efficient but simpler than the alternative
    store_sfx_in_memory(_ENV)
  end,

  draw = function(_ENV)
    print("sfx " .. two_digit_number_str(sfx_id), 1, 1, 6)

    local start_x, start_y, col_x_diff = 10, 12, 48

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

    -- draw the notes
    for i=1,16 do
      local x, y = start_x, start_y + i*6

      print(HEX_VALUES[i], x-9, y, (i-1)\4 % 2 == 0 and 7 or 6)

      notes[i]:draw(x, y, is_note_highlighted(_ENV, i), sub_selection)
      x += col_x_diff

      print(HEX_VALUES[i], x-9, y, (i-1)\4 % 2 == 0 and 7 or 6)

      notes[i+16]:draw(x, y, is_note_highlighted(_ENV, i+16), sub_selection)
    end

    -- draw the playhead
    if stat(46) == sfx_id and stat(50) >= 0 then
      palt(0, false)
      palt(14, true)
      spr(1, start_x - 4 + stat(50)\16 * col_x_diff, start_y + 6 + stat(50)%16 * 6)
      palt()
    end

    -- draw the settings
    sfx_speed:draw(start_x + 89, start_y + 6, panel_selection == 1 and settings_selection == 0)

    -- TODO : could be better to visualize in hex
    print("-loop-", start_x + 89, start_y + 18, 6)

    sfx_loop_in:draw(start_x + 93, start_y + 24, panel_selection == 1 and settings_selection == 1)
    sfx_loop_out:draw(start_x + 89, start_y + 30, panel_selection == 1 and settings_selection == 2)

    for i=4,#sfx_settings do
      sfx_settings[i]:draw(start_x + 89, start_y + 18 + i*6, panel_selection == 1 and i-1 == settings_selection)
    end
  end,

  -- update functions

  is_note_highlighted = function(_ENV, note_id)
    return panel_selection == 0 and
        note_id >= selection_lower and
        note_id <= selection_upper
  end,

  update_note_panel = function(_ENV)
    local upd_uppper_lower = function()
      if multi_selection then
        selection_upper = max(selection_start, current_note)
        selection_lower = min(selection_start, current_note)
      else
        selection_start = current_note
        selection_upper = current_note
        selection_lower = current_note
      end
    end

    -- sel modifier
    if btn(4, 1) then
      if btnp_once(4) then
        if not multi_selection then
          multi_selection = true
        else
          if selection_lower ~= 1 or selection_upper ~= 32 then
            -- second press of sel+b selects everything
            selection_start = 32
            current_note = 1
          else
            copy_selected_notes(_ENV)
          end
        end
      end

      if btnp_once(5) then
        if multi_selection then
          cut_selected_notes(_ENV)
        else
          paste_selected_notes(_ENV)
        end
      end

      upd_uppper_lower()

      return
    end

    if multi_selection and btnp_once(4) then
      copy_selected_notes(_ENV)
    end

    -- moving the cursor around
    if not btn(4) and not btn(5) then
      if btnp(0) then sub_selection -= 1 end
      if btnp(1) then sub_selection += 1 end

      if btnp(2) then current_note -= 1 end
      if btnp(3) then current_note += 1 end

      -- TODO see if we can handle the multi_selection case better
      if not multi_selection then
        -- move from one note column to the other
        if sub_selection < 1 and current_note > 16 then
          sub_selection = 4
          current_note -= 16
        elseif sub_selection > 4 and current_note <= 16 then
          sub_selection = 1
          current_note += 16
        elseif sub_selection > 4 and current_note > 16 then
          panel_selection = 1
        end
      end

      sub_selection = mid(1, sub_selection, 4)
    end

    current_note = mid(1, current_note, 32)

    upd_uppper_lower()

    -- update each selected note widget
    for i=selection_lower,selection_upper do
      notes[i]:update(sub_selection)
    end
  end,

  update_settings_panel = function(_ENV)
    -- sel modifier
    if btn(4, 1) then
      return
    end

    local cur_setting_widget = sfx_settings[settings_selection+1]
    local old_setting_value = cur_setting_widget.value

    cur_setting_widget:update()

    if not btn(4) and not btn(5) then
      if btnp(0) then panel_selection = 0 end

      if btnp(2) then settings_selection -= 1 end
      if btnp(3) then settings_selection += 1 end

      settings_selection = mid(0, settings_selection, #sfx_settings-1)
    end
  end,

  copy_selected_notes = function(_ENV)
    copied_notes = {}
    for i=selection_lower,selection_upper do
      add(copied_notes, copy_note(notes[i]))
    end
    multi_selection = false
  end,

  cut_selected_notes = function(_ENV)
    copy_selected_notes(_ENV)
    -- multi_selection is false after the copy, but the note selection
    -- lower and upper are not yet reset
    for i=selection_lower,selection_upper do
      notes[i].volume.value = 0
    end
  end,

  paste_selected_notes = function(_ENV)
    for i=current_note,min(current_note+#copied_notes-1,32) do
      notes[i] = copy_note(copied_notes[i-current_note+1])
    end
  end,

  play_sfx = function(_ENV)
    sfx(sfx_editor.sfx_id, 0, btn(4, 1) and current_note-1 or 0)
  end,

  change_sfx = function(_ENV, new_sfx_id)
    multi_selection = false
    new_sfx_id = mid(0, new_sfx_id, 63)

    if new_sfx_id == sfx_id then return end

    init(_ENV, new_sfx_id)
  end,

  -- IO / memory synchronisation

  store_sfx_settings = function(_ENV, addr)
    -- editor mode and filter switches
    local byte = 0
    byte += 1 -- TODO beware that we may not want to override the editor mode
    byte += shl(sfx_noise.value, 1)
    byte += shl(sfx_buzz.value, 2)
    byte += sfx_detune.value * 8
    byte += sfx_reverb.value * 24
    byte += sfx_dampen.value * 72
    poke(addr, byte)

    poke(addr+1, sfx_speed.value)
  end,

  store_sfx_in_memory = function(_ENV)
    -- compute address of sfx
    local sfxaddr = 0x3200 + 68*sfx_id

    for i=1,32 do
      notes[i]:store_in_mem(sfxaddr)
      sfxaddr += 2
    end

    store_sfx_settings(_ENV, sfxaddr)

    poke(sfxaddr+2, sfx_loop_in.value)
    poke(sfxaddr+3, sfx_loop_out.value)
  end,

  load_sfx_from_memory = function(_ENV)
    local sfxaddr = 0x3200 + 68*sfx_id

    for i=1,32 do
      add(notes, make_note_widget())
      notes[i]:load_from_mem(sfxaddr)
      sfxaddr += 2
    end

    -- following byte, editor mode and filter switches
    local byte = peek(sfxaddr)
    sfx_noise.value = shr(byte, 1) & 1
    sfx_buzz.value = shr(byte, 2) & 1
    sfx_detune.value = byte\8  % 3
    sfx_reverb.value = byte\24 % 3
    sfx_dampen.value = byte\72 % 3

    sfx_speed.value = peek(sfxaddr+1)
    sfx_loop_in.value = peek(sfxaddr+2)
    sfx_loop_out.value = peek(sfxaddr+3)
  end,
}
