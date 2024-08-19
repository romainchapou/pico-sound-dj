sfx_editor = class:new {
  sfx_id = 0,

  init = function(_ENV, sfx_id)
    _ENV.sfx_id = sfx_id

    notes = {}

    -- 0 for the note panel, 1 for the settings panel
    panel_selection = 0

    settings_selection = 0

    note_selection = 0
    note_sub_selection = 0

    for i=1,32 do
      add(notes, make_note_widget())
    end

    last_edited_note = make_note_widget()
    last_edited_note.volume.value = 5
    last_edited_note.pitch.value = 24

    sfx_speed = make_named_input_widget("spd", 16, 1, 255, 4)

    sfx_loop_in   = make_named_input_widget("in",  0, 0, 63, 4)
    sfx_loop_out  = make_named_input_widget("out", 0, 0, 63, 4)

    sfx_noise  = make_named_input_widget("noiz", 0, 0, 1)
    sfx_buzz   = make_named_input_widget("buzz", 0, 0, 1)
    sfx_detune = make_named_input_widget("detu", 0, 0, 2)
    sfx_reverb = make_named_input_widget("revb", 0, 0, 2)
    sfx_dampen = make_named_input_widget("damp", 0, 0, 2)

    sfx_settings = {
      sfx_speed, sfx_loop_in, sfx_loop_out, sfx_noise, sfx_buzz, sfx_detune, sfx_reverb, sfx_dampen
    }

    load_sfx_from_memory(_ENV)
  end,

  update = function(_ENV)
    -- pane movement
    if btn(4, 1) then
      if btnp(0) then
        store_sfx_in_memory(_ENV)
        GLOBAL.current_pane = pattern_editor
      end

      return -- TODO start of selection mode should be handled here
    end

    -- play/pause on this sfx
    if btnp(5, 1) then
      if stat(46) ~= sfx_id then
        play_sfx(_ENV)
      else
        -- already playing, stop the playback
        sfx(sfx_id, -2)
      end
    end

    if btn(4) then
      if btnp(0) then panel_selection -= 1 end
      if btnp(1) then panel_selection += 1 end

      if btnp(2) then change_sfx(_ENV, sfx_id-1) end
      if btnp(3) then change_sfx(_ENV, sfx_id+1) end

      panel_selection = mid(0, panel_selection, 1)
    end

    if panel_selection == 0 then
      update_note_panel(_ENV)
    elseif panel_selection == 1 then
      update_settings_panel(_ENV)
    end
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

      notes[i]:draw(x, y, panel_selection == 0 and i-1 == note_selection, note_sub_selection)
      x += col_x_diff

      print(HEX_VALUES[i], x-9, y, (i-1)\4 % 2 == 0 and 7 or 6)

      notes[i+16]:draw(x, y, panel_selection == 0 and i+15 == note_selection, note_sub_selection)
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

  update_note_panel = function(_ENV)
    notes[note_selection+1]:update(note_sub_selection)

    if not btn(4) and not btn(5) then
      if btnp(0) then note_sub_selection -= 1 end
      if btnp(1) then note_sub_selection += 1 end

      -- move from one note column to the other
      if note_sub_selection < 0 and note_selection >= 16 then
        note_sub_selection = 3
        note_selection -= 16
      elseif note_sub_selection > 3 and note_selection < 16 then
        note_sub_selection = 0
        note_selection += 16
      elseif note_sub_selection > 3 and note_selection >= 16 then
        panel_selection = 1
      end

      note_sub_selection = mid(0, note_sub_selection, 3)

      if btnp(2) then note_selection -= 1 end
      if btnp(3) then note_selection += 1 end
    end

    note_selection = mid(0, note_selection, 31)
  end,

  update_settings_panel = function(_ENV)
    local cur_setting_widget = sfx_settings[settings_selection+1]
    local old_setting_value = cur_setting_widget.value

    cur_setting_widget:update()

    if cur_setting_widget.value ~= old_setting_value then
      store_sfx_in_memory(_ENV)
    end

    if not btn(4) and not btn(5) then
      if btnp(0) then panel_selection = 0 end

      if btnp(2) then settings_selection -= 1 end
      if btnp(3) then settings_selection += 1 end

      settings_selection = mid(0, settings_selection, #sfx_settings-1)
    end
  end,

  play_sfx = function(_ENV)
    store_sfx_in_memory(_ENV)
    sfx(sfx_editor.sfx_id, 0)
  end,

  change_sfx = function(_ENV, new_sfx_id)
    new_sfx_id = mid(0, new_sfx_id, 63)

    if new_sfx_id == sfx_id then return end

    store_sfx_in_memory(_ENV)
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

    byte += 1 -- TODO beware that we may not want to override the editor mode
    byte += shl(sfx_noise.value, 1)
    byte += shl(sfx_buzz.value, 2)
    byte += sfx_detune.value * 8
    byte += sfx_reverb.value * 24
    byte += sfx_dampen.value * 72
    poke(sfxaddr, byte)

    sfxaddr += 1
    poke(sfxaddr, sfx_speed.value)

    sfxaddr += 1
    poke(sfxaddr, sfx_loop_in.value)

    sfxaddr += 1
    poke(sfxaddr, sfx_loop_out.value)
  end,
}
