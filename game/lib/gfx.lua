gfx = {}
local draw = love.graphics.draw --Saves cycles

function gfx.drawMultisprite(image, sprites, layers, offset)
  --[[
  Draws a group of multiple sprites, layer by layer.

  @param image `image`   -  A spritesheet or texture atlas.
  @param sprites `table` -  A table containing quads for each sprite stored either with key/value pairs or positionally
                            E.g. {love.graphics.newQuad(0,0,8,8,64,64), love.graphics.newQuad(8,0,8,8,64,64)}
  @param layers `table`  -  A table which contains the sprites to be drawn, referred to either by their keys or by their positions.
                            Tables within the table denote rows, and the strings within tables (which, again, should be their keys or positions) denote columns.
                              - NB - The items within each layer can also be tables to add more options. This optional second form is as follows: {item, rotation, sx, sy}
                            E.g. {{1,2},{2,2},{1,{2, 0, -1, -1}}}
  @param offset `table`  -  The offset with which the multisprite group should be drawn. Should be an X/Y pair.
  @returns Nothing, unless an error occurs.
  NB - All sprites should be square and of the same size.
  ]]--
  local spriteX, spriteY, spriteW, spriteH = sprites[next(sprites)]:getViewport()

  --Cycle through layer items, layer by layer
  for y,v1 in ipairs(layers) do
    for x,v2 in ipairs(layers[y]) do
      if type(layers[y][x]) == "table" then --Optional second form
        draw(image, sprites[layers[y][x][1]], offset[1] + math.ceil(spriteW * (x - 1)), offset[2] + math.ceil(spriteW * (y - 1)), layers[y][x][2], layers[y][x][3], layers[y][x][4])
      else
        draw(image, sprites[layers[y][x]], offset[1] + math.ceil(spriteW * (x - 1)), offset[2] + math.ceil(spriteW * (y - 1)))
      end
    end
  end
end
