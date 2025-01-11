GLOBAL=_ENV

class=setmetatable({
  new=function(_ENV,tbl)
    tbl=tbl or {}
    setmetatable(tbl, {
      __index=_ENV,
      -- small token optimisation, table.value = v => table(v)
      __call = function(_ENV, v) value = v end
    })
    return tbl
  end,
  
  init=function()end
},{__index=_ENV})
