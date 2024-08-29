function make_note_widget()
  local pitch_draw_func = function(_ENV, x, y, is_selected, is_activated)
    if is_selected then
      rectfill(x-2, y-1, x+12, y+5, 9)
    end

    if is_activated then
      print(NOTE_NAMES[value % 12 + 1], x, y, 0)
      print(value \ 12, x+8, y, 0)
    else
      print("...", x, y-2, 0)
    end
  end

  local effect_draw_func = function(_ENV, x, y, is_selected, is_activated)
      if is_selected then
        rectfill(x-2, y-1, x+4, y+5, 9)
      end

      local do_print = value == 0 or not is_activated
      print(do_print and "." or value, x, y - (do_print and 2 or 0), 0)
  end

  return class:new {
    pitch    = make_input_widget(0, 0, 63, 12, pitch_draw_func),
    waveform = make_input_widget(0, 0, 7),  -- aka instrument
    volume   = make_input_widget(0, 0, 7),
    effect   = make_input_widget(0, 0, 7, nil, effect_draw_func),

    get_sub_widgets = function(_ENV)
      return {pitch, waveform, volume, effect}
    end,

    play_tmp_note = function(_ENV)
      -- TODO also maybe store the previous note for the correct playback of
      -- the slide effect
      -- TODO store not in sfx 63 but in the free memory and point to it for
      -- the playback to avoid overlaps -> not sure that this is possible

      -- no note preview when multi selection on
      if sfx_editor.multi_selection then
        return
      end

      local sfx_addr = 0x3200 + 68*63
      store_in_mem(_ENV, sfx_addr) -- store to first note of sfx 63
      sfx_editor:store_sfx_settings(sfx_addr + 64)
      sfx(63, 3, 0, 1)
    end,

    copy_values = function(_ENV, other_note)
      for i,e in ipairs(get_sub_widgets(_ENV)) do
        e.value = other_note:get_sub_widgets()[i].value
      end
    end,

    -- we assume that this note is selected
    update = function(_ENV, sub_selection, should_modify_if_no_volume)
      if volume.value == 0 and not should_modify_if_no_volume then
        return
      end

      if not sfx_editor.multi_selection then
        if btn(4) then
          if btnp_once(5) then
            -- cut the selection by copying its value to last_edited_note
            sfx_editor.last_edited_note = make_note_widget()
            sfx_editor.last_edited_note:copy_values(_ENV)

            volume.value = 0
          end

          return
        end

        -- single X press pastes the last edited note if on
        -- an empty note in the pitch colum
        if volume.value == 0 and sub_selection == 1 then
          if btnp_once(5) then
            copy_values(_ENV, sfx_editor.last_edited_note)

            if volume.value == 0 then
              volume.value = 5
            end
          end
        end
      end

      local sub_widget = get_sub_widgets(_ENV)[sub_selection]
      local old_value = sub_widget.value

      sub_widget:update()

      if sub_widget.value ~= old_value or btnp_once(5) then
        if stat(46) < 0 then
          play_tmp_note(_ENV)
        end
        sfx_editor.last_edited_note = _ENV
      end
    end,

    draw = function(_ENV, x, y, is_note_selected, sub_selection)
      for i=1,4 do
        get_sub_widgets(_ENV)[i]:draw(x + (i > 1 and 6+i*6 or 0), y,
                                      is_note_selected and sub_selection == i,
                                      volume.value > 0)
      end
    end,

    store_in_mem = function(_ENV, addr)
      local v = 0
      v += pitch.value
      v += shl(waveform.value, 6)
      v += shl(volume.value, 9)
      v += shl(effect.value, 12)
      -- TODO purposefully letting the custom instrument byte be 0

      poke2(addr, v)
    end,

    load_from_mem = function(_ENV, addr)
      local data = peek2(addr)

      pitch.value    =     data & 0b0000000000111111
      waveform.value = shr(data & 0b0000000111000000, 6)
      volume.value   = shr(data & 0b0000111000000000, 9)
      effect.value   = shr(data & 0b0111000000000000, 12)

      -- TODO custom instrument byte
    end,
  }
end

function copy_note(input_note)
  local new_note = make_note_widget()
  new_note:copy_values(input_note)
  return new_note
end
