function make_btn_state_seq(btn_val)
  return class:new {
    btn_val = btn_val,
    hold_nb_frames = 0,
    time_since_last = 32000,

    update = function(_ENV)
      if btn(btn_val) and key_handler.last_frame_btn[1][btn_val] then
        hold_nb_frames += 1
      elseif btn() ~= 0 then
        hold_nb_frames = 0
      end

      if btn() == 0 then
        time_since_last += 1
        time_since_last = min(32000, time_since_last)
      elseif btn() == shl(1, btn_val) and not key_handler.double_registered then
        time_since_last = 0
      else
        time_since_last = 32000
      end
    end,

    recent_short_press = function(_ENV)
      return not key_handler.last_frame_btn[1][btn_val]
             and hold_nb_frames < 10 and time_since_last < 20
    end
  }
end

key_handler = class:new {
  last_frame_btn = {{}, {}},

  o_state = make_btn_state_seq(4),
  x_state = make_btn_state_seq(5),

  double_registered = false, -- TODO use could probably be simplified

  update = function(_ENV)
    o_state:update()
    x_state:update()

    for pl=0,1 do
      for v=0,5 do
        last_frame_btn[pl+1][v] = btn(v, pl)
      end
    end

    if btn() == 0 then
      double_registered = false
    end
  end
}

function btnp_once(val, pl)
  if pl == nil then pl = 0 end
  return btn(val, pl) and not key_handler.last_frame_btn[pl+1][val]
end

-- return true when the sequence "btn(v1) -> btn(v2)" is quickly inputed
-- v1 must be 4 or 5
-- TODO launch only when btn(v2) is RELEASED!!!!
function btnp_seq(v1, v2)
  if v1 ~= 4 and v1 ~= 5 then return false end

  local btn_state = v1 == 4 and key_handler.o_state or key_handler.x_state

  local ret = btnp_once(v2) and btn_state:recent_short_press()

  if ret then
    key_handler.double_registered = true
  end

  return ret
end
