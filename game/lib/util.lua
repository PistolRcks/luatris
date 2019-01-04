util = {}

--Simple Fisher-Yates shuffle from Gist Uradamus/shuffle.lua
function util.shuffle(tbl)
  local size = #tbl
  for i = size,1 , -1 do
    local rand = math.random(size)
    tbl[i], tbl[rand] = tbl[rand], tbl[i]
  end
  return tbl
end
