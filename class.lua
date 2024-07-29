GLOBAL=_ENV

class=setmetatable({
  new=function(_ENV,tbl)
    tbl=tbl or {}
    setmetatable(tbl,{ __index=_ENV })
    return tbl
  end,
  
  init=function()end
},{__index=_ENV})
