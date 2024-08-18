debug = class:new {
  elts = {},
  color = 8,

  do_print = true,

  add = function(_ENV, txt, elt)
    while #elts >= 18 do
      deli(elts, 1)
    end

    add(elts, {txt, elt})
  end,

  draw = function(_ENV)
    if not do_print then return end

    local y = 0

    for e in all(elts) do
      local txt, elt = e[1], e[2]
      local to_print
      if type(elt) == "function" then
        to_print = elt()
      else
        to_print = elt
      end

      if to_print == nil then
        to_print = txt
      else
        to_print = txt .. ":" .. tostring(to_print)
      end

      for dx=-1,1 do
        for dy=-1,1 do
          print(to_print, 1+dx, y+dy, 0)
        end
      end

      print(to_print, 1, y, _ENV.color)
      y += 7
    end
  end
}

inspect = function(t)
  if type(t) == "table" then
    local res = "{"

    for k,e in pairs(t) do
      res = res .. tostring(k) .. ":" .. inspect(e) .. ", "
    end
    res = sub(res, 1, #res-1) .. "}"
    return res
  else
    return type(t)
  end
end
