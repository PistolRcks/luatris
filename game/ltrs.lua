--"ltrs" library by PistolRcks. Includes useful functions for Luatris.
ltrs = {}

--Vector subtract and add function paraphrased from Starbound's "vec2" table because I'm lazy
function ltrs.vecSub(vec1, vec2)
  return {x = vec1.x - vec2.x, y = vec1.y - vec2.y}
end
function ltrs.vecAdd(vec1, vec2)
  return {x = vec1.x + vec2.x, y = vec1.y + vec2.y}
end

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
       if block.stored[tostring(set_or_pos[i].x).."/"..tostring(set_or_pos[i].y-1)] ~= nil then return true end
     elseif dir == "below" then
       if block.stored[tostring(set_or_pos[i].x).."/"..tostring(set_or_pos[i].y+1)] ~= nil then return true end
     elseif dir == "left" then
       if block.stored[tostring(set_or_pos[i].x-1).."/"..tostring(set_or_pos[i].y)] ~= nil then return true end
     elseif dir == "right" then
       if block.stored[tostring(set_or_pos[i].x+1).."/"..tostring(set_or_pos[i].y)] ~= nil then return true end
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
   if block.stored[tostring(set_or_pos.x).."/"..tostring(set_or_pos.y)] ~= nil then return true
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
  local referenceCorner = ltrs.vecSub(block.current.set[1], tetromino.shapes[piece].form[currentRotation][1]) --Get the corner in grid coordinates to translate with local coordinates
  local rotationChange = currentRotation.."-"..newRotation --Concatenation of the current and new rotations for use with the ltrs.rotationData
  local newPos = {} --Initialize the new position table for use later
  local dataSet
  if piece == "j" or piece == "l" or piece == "s" or piece == "t" or piece == "s" or piece == "z" then --This could probably be made more efficient
    dataSet = "others"
  elseif piece == "i" then
    dataSet = "i"
  elseif piece == "o" then --Why would you test the rotation of an "o" block...? UPDATE: Apparently, there are "O"-spins in modern Tetris games. I might add this sometime.
    return true
  end
  for test = 1, 5 do
    print("Starting test "..test.."...")
    for block = 1, 4 do
      --The test position is the vector addition of the reference corner (in grid coordinates), the current block's new rotation (in local coordinates) and the current test's offset (local coords, see ltrs.rotationData)
      local testPos = ltrs.vecAdd(ltrs.vecAdd(referenceCorner, tetromino.shapes[piece].form[newRotation][block]), ltrs.rotationData[dataSet][rotationChange][test])
      if not ltrs.blockCollides(testPos, "pos") and testPos.x < grid.width and testPos.x >= 0 and testPos.y <= grid.height then --If a block is not in the same position as the test position, then add it to the new position table
        print("   Block "..block.." succeeded on test "..test.." at position ["..testPos.x..", "..testPos.y.."]!")
        newPos[block] = testPos
      else --If one piece fails the test, scrap the entire thing and break the current test
        newPos = {}
        print("   Block "..block.." failed on test "..test.." at position ["..testPos.x..", "..testPos.y.."]!")
        break
      end
    end
    if newPos[1] ~= nil and newPos[2] ~= nil and newPos[3] ~= nil and newPos[4] ~= nil then --Sanity check
      return newPos
    end
  end
  return false --When all else fails, return false
end

function ltrs.updateHardDrop() --Updates the position of the hard drop
  local lowestInSet = {}
  for i=1,4 do
    if lowestInSet[block.current.set[i].x] == nil then --If there is no set lowest for the current X coordinate...
      lowestInSet[block.current.set[i].x] = block.current.set[i].y --...set one.
    elseif lowestInSet[block.current.set[i].x] < block.current.set[i].y then --If the block which is being checked is lower than the one that we already have (which is in the same X coordinate)
      lowestInSet[block.current.set[i].x] = block.current.set[i].y --...the current block will be set as the new lowest for that X coordinate.
    end
  end

  local highestBlocks = {}
  for k,v in pairs(lowestInSet) do
    for i=v, (grid.height - 1) do --Go down through all y values in the grid to check if there's a block (N.B. that we are using "i=v" since we should start testing at where the block currently is)
      if block.stored[tostring(k).."/"..tostring(i)] ~= nil then --If there's a block...
        table.insert(highestBlocks, {x = k, y = i - 1}) --...the highest possible drop spot for this X value is one above it
        break
      elseif i == (grid.height - 1) then --Only will trigger if there is no block below
        table.insert(highestBlocks, {x = k, y = (grid.height - 1)})
        break
      end
    end
  end
  table.sort(highestBlocks, function(a,b) return a.y < b.y end) --Sort the highest blocks... by height; the highest should be highestBlocks[1]

  --Sanity check
  for i,v in ipairs(highestBlocks) do
    local testsCorrect = 0
    local dropOffset = highestBlocks[i].y - lowestInSet[highestBlocks[i].x] --This will create an offset with which the new drop position will be found, and applied to all blocks
    --print("Drop offset for higestBlock "..i.." is: "..highestBlocks[i].y.." - "..lowestInSet[highestBlocks[i].x].." = "..dropOffset)
    for i2=1,4 do
      if block.stored[tostring(block.current.set[i2].x).."/"..tostring(block.current.set[i2].y + dropOffset)] == nil and (block.current.set[i2].y + dropOffset) <= (grid.height - 1) then
        testsCorrect = testsCorrect + 1
        --print(" Block "..i2.." test succeeded")
        block.hardDropPos[i2] = {x = block.current.set[i2].x, y = block.current.set[i2].y + dropOffset}
      else
        --print(" Block "..i2.." test failed; clearing and trying again")
        block.hardDropPos = {} --If a block test fails, clear everything from the hardDropPos table and try again
        break
      end
    end
    if testsCorrect == 4 then --If four tests were correct, we can stop.
      break
    end
  end

  print("Hard drop position is now...")
  if next(block.hardDropPos) ~= nil then
    for i=1,4 do
      print(" Block "..i..": ["..block.hardDropPos[i].x..", "..block.hardDropPos[i].y.."]")
    end
  end
end
