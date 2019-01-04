--TODO: Optimize and garbage collect; draw function is taking up a lot of memory (ok I really don't know what's going on)
--TODO: Create animation management system

function love.load(arg)
  require("lib/ltrs")
  require("lib/util")
  require("lib/gfx")
  math.randomseed(os.time()) --Set the seed because Lua is pseudorandom
  love.graphics.setDefaultFilter("nearest", "nearest")

  window = {}
  window.width, window.height, window.flags = love.window.getMode()

  --Load spritesheets
  sprite = {main = {img = love.graphics.newImage("assets/tiles/mainSpritesheet.png"), sheet = {}}}
  for x=1,7 do --The spritesheet supports 64 sprites, but we're currently only using 7.
    sprite.main.sheet[x] = love.graphics.newQuad((x-1)*8, 0, 8, 8, 64, 64)
  end

  block = {
    data = {},
    current = {set = {}, color = {}, rotation = 1, active = false, tetromino = nil, held = nil},
    stored = {},
    hardDropPos = {}
  }
  block.data.width, block.data.height = 8, 8

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
    nextList = {}
  }
  grid = {width = 10, height = 20}
  grid.playfield = {height = window.height * 0.9} --The playfield's width will be based off of this because its height will always be centered on the window, whereas the width will not
  grid.playfield.width = (grid.playfield.height * grid.width) / grid.height --Good ol' cross multiplication solves this scaling problem

  grid.scaleFactor = {width = math.ceil(grid.playfield.width/grid.width), height = math.ceil(grid.playfield.height/grid.height)}
  grid.tetrominoStartingPosition = math.floor((grid.width - 4) / 2)

  bggrid = {edgeImg = love.graphics.newImage("assets/tiles/playfieldedge.png"), cornerImg = love.graphics.newImage("assets/tiles/playfieldcorner.png")}

  bggrid.canvas = love.graphics.newCanvas(8,8)
  love.graphics.setCanvas(bggrid.canvas) --Create the texture canvas to make the sprite able to be used in a spriteBatch
    love.graphics.draw(sprite.main.img, sprite.main.sheet[3])
  love.graphics.setCanvas()

  bggrid.spriteBatch = love.graphics.newSpriteBatch(bggrid.canvas)
  for y=0, (grid.height-1) do
    for x=0, (grid.width-1) do
      bggrid.spriteBatch:add(x*8,y*8)
    end
  end

  bggrid.vertEdgeQuad = love.graphics.newQuad(0, 0, grid.scaleFactor.width, grid.playfield.height, grid.scaleFactor.width, grid.scaleFactor.width)
  bggrid.horizEdgeQuad = love.graphics.newQuad(0, 0, grid.scaleFactor.width, grid.playfield.width, grid.scaleFactor.width, grid.scaleFactor.width)

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
    timePlayed = 0,
    gravity = {tick = nil, groundTimer = 0, groundMax = 0.5, softDrop = 0.01667}, --TODO: Eventually, the gravity max and the ground max will be adaptive based on the current level
    isPaused = false, started = false
  }
  game.gravity.max = 0.5/math.floor((game.linesCleared+10)/10) --Early difficulty implementation
  game.gravity.normal = game.gravity.max

  animation = {
    quitMessage = false,
    lineClear = {message = nil, fade = 0}
  }

  local textScaleFactor = math.max(window.width, window.height) * 0.001

  font = {
    hobo = {
      h2 = love.graphics.newFont("/assets/fonts/hobo.ttf", math.min(64, math.ceil(64 * textScaleFactor))),
      h3 = love.graphics.newFont("/assets/fonts/hobo.ttf", math.min(48, math.ceil(48 * textScaleFactor))),
      h4 = love.graphics.newFont("/assets/fonts/hobo.ttf", math.min(32, math.ceil(32 * textScaleFactor)))
    }
  }
end

function love.update(dt)
  --Utilities
  --TODO: EVENTUALLY, dynamic rescaling will be re-added in, but for now, that's too much hassle.
  --window.width, window.height, window.flags = love.window.getMode() --Setting this in the update function for adaptive window resizing (which really doesn't work correctly as of right now)
  --grid.scaleFactor = {width = window.width/grid.width, height = window.height/grid.height}

  if not love.keyboard.isDown("escape") then --Reset stuff
    quittimer = 3
    animation.quitMessage = false
    game.controls.keypress.esc = false
  end
  if love.keyboard.isDown("escape") then
    --Game pausing
    if not game.controls.keypress.esc and game.started then
      game.isPaused = not game.isPaused
      --collectgarbage("collect")
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

  --Main Game Loop--
  if game.isPaused == false and game.started == true then
    --Game timer
    game.timePlayed = game.timePlayed + dt

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
      game.gravity.normal = game.gravity.max
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
      --collectgarbage("collect") --This should stem the flow of the memory leak issue until I figure out what's the problem
    end

    if animation.lineClear.fade >= 0 then
      animation.lineClear.fade = animation.lineClear.fade - dt
    end

    --Block Spawning--
    if block.current.active == false then
      ltrs.bagShuffle() --See util/ltrs.lua for more
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
        ltrs.bagShuffle()
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

--Pause the game on focus lost
function love.focus(f)
  if f == false then
    game.isPaused = true
  end
end

function love.draw(dt)
  local offset = window.height * 0.05
  local scalar = grid.scaleFactor.width/block.data.width
  local scalarOffset = offset/scalar --When scaling, the x and y positions are scaled with the scalar. To circumvent this, we'll use this
  local draw = love.graphics.draw --Saves cycles

  love.graphics.setColor(0.1,0.1,0.1,1)
  love.graphics.rectangle("fill", 0, 0, window.width, window.height) --This will eventually be able to be customized, and you will be able to choose your own background
  love.graphics.setColor(1,1,1,1)
  --Draw the edges of the playfield
  local edgeOffset = grid.scaleFactor.width
  local widthLength = grid.playfield.width + offset
  bggrid.edgeImg:setWrap("clamp","repeat")
  draw(bggrid.edgeImg, bggrid.vertEdgeQuad, offset - edgeOffset, offset) --Left edge
  draw(bggrid.edgeImg, bggrid.vertEdgeQuad, widthLength + edgeOffset, offset, 0, -1, 1) --Right edge
  bggrid.edgeImg:setWrap("repeat","clamp")
  draw(bggrid.edgeImg, bggrid.horizEdgeQuad, widthLength, offset - edgeOffset, math.pi/2) --Top edge
  draw(bggrid.edgeImg, bggrid.horizEdgeQuad, offset, grid.playfield.height + offset + edgeOffset, math.pi/2, -1, -1) --Bottom edge

  --Block drawing
  love.graphics.push()
    love.graphics.scale(scalar) --Adaptive window rescaling
    love.graphics.setColor(0.5,0.5,0.5,1)
    draw(bggrid.spriteBatch, scalarOffset, scalarOffset) --Draw the background grid
    love.graphics.setColor(1,1,1,1)
    --Draw grid corners
    local scalarEdgeOffset = edgeOffset/scalar
    local scalarWidthLength = widthLength/scalar
    local scalarHeightLength = (grid.playfield.height + offset)/scalar
    draw(sprite.main.img, sprite.main.sheet[4], scalarOffset - scalarEdgeOffset, scalarOffset - scalarEdgeOffset) --Top-left
    --draw(heldImg, scalarWidthLength, scalarOffset - scalarEdgeOffset*(3/8)) --Hold indicator (is in the top-right corner)
    --[[gfx.drawMultisprite(sprite.main.img, sprite.main.sheet,
    {
      {{5, math.pi/2, 1, 1}, {5, math.pi/2, 1, 1}, {5, math.pi/2, 1, 1}, {4, math.pi, 1, 1}},
      {7, 7, 7, {5, 0, -1, 1}},
      {6, 7, {6, math.pi, 1, 1}, {5, 0, -1, 1}},
      {{5, math.pi/2, 1, -1}, {5, math.pi/2, 1, -1}, {5, math.pi/2, 1, -1}, {4, 0, -1, -1}},
    }, {scalarWidthLength, scalarOffset - scalarEdgeOffset})]]
    draw(sprite.main.img, sprite.main.sheet[4], scalarOffset - scalarEdgeOffset, scalarHeightLength + scalarEdgeOffset, 0, 1, -1) --Bottom-left
    draw(sprite.main.img, sprite.main.sheet[4], scalarWidthLength + scalarEdgeOffset, scalarHeightLength + scalarEdgeOffset, 0, -1, -1) --Bottom-right
    --Draw hard drop shade
    if block.current.active == true and next(block.hardDropPos) ~= nil then
      love.graphics.setColor(block.current.color[1], block.current.color[2], block.current.color[3], 0.5)
      for i=1,4 do
        draw(sprite.main.img, sprite.main.sheet[3], (block.hardDropPos[i].x * block.data.width) + scalarOffset, (block.hardDropPos[i].y * block.data.height) + scalarOffset)
      end
    end
    --Draw stored blocks
    for k,v in pairs(block.stored) do
      if block.stored[k].y >= 0 then --Blocks shouldn't render above the threshold
        love.graphics.setColor(block.stored[k].color)
        draw(sprite.main.img, sprite.main.sheet[2], (block.stored[k].x * block.data.width) + scalarOffset, (block.stored[k].y * block.data.height) + scalarOffset)
      end
    end
    --Draw active blocks
    if block.current.active == true and next(block.current.set) ~= nil then
      love.graphics.setColor(block.current.color)
      for i=1,4 do
        if block.current.set[i].y >= 0 then
          draw(sprite.main.img, sprite.main.sheet[2], (block.current.set[i].x * block.data.width) + scalarOffset, (block.current.set[i].y * block.data.height) + scalarOffset)
        end
      end
      --Draw some white over the blocks when touching the ground
      if game.gravity.groundTimer > 0 then
        love.graphics.setColor(1,1,1,game.gravity.groundTimer/game.gravity.groundMax)
        for i=1,4 do
          if block.current.set[i].y >= 0 then
            draw(sprite.main.img, sprite.main.sheet[2], (block.current.set[i].x * block.data.width) + scalarOffset, (block.current.set[i].y * block.data.height) + scalarOffset)
          end
        end
      end
    end
    love.graphics.setColor(1,1,1,1)
  love.graphics.pop()

  if animation.quitMessage then
    love.graphics.print("Quitting in "..math.abs(math.ceil(quittimer)).."...", 100, 100)
  end

  --Statistics
  local stats = love.graphics.getStats()
  love.graphics.setFont(font.hobo.h4)
  love.graphics.print(love.timer.getFPS().." fps\nBlock Size: "..grid.scaleFactor.width.."px\nDraw Calls: "..stats.drawcalls.."\nTexture Memory: "..string.format("%.2f MB", stats.texturememory/1024/1024))
  love.graphics.print("Time Played: "..string.format("%2.1f",game.timePlayed).." sec\nNext Blocks: "..table.concat(tetromino.nextList,", ").."\nCurrent Tetromino: "..tostring(block.current.tetromino).."\nBlock Held: "..tostring(block.current.held).."\nLines Cleared: "..tostring(game.linesCleared)..string.format("\nGravity: %.2fG", game.gravity.normal*60), math.floor(window.width*0.67), math.floor(offset))

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
