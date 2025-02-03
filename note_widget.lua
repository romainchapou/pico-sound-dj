function make_note_widget()
  local pitch_draw_func = function(_ENV, x, y, is_selected, is_activated)
    if is_selected then
      rectfill(x-2, y-1, x+12, y+5, 9)
    end

    if is_activated then
      print(pitch_to_str(value), x, y, 0)
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

  local wave_draw_func = function(_ENV, x, y, is_selected, is_activated)
    if is_selected then
      rectfill(x-2, y-1, x+4, y+5, 9)
    end

    local color = 0
    if value >= 8 and is_activated then
      color = is_selected and 7 or 9
    end

    print(is_activated and value % 8 or ".", x, y - (is_activated and 0 or 2), color)
  end

  return class:new {
    pitch    = make_input_widget(0, 0, 63, 12, pitch_draw_func),
    -- for the waveform (aka instrument), a value in [0, 7] represents a usual instrument value,
    -- while a value in [8, 15] represents a custom instrument
    waveform = make_input_widget(0, 0, 15, 8, wave_draw_func),
    volume   = make_input_widget(0, 0, 7),
    effect   = make_input_widget(0, 0, 7, nil, effect_draw_func),

    get_sub_widgets = function(_ENV)
      return {pitch, waveform, volume, effect}
    end,

    play_note_preview = function(_ENV)
      -- no note preview when multi selection or pattern or sfx playing
      if sfx_editor.n_multi_selection or stat(57) or stat(46) >= 0 then
        return
      end

      local neighbour_addr = 0x3200 + 68*sfx_editor.neighbour_sfx_id
      store_in_mem(_ENV, neighbour_addr) -- store to first note of neighbour sfx

      -- storing sfx settings of the currently edited sfx to its neighbour
      -- using store_waveform = false as it should always be the case when playing a note preview
      sfx_settings[sfx_editor.sfx_id+1]:store_in_mem(false, neighbour_addr + 64)
      sfx(sfx_editor.neighbour_sfx_id, 3, 0, 1)
    end,

    copy_values = function(_ENV, other_note)
      for i,e in ipairs(get_sub_widgets(_ENV)) do
        e(other_note:get_sub_widgets()[i].value)
      end
    end,

    -- we assume that this note is selected
    update = function(_ENV, sub_selection, should_modify_if_no_volume)
      if volume.value == 0 and not should_modify_if_no_volume then
        return
      end

      if not sfx_editor.n_multi_selection then
        if btn_b then
          if btnp_once "BTN_A" then
            -- cut the selection by copying its value to last_edited_note
            sfx_editor.last_edited_note = make_note_widget()
            sfx_editor.last_edited_note:copy_values(_ENV)

            volume(0)
          end

          return
        end

        -- single O press pastes the last edited note if on
        -- an empty note in the pitch colum
        if volume.value == 0 and sub_selection == 1 and btnp_once(BTN_A, true) then
          copy_values(_ENV, sfx_editor.last_edited_note)

          if volume.value == 0 then
            volume(5)
          end
        end
      end

      local sub_widget = get_sub_widgets(_ENV)[sub_selection]
      local old_value = sub_widget.value

      sub_widget:update()

      if sub_widget.value ~= old_value or btnp_once(BTN_A, true) then
        if not sfx_editor.n_multi_selection and volume.value ~= 0 then
          if sub_selection == 2 then
            if waveform.value >= 8 then
              send_msg("custom instr " .. tostr(waveform.value % 8), false)
            else
              send_msg("instr " .. tostr(waveform.value) .. ": "
              .. INSTRUMENT_NAMES[waveform.value+1], false)
            end
          elseif sub_selection == 4 then
            send_msg("fx " .. tostr(effect.value) .. ": "
            .. EFFECT_NAMES[effect.value+1], false)
          end
        end

        play_note_preview(_ENV)
        sfx_editor.last_edited_note = _ENV
      end
    end,

    draw = function(_ENV, x, y, is_note_selected, sub_selection,
                    next_note_has_slide, prev_note_has_volume)

      local is_ghost_note = next_note_has_slide or (effect.value == 1 and prev_note_has_volume)

      if is_ghost_note and volume.value == 0 then
        pal(0, 6)
      end

      for i=1,4 do
        get_sub_widgets(_ENV)[i]:draw(x + (i > 1 and 6+i*6 or 0), y,
                                      is_note_selected and sub_selection == i,
                                      volume.value > 0 or is_ghost_note)
      end

      pal(0, 0)
    end,

    store_in_mem = function(_ENV, addr)
      poke2(addr, pitch.value
                  | waveform.value % 8 << 6
                  | volume.value << 9
                  | effect.value << 12
                  | bool_to_num(waveform.value >= 8) << 15)
    end,

    load_from_mem = function(_ENV, addr)
      local data = %addr

      pitch(         data & 0b0000000000111111)
      waveform(  shr(data & 0b0000000111000000, 6))
      volume(    shr(data & 0b0000111000000000, 9))
      effect(    shr(data & 0b0111000000000000, 12))

      if data & 0b1000000000000000 ~= 0 then
        waveform.value += 8
      end
    end,
  }
end

function copy_note(input_note)
  local new_note = make_note_widget()
  new_note:copy_values(input_note)
  return new_note
end
