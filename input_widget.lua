function make_input_widget(base_val, min_val, max_val, delta, draw, update)
  if draw == nil then
    draw = function(_ENV, x, y, is_selected)
      if is_selected then
        rectfill(x-2, y-1, x+4, y+5, 9)
      end

      print(value, x, y, 0)
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
  local GLOBAL = _ENV

  local pitch_draw_func = function(_ENV, x, y, is_selected)
    if is_selected then
      rectfill(x-2, y-1, x+12, y+5, 9)
    end

    print(GLOBAL.note_names[value % 12 + 1], x, y, 0)
    print(value \ 12, x+8, y, 0)
  end

  return {
    pitch    = make_input_widget(0, 0, 63, 12, pitch_draw_func),
    waveform = make_input_widget(0, 0, 7),  -- aka instrument
    volume   = make_input_widget(0, 0, 7),
    effect   = make_input_widget(0, 0, 7),

    get_sub_widgets = function(_ENV)
      return {pitch, waveform, volume, effect}
    end,

    play_tmp_note = function(_ENV)
      store_in_mem(_ENV, 0x3200 + 68) -- store to first note of sfx 1
      GLOBAL.sfx(1, -1, 0, 1)
    end,

    update = function(_ENV, sub_selection)
      local sub_widget = get_sub_widgets(_ENV)[sub_selection+1]
      local old_value = sub_widget.value

      sub_widget:update()

      if sub_widget.value ~= old_value or GLOBAL.btnp_once(5) then
        play_tmp_note(_ENV)
      end
    end,

    draw = function(_ENV, x, y, is_note_selected, sub_selection)
      pitch:draw(x, y, is_note_selected and sub_selection == 0)
      waveform:draw(x+15, y, is_note_selected and sub_selection == 1)
      volume:draw(x+21, y, is_note_selected and sub_selection == 2)
      effect:draw(x+27, y, is_note_selected and sub_selection == 3)
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
