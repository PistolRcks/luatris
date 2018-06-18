--"ltrs" library by PistolRcks. Includes useful functions for Luatris.
ltrs = {}

function ltrs.blockCollides(set_or_pos, dir)
  --ltrs.blockCollides(set_or_pos, [dir])
  --Has two modes: Checking a raw `pos` (table) or checking if blocks in `set` collide in `dir`
  --Returns true if any block in `set` would collide in the specified `dir` or if a block resides in `pos`
  --There are eight choices for `dir`:
    --"pos", which changes the mode of the function to position checking instead of direction checking
    --"above", which checks if blocks in `set` would collide with any block above
    --"below", which checks if blocks in `set` would collide with any block below
    --"left", which checks if blocks in `set` would collide with any block to the left of the `set`
    --"right", which checks if blocks in `set` would collide with any block to the right of the `set`
    --"leftedge", which checks if blocks in `set` would collide with the left edge of the grid
    --"rightedge", which checks if blocks in `set` would collide with the right edge of the grid
    --"bottom", which checks if blocks in `set` would collide with the bottom of the screen
  if dir ~= "pos" then
   for i,v in ipairs(set_or_pos) do
     if dir == "above" then
       if block.stored[tostring(set_or_pos[i].x)..tostring(set_or_pos[i].y-1)] ~= nil then return true end
     elseif dir == "below" then
       if block.stored[tostring(set_or_pos[i].x)..tostring(set_or_pos[i].y+1)] ~= nil then return true end
     elseif dir == "left" then
       if block.stored[tostring(set_or_pos[i].x-1)..tostring(set_or_pos[i].y)] ~= nil then return true end
     elseif dir == "right" then
       if block.stored[tostring(set_or_pos[i].x+1)..tostring(set_or_pos[i].y)] ~= nil then return true end
     elseif dir == "leftedge" then
       if set_or_pos[i].x-1 == -1 then return true end
     elseif dir == "rightedge" then
       if set_or_pos[i].x+1 == grid.width then return true end
     elseif dir == "bottom" then
       if set_or_pos[i].y == grid.height - 1 then return true end
     end
   end
   return false
 else
   if block.stored[tostring(set_or_pos.x)..tostring(set_or_pos.y)] ~= nil then return true
   else return false end
 end
end

ltrs.rotationData = { --Super Rotation System data (http://tetris.wikia.com/wiki/SRS). This was awful to copy and format (for continuity).
  others = {
    ["1-2"] = {{x = 0, y = 0}, {x = -1, y = 0}, {x = -1, y = 1}, {x = 0, y = -2}, {x = -1, y = -2}},
    ["2-1"] = {{x = 0, y = 0}, {x = 1, y = 0}, {x = 1, y = -1}, {x = 0, y = 2}, {x = 1, y = 2}},
    ["2-3"] = {{x = 0, y = 0}, {x = 1, y = 0}, {x = 1, y = -1}, {x = 0, y = 2}, {x = 1, y = 2}},
    ["3-2"] = {{x = 0, y = 0}, {x = -1, y = 0}, {x = -1, y = 1}, {x = 0, y = -2}, {x = -1, y = -2}},
    ["3-4"] = {{x = 0, y = 0}, {x = 1, y = 0}, {x = 1, y = 1}, {x = 0, y = -2}, {x = 1, y = -2}},
    ["4-3"] = {{x = 0, y = 0}, {x = -1, y = 0}, {x = -1, y = -1}, {x = 0, y = 2}, {x = -1, y = 2}},
    ["4-1"] = {{x = 0, y = 0}, {x = -1, y = 0}, {x = -1, y = -1}, {x = 0, y = 2}, {x = -1, y = 2}},
    ["1-4"] = {{x = 0, y = 0}, {x = 1, y = 0}, {x = 1, y = 1}, {x = 0, y = -2}, {x = 1, y = -2}}
  },
  i = {
    ["1-2"] = {{x = 0, y = 0}, {x = -2, y = 0}, {x = 1, y = 0}, {x = -2, y = -1}, {x = 1, y = 2}},
    ["2-1"] = {{x = 0, y = 0}, {x = 2, y = 0}, {x = -1, y = 0}, {x = 2, y = 1}, {x = -1, y = -2}},
    ["2-3"] = {{x = 0, y = 0}, {x = -1, y = 0}, {x = 2, y = 0}, {x = -1, y = 2}, {x = 2, y = -1}},
    ["3-2"] = {{x = 0, y = 0}, {x = 1, y = 0}, {x = -2, y = 0}, {x = 1, y = -2}, {x = -2, y = 1}},
    ["3-4"] = {{x = 0, y = 0}, {x = 2, y = 0}, {x = -1, y = 0}, {x = 2, y = 1}, {x = -1, y = -2}},
    ["4-3"] = {{x = 0, y = 0}, {x = -2, y = 0}, {x = 1, y = 0}, {x = -2, y = -1}, {x = 1, y = 2}},
    ["4-1"] = {{x = 0, y = 0}, {x = 1, y = 0}, {x = -2, y = 0}, {x = 1, y = -2}, {x = -2, y = 1}},
    ["1-4"] = {{x = 0, y = 0}, {x = -1, y = 0}, {x = 2, y = 0}, {x = -1, y = 2}, {x = 2, y = -1}}
  }
}

function ltrs.testRotation(set, piece, currentRotation, newRotation)
  --Vector subtract and add function paraphrased from Starbound's "vec2" table because I'm lazy
  local function sub(vec1, vec2)
    return {x = vec1.x - vec2.x, y = vec1.y - vec2.y}
  end
  local function add(vec1, vec2)
    return {x = vec1.x + vec2.x, y = vec1.y + vec2.y}
  end
  local referenceCorner = sub(block.current.set[1], tetromino.shapes[piece].form[currentRotation][1]) --Get the corner in grid coordinates to translate with local coordinates
  local rotationChange = currentRotation.."-"..newRotation --Concatenation of the current and new rotations for use with the ltrs.rotationData
  local newPos = {} --Initialize the new position table for use later
  local dataSet
  if piece == "j" or piece == "l" or piece == "s" or piece == "t" or piece == "s" or piece == "z" then --This could probably be made more efficient
    dataSet = "others"
  elseif piece == "i" then
    dataSet = "i"
  elseif piece == "o" then --Why would you test the rotation of an "o" block...?
    return true
  end
  for test = 1, 5 do
    print("Starting test "..test.."...")
    for block = 1, 4 do
      --The test position is the vector addition of the reference corner (in grid coordinates), the current block's new rotation (in local coordinates) and the current test's offset (local coords, see ltrs.rotationData)
      local testPos = add(add(referenceCorner, tetromino.shapes[piece].form[newRotation][block]), ltrs.rotationData[dataSet][rotationChange][test])
      if not ltrs.blockCollides(testPos, "pos") and testPos.x < grid.width and testPos.x >= 0 and testPos.y <= grid.height then --If a block is not in the same position as the test position, then add it to the new position table
        print("   Block "..block.." succeeded on test "..test.." at position ["..testPos.x..", "..testPos.y.."]!")
        newPos[block] = testPos
      else --If one piece fails the test, scrap the entire thing and break the current test
        newPos = {}
        print("   Block "..block.." failed on test "..test.." at position ["..testPos.x..", "..testPos.y.."]!")
        break
      end
    end
    if newPos[1] ~= nil and newPos[2] ~= nil and newPos[3] ~= nil and newPos[4] ~= nil then --Sanity check.
      return newPos
    end
  end
  return false --When all else fails, return false
end
