function base_widget_udpate(_ENV)
  if btn(BTN_A) and not btn(BTN_B) then
    value = mid(min_value, value + nudge() - nudge(true)*delta_up, max_value)
  end
end

-- note that this should actually be named "numeric_input_widget"
function make_input_widget(base_val, min_val, max_val, delta, draw, update)
  draw = draw or function(_ENV, x, y, is_selected, is_activated)
    -- @Cleanup: this is used in every widget, so we could refactor by
    -- splitting the draw function in two and just providing a size for the
    -- rectangle to highlight
    if is_selected then
      rectfill(x-2, y-1, x+4, y+5, 9)
    end

    print(is_activated and value or ".", x, y - (is_activated and 0 or 2), 0)
  end

  return class:new {
    value = base_val,
    min_value = min_val,
    max_value = max_val,
    delta_up = delta or max_val,

    update = update or base_widget_udpate,
    draw = draw
  }
end

function make_named_input_widget(name, base_val, min_val, max_val, delta,
                                 draw, update, value_tbl)
  draw = draw or function(_ENV, x, y, is_selected)
    if name ~= nil then
      local str_val = tostr(value)

      if value_tbl then
        local entry = value_tbl[value]
        str_val = type(entry) == "table" and entry[1] or entry
      end

      if is_selected then
        rectfill(#name*4+5 + x-2, y-1, #name*4+1 + x+4 + #str_val*4, y+5, 9)
      end

      print(name .. ":", x, y, is_selected and 0 or 6)
      print(str_val, x + #name*4+5, y, 0)
    end
  end

  return make_input_widget(base_val, min_val, max_val, delta, draw, update)
end

-- on/off button widget
function make_button_widget(btn_spr)
  return class:new {
    state = false,

    update = function(_ENV)
      if btnp_once(BTN_A) then
        state = not state
      end
    end,

    draw = function(_ENV, x, y, is_selected)
      if is_selected then
        rectfill(x-2, y-1, x+6, y+5, 9)
      end

      if state then
        spr(btn_spr, x, y)
      else
        pset(x+2, y+2, 0)
      end
    end
  }
end

function make_btn_pushed_widget(name, action_func)
  return class:new {
    -- supposes that this is currently selected
    update = function(_ENV)
      if btnp_once(BTN_A) then
        if action_func ~= nil then
          action_func()
          -- signify that the input was handled
          return true
        else
          -- by default returns the hold text when pressed
          return name
        end
      end
    end,

    draw = function(_ENV, x, y, is_selected)
      local txt = type(name) == "function" and name() or name

      if is_selected then
        local txt_len = 0
        for c in all(txt) do
          txt_len += ord(c) >= 128 and 8 or 4
        end

        rectfill(x-2, y-1, x + txt_len, y+5, 9)
      end

      local color = 0
      if inactive then color = 6 end

      print(txt, x, y, color)
    end
  }
end
