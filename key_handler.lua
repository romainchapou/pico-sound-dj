key_handler = class:new {
  last_frame_btn = {{}, {}},
  o_hold_nb_frames = 0,
  time_since_last_o = 32000,
  double_registered = false, -- TODO use could probably be simplified

  update = function(_ENV)
    if btn(4) and last_frame_btn[1][4] then
      o_hold_nb_frames += 1
    elseif btn() ~= 0 then
      o_hold_nb_frames = 0
    end

    if btn() == 0 then
      time_since_last_o += 1
      time_since_last_o = min(32000, time_since_last_o)
    elseif btn() == 0x0010 and not double_registered then
      time_since_last_o = 0
    else
      time_since_last_o = 32000
    end

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

-- return true when the sequence "O -> bnt(v)" is quickly inputed
function btnp_seq_o(v)
  local ret = btnp_once(v) and key_handler.o_hold_nb_frames < 10 and key_handler.time_since_last_o < 30

  if ret then
    key_handler.double_registered = true
  end

  return ret
end
