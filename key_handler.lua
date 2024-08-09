key_handler = class:new {
  supported_btns = {4, 5},
  last_frame_btn = {},

  update = function(_ENV)
    for v in all(supported_btns) do
      last_frame_btn[v] = btn(v)
    end
  end
}

function btnp_once(val)
  return btn(val) and not key_handler.last_frame_btn[val]
end
