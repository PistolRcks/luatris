debug = true

function love.load(arg)
  require("ltrs")
  math.randomseed(os.time()) --Set the seed because the randomness would normally be uniform

  window = {}
  window.width, window.height, window.flags = love.window.getMode()

  block = {
    data = {img = love.graphics.newImage("assets/tiles/block.png"), imgShade = love.graphics.newImage("assets/tiles/blockShade.png")},
    current = {set = {}, color = {}, rotation = 1, active = false, tetromino = nil, held = nil},
    stored = {},
    hardDropPos = {}
  }
  block.data.width, block.data.height = block.data.img:getDimensions()

  tetromino = {
    shapes = {                                                              -- Offset all shapes by the top-left corner of a 4x4 square. The separate tables inside the `form` table are the separate rotations for each tetromino.
      i = {color = {0,1,1,1}, form = {
        {{x = 0, y = 1}, {x = 1, y = 1}, {x = 2, y = 1}, {x = 3, y = 1}},   -- 1: oooo  2: ooxo 3: oooo 4: oxoo
        {{x = 2, y = 0}, {x = 2, y = 1}, {x = 2, y = 2}, {x = 2, y = 3}},   --    xxxx     ooxo    oooo    oxoo
        {{x = 0, y = 2}, {x = 1, y = 2}, {x = 2, y = 2}, {x = 3, y = 2}},   --    oooo     ooxo    xxxx    oxoo
        {{x = 1, y = 0}, {x = 1, y = 1}, {x = 1, y = 2}, {x = 1, y = 3}}    --    oooo     ooxo    oooo    oxoo
      }},
      o = {color = {1,1,0,1}, form = {
        {{x = 1, y = 1}, {x = 2, y = 1}, {x = 1, y = 2}, {x = 2, y = 2}},   -- 1: oooo (and the rest.)
        {{x = 1, y = 1}, {x = 2, y = 1}, {x = 1, y = 2}, {x = 2, y = 2}},   --    oxxo
        {{x = 1, y = 1}, {x = 2, y = 1}, {x = 1, y = 2}, {x = 2, y = 2}},   --    oxxo
        {{x = 1, y = 1}, {x = 2, y = 1}, {x = 1, y = 2}, {x = 2, y = 2}}    --    oooo
      }},
      j = {color = {0,0,1,1}, form = {
        {{x = 0, y = 1}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 2, y = 2}},
        {{x = 1, y = 1}, {x = 1, y = 2}, {x = 1, y = 3}, {x = 2, y = 1}},
        {{x = 2, y = 3}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 2, y = 2}},
        {{x = 1, y = 1}, {x = 1, y = 2}, {x = 1, y = 3}, {x = 0, y = 3}}
      }},
      l = {color = {1,0.667,0,1}, form = {
        {{x = 2, y = 1}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 2, y = 2}},
        {{x = 1, y = 1}, {x = 1, y = 2}, {x = 1, y = 3}, {x = 2, y = 3}},
        {{x = 0, y = 3}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 2, y = 2}},
        {{x = 1, y = 1}, {x = 1, y = 2}, {x = 1, y = 3}, {x = 0, y = 1}}
      }},
      s = {color = {0,1,0,1}, form = {
        {{x = 1, y = 1}, {x = 2, y = 1}, {x = 0, y = 2}, {x = 1, y = 2}},
        {{x = 1, y = 1}, {x = 1, y = 2}, {x = 2, y = 2}, {x = 2, y = 3}},
        {{x = 1, y = 2}, {x = 2, y = 2}, {x = 0, y = 3}, {x = 1, y = 3}},
        {{x = 0, y = 1}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 1, y = 3}}
      }},
      z = {color = {1,0,0,1}, form = {
        {{x = 0, y = 1}, {x = 1, y = 1}, {x = 1, y = 2}, {x = 2, y = 2}},
        {{x = 2, y = 1}, {x = 1, y = 2}, {x = 2, y = 2}, {x = 1, y = 3}},
        {{x = 0, y = 2}, {x = 1, y = 2}, {x = 1, y = 3}, {x = 2, y = 3}},
        {{x = 1, y = 1}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 0, y = 3}}
      }},
      t = {color = {0.667,0,1,1}, form = {
        {{x = 1, y = 1}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 2, y = 2}},
        {{x = 1, y = 1}, {x = 1, y = 2}, {x = 1, y = 3}, {x = 2, y = 2}},
        {{x = 0, y = 2}, {x = 1, y = 2}, {x = 2, y = 2}, {x = 1, y = 3}},
        {{x = 0, y = 2}, {x = 1, y = 1}, {x = 1, y = 2}, {x = 1, y = 3}}
      }}
    },
    list = {"i","o","j","l","s","z","t"},
    nextList = {},
    nextMax = 5
  }
  grid = {width = 10, height = 20}

  grid.scaleFactor = {width = window.width/grid.width, height = window.height/grid.height}
  grid.tetrominoStartingPosition = math.floor((grid.width - 4) / 2)

  bggrid = {img = love.graphics.newImage("assets/tiles/backgroundgrid.png")}
  bggrid.quad = love.graphics.newQuad(0,0,window.width,window.height,grid.scaleFactor.width,grid.scaleFactor.width)
  bggrid.img:setWrap("repeat","repeat")

  game = {
    controls = {
      pressStart = 0,
      pressDelay = 0.25,
      denyMovement = false,
      keypress = {esc = false, up = false, rotate = false, space = false},
      holdUsed = false
    },
    event = {
      setBlock = false
    },
    linesCleared = 0,
    currentCombo = 0,
    gravity = {tick = nil, groundTimer = 0, groundMax = 0.5, softDropMulti = 4}, --TODO: Eventually, the gravity max and the ground max will be adaptive based on the current level
    isPaused = false, started = false
  }
  game.gravity.max = 0.5/math.floor((game.linesCleared+10)/10) --Early difficulty implementation
  game.gravity.normal, game.gravity.softDrop = game.gravity.max, (game.gravity.max/game.gravity.softDropMulti)

  animation = {
    quitMessage = false,
    lineClear = {message = nil, fade = 0}
  }

  font = {
    hobo = {
      h2 = love.graphics.newFont("/assets/fonts/hobo.ttf", 64),
      h3 = love.graphics.newFont("/assets/fonts/hobo.ttf", 48),
      h4 = love.graphics.newFont("/assets/fonts/hobo.ttf", 32)
    }
  }
end

function love.update(dt)
  --Utilities
  window.width, window.height, window.flags = love.window.getMode() --Setting this in the update function for adaptive window resizing (which really doesn't work correctly as of right now)
  grid.scaleFactor = {width = window.width/grid.width, height = window.height/grid.height}

  if not love.keyboard.isDown("escape") then --Reset stuff
    quittimer = 3
    animation.quitMessage = false
    game.controls.keypress.esc = false
  end
  if love.keyboard.isDown("escape") then
    --Game pausing
    if not game.controls.keypress.esc and game.started then
      if game.isPaused == true then
        game.isPaused = false
      else
        game.isPaused = true
      end
      game.controls.keypress.esc = true --To avoid spam while holding the key
    else
      --Good ol' hold-to-quit, thanks toby
      animation.quitMessage = true
      quittimer = quittimer - dt
      if quittimer < 0 then
        love.event.push("quit")
      end
    end
  end

  --Countdown at the beginning of the game
  if game.started == false and game.isPaused == false then
    if countdownTimerStart == nil then
      countdownTimerStart = love.timer.getTime()
    end
    countdownTimer = love.timer.getTime() - countdownTimerStart
    if countdownTimer > 4 then --Stop all the counting and start the game
      countdownTimerStart = nil
      game.started = true
      game.isPaused = false
    end
  end

  --Game Logic--
  if game.isPaused == false and game.started == true then
    --Gravity--
    if game.gravity.tick == nil then --If there is no gravity tick, get one
      game.gravity.tick = love.timer.getTime()
    elseif (love.timer.getTime() - game.gravity.tick) >= game.gravity.max and block.current.active == true then --On every gravity tick, when a block is active...
      if ltrs.blockCollides(block.current.set, "bottom") or ltrs.blockCollides(block.current.set, "below") then --...and a block collides with the bottom of the grid or another block below it...
        --...start counting up with the timer which counts how long a block has been touching the ground or a block below it
        game.gravity.groundTimer = game.gravity.groundTimer + dt
      else
        --TODO: This shouldn't just reset the timer in the future, but should change based on how much time the current block has spent on the ground previously
        game.gravity.groundTimer = 0
        --Lower all blocks in the current set by one
        for i=1,4 do
          block.current.set[i].y = block.current.set[i].y + 1
        end
        game.gravity.tick = love.timer.getTime()
      end
    end

    if game.gravity.groundTimer >= game.gravity.groundMax and block.current.active == true then
      game.event.setBlock = true
    end

    --Block setting--
    if game.event.setBlock then
      block.current.active = false
      --Store the block. Each block's data is stored in block.stored with a key which is a concatenation of its xcoord, a slash (to keep the numbers separated) and its ycoord.
      for i,v in ipairs(block.current.set) do
        block.stored[tostring(block.current.set[i].x).."/"..tostring(block.current.set[i].y)] = {x = block.current.set[i].x, y = block.current.set[i].y, color = block.current.color}
      end
      --Find layers which are full
      local layer = {destroyed = {}}
      for i,v in ipairs(block.current.set) do
        layer[tostring(block.current.set[i].y)] = {finished, full}
        if layer[tostring(block.current.set[i].y)].finished ~= true then --Don't redo layers that are already done
          for x = 0, grid.width - 1 do
            if block.stored[tostring(x).."/"..tostring(block.current.set[i].y)] ~= nil then
              layer[tostring(block.current.set[i].y)].full = true
              --print("Layer "..i.." is full at block "..x)
            else --If one of the blocks is not doesn't exist in a line, stop.
              layer[tostring(block.current.set[i].y)].full = false
              --print("Layer "..i.." not full at block "..x)
              break
            end
          end
        end
        layer[tostring(block.current.set[i].y)].finished = true --Set the layer as done
      end
      --Destroy layers which are full
      for k,v in pairs(layer) do
        if layer[k].full then
          print("Destroying layer "..k)
          for x = 0, (grid.width - 1) do
            block.stored[tostring(x).."/"..tostring(k)] = nil
          end
          table.insert(layer.destroyed, tonumber(k)) --Need to change it to a number so that it can be correctly sorted later
        end
      end
      table.sort(layer.destroyed) --Sort the table, lowest first, so that the top is pulled down first, then the ones below it as to not leave empty lines
      --print("Layers destroyed are: "..table.concat(layer.destroyed, ", "))
      --Shift down destroyed layers
      for i,v in ipairs(layer.destroyed) do
        --print("Starting at line "..v)
        for y = v-1, 0, -1 do
          --print(" Starting to shift down line "..y)
          local blockExists = 0
          for x = 0, (grid.width - 1) do
            if block.stored[tostring(x).."/"..tostring(y)] ~= nil then --Bring down blocks that exist
              blockExists = blockExists + 1
              block.stored[tostring(x).."/"..tostring(y+1)] = {x = block.stored[tostring(x).."/"..tostring(y)].x, y = block.stored[tostring(x).."/"..tostring(y)].y + 1 , color = block.stored[tostring(x).."/"..tostring(y)].color}
              block.stored[tostring(x).."/"..tostring(y)] = nil --Get rid of the old block
              --print("   Shifting down block at ["..x..","..y.."]".."; new pos at ["..x..","..(y+1).."]")
            --else
              --print("   Not shifting down block "..x)
            end
          end
          if blockExists == 0 then --If there are no blocks in a line, stop destroying lines
            break
          end
        end
      end
      --Update game gravity after clearing lines
      game.linesCleared = game.linesCleared + #layer.destroyed
      game.gravity.max = 0.5/math.floor((game.linesCleared+10)/10)
      game.gravity.normal, game.gravity.softDrop = game.gravity.max, (game.gravity.max/game.gravity.softDropMulti)
      --Stuff for the animation which plays when the player clears a line
      if #layer.destroyed == 4 then
        animation.lineClear.message = "Quadruple!"
      elseif #layer.destroyed == 3 then
        animation.lineClear.message = "Triple!"
      elseif #layer.destroyed == 2 then
        animation.lineClear.message = "Double!"
      elseif #layer.destroyed == 1 then
        animation.lineClear.message = "Single!"
      end
      if #layer.destroyed > 0 then
        animation.lineClear.fade = 0.5
        game.currentCombo = game.currentCombo + 1
      else
        game.currentCombo = 0
      end
      print("Checked line destruction @ "..love.timer.getTime())
      game.event.setBlock = false
    end

    if animation.lineClear.fade >= 0 then
      animation.lineClear.fade = animation.lineClear.fade - dt
    end

    --Block Spawning--
    if block.current.active == false then
      --Pick random tetrominoes if there are none
      if next(tetromino.nextList) == nil then
        for i=1,tetromino.nextMax+1 do --Adding one because we remove one just after this, thus keeping the max at its correct number
          tetromino.nextList[i] = tetromino.list[math.random(1, 7)]
        end
      else
        tetromino.nextList[table.getn(tetromino.nextList)+1] = tetromino.list[math.random(1, 7)]
      end
      local nextTetromino = tetromino.nextList[1]
      table.remove(tetromino.nextList, 1)

      --Create the blocks
      for i,v in ipairs(tetromino.shapes[nextTetromino].form[1]) do
        block.current.set[i] = {
          x = tetromino.shapes[nextTetromino].form[1][i].x + grid.tetrominoStartingPosition,
          y = tetromino.shapes[nextTetromino].form[1][i].y - 3
        }
      end
      block.current.active, block.current.rotation, block.current.color, block.current.tetromino = true, 1, tetromino.shapes[nextTetromino].color, nextTetromino
      game.controls.denyMovement = false --Allow the player to move again after a hard drop
      game.controls.holdUsed = false
      print("Recieved new block @ "..love.timer.getTime())
      ltrs.updateHardDrop()
    end

    --Controls--
    --Rotation--
    --This could also be made more efficient.
    if love.keyboard.isDown("x") and block.current.tetromino ~= "o" and not game.controls.keypress.rotate and not game.controls.denyMovement then --You wouldn't rotate an "o" tetromino...
      print("Starting Rotation...")
      local newRotation
      if block.current.rotation < 4 then
        newRotation = block.current.rotation + 1
      else
        newRotation = 1
      end
      print("New rotation is "..newRotation)
      local rotatePos = ltrs.testRotation(block.current.set, block.current.tetromino, block.current.rotation, newRotation)
      if rotatePos ~= false then
        block.current.set = rotatePos
        block.current.rotation = newRotation
        print("Rotation succeeded!")
      else
        print("Rotation failed!")
      end
      game.controls.keypress.rotate = true
      ltrs.updateHardDrop()
    end
    if love.keyboard.isDown("z") and block.current.tetromino ~= "o" and not game.controls.keypress.rotate and not game.controls.denyMovement then --You wouldn't rotate an "o" tetromino... again
      print("Starting Rotation...")
      local newRotation
      if block.current.rotation > 1 then
        newRotation = block.current.rotation - 1
      else
        newRotation = 4
      end
      print("New rotation is "..newRotation)
      local rotatePos = ltrs.testRotation(block.current.set, block.current.tetromino, block.current.rotation, newRotation)
      if rotatePos ~= false then
        block.current.set = rotatePos
        block.current.rotation = newRotation
        print("Rotation succeeded!")
      else
        print("Rotation failed!")
      end
      game.controls.keypress.rotate = true
      ltrs.updateHardDrop()
    end

    if not love.keyboard.isDown("x") and not love.keyboard.isDown("z") and game.controls.keypress.rotate then
      game.controls.keypress.rotate = false
    end

    --Left and Right--
    --Is this efficient? I don't think so. Will I do it? Yes.
    if love.keyboard.isDown("left") and (love.timer.getTime() - game.controls.pressStart) >= game.controls.pressDelay and block.current.active and not ltrs.blockCollides(block.current.set, "left") and not ltrs.blockCollides(block.current.set, "leftedge") and not game.controls.denyMovement then
      for i=1,4 do
        block.current.set[i].x = block.current.set[i].x - 1
      end
      game.controls.pressStart = love.timer.getTime()
      if game.controls.pressDelay >= 0.05 then --Don't speed up too much
        game.controls.pressDelay = game.controls.pressDelay / 2 --Decrease the delay between the time when the block moves when holding a movement key
      end
      print("Moved left!")
      ltrs.updateHardDrop()
    elseif love.keyboard.isDown("right") and (love.timer.getTime() - game.controls.pressStart) >= game.controls.pressDelay and block.current.active and not ltrs.blockCollides(block.current.set, "right") and not ltrs.blockCollides(block.current.set, "rightedge") and not game.controls.denyMovement then
      for i=1,4 do
        block.current.set[i].x = block.current.set[i].x + 1
      end
      game.controls.pressStart = love.timer.getTime()
      if game.controls.pressDelay >= 0.05 then
        game.controls.pressDelay = game.controls.pressDelay / 2
      end
      print("Moved right!")
      ltrs.updateHardDrop()
    end
    if not love.keyboard.isDown("left") and not love.keyboard.isDown("right") then --Reset the press cooldown and delay when nothing is pressed down
      game.controls.pressStart = 0
      game.controls.pressDelay = 0.25
    end

    --Soft Drop--
    if love.keyboard.isDown("down") then
      game.gravity.max = game.gravity.softDrop
    elseif not love.keyboard.isDown("down") then
      game.gravity.max = game.gravity.normal
    end

    --Hard Drop--
    if love.keyboard.isDown("up") and not game.controls.keypress.up and next(block.current.set) ~= nil then
      print("Up pressed @ "..love.timer.getTime())
      block.current.set = block.hardDropPos
      block.hardDropPos = {}
      game.controls.keypress.up = true
      game.controls.denyMovement = true --Deny movement after hard dropping
      game.event.setBlock = true
    end

    if not love.keyboard.isDown("up") and game.controls.keypress.up then --Reset hard drop key
      game.controls.keypress.up = false
    end

    --Hold--
    if love.keyboard.isDown("space") and not game.controls.keypress.space and not game.controls.holdUsed then
      local nextHeld = block.current.tetromino
      local newTetromino
      if block.current.held == nil then --We need to create a new block
        tetromino.nextList[table.getn(tetromino.nextList)+1] = tetromino.list[math.random(1, 7)]
        newTetromino = tetromino.nextList[1]
        table.remove(tetromino.nextList, 1)
      else --We'll just get the new block from the one that's held
        newTetromino = block.current.held
      end
      for i,v in ipairs(tetromino.shapes[newTetromino].form[1]) do
        block.current.set[i] = {
          x = tetromino.shapes[newTetromino].form[1][i].x + grid.tetrominoStartingPosition,
          y = tetromino.shapes[newTetromino].form[1][i].y - 3
        }
      end
      block.current.active, block.current.rotation, block.current.color, block.current.tetromino = true, 1, tetromino.shapes[newTetromino].color, newTetromino
      block.current.held = nextHeld
      ltrs.updateHardDrop()
      game.controls.holdUsed = true
    end

    if not love.keyboard.isDown("space") and game.controls.keypress.space then --Reset hold key
      game.controls.keypress.space = false
    end

    --Lose conditions
    if block.stored[tostring(grid.tetrominoStartingPosition).."/-2"] ~= nil
      or block.stored[tostring(grid.tetrominoStartingPosition+1).."/-2"] ~= nil
      or block.stored[tostring(grid.tetrominoStartingPosition+2).."/-2"] ~= nil
      or block.stored[tostring(grid.tetrominoStartingPosition+3).."/-2"] ~= nil then --Eventually, add a gameover sequence to losing
      print("Game over!\nYou cleared "..game.linesCleared.." lines!")
      game.isPaused = true
    end
  end
end

function love.draw(dt)
  love.graphics.setNewFont(12)
  love.graphics.draw(bggrid.img,bggrid.quad,0,0) --Draw the background grid

  --Block drawing
  love.graphics.push()
    love.graphics.scale(grid.scaleFactor.width/block.data.width) --Adaptive window rescaling
    if block.current.active == true and next(block.hardDropPos) ~= nil then
      love.graphics.setColor(block.current.color[1], block.current.color[2], block.current.color[3], 0.5)
      for i=1,4 do
        love.graphics.draw(block.data.imgShade, block.hardDropPos[i].x * block.data.width, block.hardDropPos[i].y * block.data.height)
      end
    end
    for k,v in pairs(block.stored) do
      love.graphics.setColor(block.stored[k].color)
      love.graphics.draw(block.data.img, block.stored[k].x * block.data.width, block.stored[k].y * block.data.height)
    end
    if block.current.active == true and next(block.current.set) ~= nil then
      love.graphics.setColor(block.current.color)
      for i=1,4 do
        love.graphics.draw(block.data.img, block.current.set[i].x * block.data.width, block.current.set[i].y * block.data.height)
      end
    end
    love.graphics.setColor(1,1,1,1)
  love.graphics.pop()

  --Other stuff
  love.graphics.print(love.timer.getFPS().." fps")
  love.graphics.print("Block Size: "..grid.scaleFactor.width.."px\nNext Blocks: "..table.concat(tetromino.nextList,", ").."\nCurrent Tetromino: "..tostring(block.current.tetromino).."\nBlock Held: "..tostring(block.current.held).."\nLines Cleared: "..tostring(game.linesCleared), 100, 124)
  if animation.quitMessage then
    love.graphics.print("Quitting in "..math.abs(math.ceil(quittimer)).."...", 100, 100)
  end

  --Line clear animation
  if animation.lineClear.fade > 0 then
    love.graphics.setColor(1,1,1,math.abs(animation.lineClear.fade))
    love.graphics.setFont(font.hobo.h3)
    love.graphics.print(animation.lineClear.message, (window.width/2)-(font.hobo.h3:getWidth(animation.lineClear.message)/2), (window.height/2)-(font.hobo.h3:getAscent()/2))
    if game.currentCombo > 1 then
      love.graphics.setFont(font.hobo.h4)
      love.graphics.print(tostring(game.currentCombo).." Combo!", (window.width/2)-(font.hobo.h4:getWidth(tostring(game.currentCombo).." Combo!")/2), (window.height/2)+(font.hobo.h3:getAscent()))
    end
  end

  love.graphics.setColor(1,1,1,1)
  love.graphics.setFont(font.hobo.h2)
  --Pause text
  if game.isPaused and game.started then
    love.graphics.print("Paused!", (window.width/2)-(font.hobo.h2:getWidth("Paused!")/2), (window.height/2)-(font.hobo.h2:getAscent()/2))
  end

  --Countdown timer
  if countdownTimer ~= nil and not (countdownTimer >= 3) and not game.isPaused then
    love.graphics.print(math.ceil(countdownTimer), (window.width/2)-(font.hobo.h2:getWidth(math.ceil(countdownTimer))/2), (window.height/2)-(font.hobo.h2:getAscent()/2)) --Centering is hard
  elseif countdownTimer >= 3 and countdownTimer <= 4 and not game.isPaused then
    love.graphics.print("Go!", (window.width/2)-(font.hobo.h2:getWidth("Go!")/2), (window.height/2)-(font.hobo.h2:getAscent()/2))
  end
end

function love.quit()
  print("The game is now done.")
end
