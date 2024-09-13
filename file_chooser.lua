file_chooser = class:new {
  init = function(_ENV, on_confirm)
    active = true

    NB_SHOWN_FILES = 19

    confirm_func = on_confirm

    cur_dir = "/"
    dir_files = {}
    update_dir_files(_ENV)

    first_visible_line = 0

    cur_line = 1

    saved_pos = {}
  end,

  update = function(_ENV)
    if not active then return end

    if btnp(2) then cur_line -= 1 end
    if btnp(3) then cur_line += 1 end

    cur_line = mid(1, cur_line, #dir_files)

    if first_visible_line + NB_SHOWN_FILES < cur_line then
      first_visible_line = cur_line - NB_SHOWN_FILES
    elseif cur_line <= first_visible_line then
      first_visible_line = cur_line - 1
    end

    if btnp(0) or btnp_once(4) then
      if cur_dir == "/" then
        -- cancel the file selection
        active = false
        return
      end

      move_back(_ENV)
    end

    -- move in
    if btnp(1) or btnp_once(5) then
      local selection = dir_files[cur_line]

      if selection == ".." then
        move_back(_ENV)
        return
      end

      if selection[#selection] == "/" then
        saved_pos[cur_dir] = cur_line

        -- this is a directory, entering it
        cur_dir = cur_dir .. selection
        update_dir_files(_ENV)

        if saved_pos[cur_dir] then
          cur_line = saved_pos[cur_dir]
        end
      else
        -- this is a file, return it
        confirm_func(cur_dir .. selection)
        active = false
      end
    end
  end,

  move_back = function(_ENV)
    saved_pos[cur_dir] = cur_line

    local path = split(cur_dir, "/")
    cur_dir = ""

    for i=2,#path-2 do
      cur_dir = cur_dir .. "/" .. path[i]
    end

    cur_dir = cur_dir .. "/"

    update_dir_files(_ENV)

    if saved_pos[cur_dir] then
      cur_line = saved_pos[cur_dir]
    end
  end,

  update_dir_files = function(_ENV)
    dir_files = {}

    if cur_dir ~= "/" then
      add(dir_files, "..")
    end

    for f in all(ls(cur_dir)) do
      local path = split(f, "/")
      local exts = split(path[#path], ".")
      local last_ext = exts[#exts]

      if path[#path] == "" or last_ext == "p8" or (last_ext == "png" and exts[#exts-1] == "p8") then
        add(dir_files, f)
      end
    end
  end,

  draw = function(_ENV)
    if not active then return end

    cls(7)

    rectfill(9, -1+6*(cur_line-first_visible_line),
             100, 5+6*(cur_line-first_visible_line), 9)

    for i=1,NB_SHOWN_FILES do
      local f = dir_files[first_visible_line+i]

      if f then
        print(dir_files[first_visible_line+i], 10, i*6, 0)
      end
    end

    print(cur_dir, 0, 120, 8)
  end
}
