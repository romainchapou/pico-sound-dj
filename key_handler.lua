key_handler = class:new {
  last_frame_btn = {},

  update = function(_ENV)
    for v=0,5 do
      last_frame_btn[v] = btn(v)
    end
  end
}

function btnp_once(val)
  return btn(val) and not key_handler.last_frame_btn[val]
end
