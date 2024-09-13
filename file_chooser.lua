file_chooser = class:new {
  init = function(_ENV, on_confirm)
    active = true
  end,

  update = function(_ENV)
  end,

  draw = function(_ENV)
    if not active then return end

    print("cooooool", 40 + rnd()*2, 60, 9)
  end
}
