function make_input_widget(x, y, base_val, min_val, max_val, delta, draw, upd)
  if draw == nil then
    draw = function(_ENV, is_selected)
      print(value, x, y, 0)

      if is_selected then
        -- TODO selection visualisation
        pset(x, y, 8)
      end
    end
  end

  if delta == nil then delta = max_val end

  if upd == nil then
    upd = function(_ENV)
      if btn(5) and not btn(4) then
        if btnp(0) then value -= 1 end
        if btnp(1) then value += 1 end
        if btnp(2) then value += delta_up end
        if btnp(3) then value -= delta_up end

        value = mid(min_value, value, max_value)
      end
    end
  end

  -- TODO width / height
  return class:new {
    x = x,
    y = y,
    value = base_val,
    min_value = min_val,
    max_value = max_val,
    delta_up = delta,

    update = upd,
    draw = draw
  }
end

function make_note_widget(x, y)
  return {
    pitch    = make_input_widget(x,    y, 0, 0, 63, 12), -- TODO custom draw here
    waveform = make_input_widget(x+13, y, 0, 0, 7),      -- aka instrument
    volume   = make_input_widget(x+18, y, 0, 0, 7),
    effect   = make_input_widget(x+22, y, 0, 0, 7),

    update = function(_ENV, selected)
      local sub_widgets = {pitch, waveform, volume, effect}

      sub_widgets[selected]:update()
    end,

    draw = function(_ENV, selected)
      for i,w in ipairs({pitch, waveform, volume, effect}) do
        w:draw(selected == i)
      end
    end
  }
end
