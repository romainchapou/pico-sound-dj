pattern_editor = class:new {
  init = function(_ENV)
    first_visible_pattern = 0
  end,

  update = function(_ENV)
  end,

  draw = function(_ENV)
    print("pattern editor", 1, 1, 6)

    local start_y = 10

    for i=0,15 do
      print(two_digit_number_str(i + first_visible_pattern), 3, start_y + i*6, 6)
    end
  end,
}
