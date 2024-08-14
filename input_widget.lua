function make_input_widget(base_val, min_val, max_val, delta, draw, update)
  if draw == nil then
    draw = function(_ENV, x, y, is_selected, is_activated)
      -- @Cleanup: this is used in every widget, so we could refactor by
      -- splitting the draw function in two and just providing a size for the
      -- rectangle to highlight
      if is_selected then
        rectfill(x-2, y-1, x+4, y+5, 9)
      end

      print(is_activated and value or ".", x, y - (is_activated and 0 or 2), 0)
    end
  end

  if delta == nil then delta = max_val end

  if update == nil then
    update = function(_ENV)
      if btn(5) and not btn(4) then
        local old_value = value

        if btnp(0) then value -= 1 end
        if btnp(1) then value += 1 end
        if btnp(2) then value += delta_up end
        if btnp(3) then value -= delta_up end

        value = mid(min_value, value, max_value)
      end
    end
  end

  return class:new {
    value = base_val,
    min_value = min_val,
    max_value = max_val,
    delta_up = delta,

    update = update,
    draw = draw
  }
end

function make_note_widget()
  local pitch_draw_func = function(_ENV, x, y, is_selected, is_activated)
    if is_selected then
      rectfill(x-2, y-1, x+12, y+5, 9)
    end

    if is_activated then
      print(note_names[value % 12 + 1], x, y, 0)
      print(value \ 12, x+8, y, 0)
    else
      print("...", x, y-2, 0)
    end
  end

  local effect_draw_func = function(_ENV, x, y, is_selected, is_activated)
      if is_selected then
        rectfill(x-2, y-1, x+4, y+5, 9)
      end

      print(value == 0 and "." or value, x, y - (value == 0 and 2 or 0), 0)
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
      store_in_mem(_ENV, 0x3200 + 68) -- store to first note of sfx 1
      sfx(1, -1, 0, 1)
    end,

    copy_values = function(_ENV, other_note)
      for i,e in ipairs(get_sub_widgets(_ENV)) do
        e.value = other_note:get_sub_widgets()[i].value
      end
    end,

    -- we assume that this is the selected note
    update = function(_ENV, sub_selection)
      if btn(4) then
        if btnp_once(5) then
          -- cut the selection by copying its value to last_edited_note
          GLOBAL.last_edited_note = make_note_widget()
          GLOBAL.last_edited_note:copy_values(_ENV)

          volume.value = 0
        end

        return
      end

      if volume.value == 0 then
        if sub_selection == 0 then
          -- single X press copies the last edited note if on an empty
          -- note in the pitch colum
          if btnp(5) then
            copy_values(_ENV, GLOBAL.last_edited_note)

            if volume.value == 0 then
              volume.value = 5
            end

            play_tmp_note(_ENV)
          end
        end
      end

      local sub_widget = get_sub_widgets(_ENV)[sub_selection+1]
      local old_value = sub_widget.value

      sub_widget:update()

      if sub_widget.value ~= old_value or btnp_once(5) then
        play_tmp_note(_ENV)
        GLOBAL.last_edited_note = _ENV
      end
    end,

    draw = function(_ENV, x, y, is_note_selected, sub_selection)
      pitch:draw(x, y, is_note_selected and sub_selection == 0, volume.value > 0)
      waveform:draw(x+18, y, is_note_selected and sub_selection == 1, volume.value > 0)
      volume:draw(x+24, y, is_note_selected and sub_selection == 2, volume.value > 0)
      effect:draw(x+30, y, is_note_selected and sub_selection == 3, volume.value > 0)
    end,

    store_in_mem = function(_ENV, addr)
      local v = 0
      v += pitch.value
      v += shl(waveform.value, 6)
      v += shl(volume.value, 9)
      v += shl(effect.value, 12)

      poke2(addr, v)
    end,
  }
end
