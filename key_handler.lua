key_handler = class:new {
  last_frame_btn = {{}, {}},

  update = function(_ENV)
    for pl=0,1 do
      for v=0,5 do
        last_frame_btn[pl+1][v] = btn(v, pl)
      end
    end
  end
}

function btnp_once(val, pl)
  if pl == nil then pl = 0 end
  return btn(val, pl) and not key_handler.last_frame_btn[pl+1][val]
end
