-- note that this should actually be named "numeric_input_widget"
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
        value = mid(min_value, value + nudge() - nudge(true)*delta_up, max_value)
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

function make_named_input_widget(name, base_val, min_val, max_val, delta, draw, update)
  if draw == nil then
    draw = function(_ENV, x, y, is_selected)
      if name ~= nil then
        if is_selected then
          rectfill(#name*4+5 + x-2, y-1, #name*4+1 + x+4 + #tostr(value)*4, y+5, 9)
        end

        print(name .. ":", x, y, is_selected and 0 or 6)
        print(value, x + #name*4+4+1, y, 0)
      end
    end
  end

  local input_widget = make_input_widget(base_val, min_val, max_val, delta, draw, update)

  return input_widget
end

-- on/off button widget
function make_button_widget(btn_spr)
  return class:new {
    state = false,

    update = function(_ENV)
      if btnp_once(5) then
        state = not state
      end
    end,

    draw = function(_ENV, x, y, is_selected)
      if is_selected then
        rectfill(x-2, y-1, x+6, y+5, 9)
      end

      if state then
        palt(14, true)
        palt(0, false)

        spr(btn_spr, x, y)

        palt()
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
      if btnp_once(5) then
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
      local txt = (type(name) == "function") and name() or name

      if is_selected then
        rectfill(x-2, y-1, x + 4*#txt, y+5, 9)
      end

      local color = 0
      if inactive then color = 6 end

      print(txt, x, y, color)
    end
  }
end
