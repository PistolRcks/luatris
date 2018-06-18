debug = true

function love.load(arg)
  require("ltrs")
  math.randomseed(os.time()) --Set the seed because the randomness would normally be uniform

  window = {}
  window.width, window.height, window.flags = love.window.getMode()

  block = {
    data = {img = love.graphics.newImage("assets/tiles/block.png")},
    current = {set = {}, rotation = 1, active = false, tetromino = nil},
    stored = {}
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
        {{x = 0, y = 1}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 2, y = 2}},   -- xxxo
        {{x = 1, y = 1}, {x = 1, y = 2}, {x = 1, y = 3}, {x = 2, y = 1}},   --
        {{x = 2, y = 3}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 2, y = 2}},   --
        {{x = 1, y = 1}, {x = 1, y = 2}, {x = 1, y = 3}, {x = 0, y = 3}}    --
      }},
      l = {color = {1,0.667,0,1}, form = {
        {{x = 2, y = 1}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 2, y = 2}},  -- oxxx
        {{x = 1, y = 1}, {x = 1, y = 2}, {x = 1, y = 3}, {x = 2, y = 3}},
        {{x = 0, y = 3}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 2, y = 2}},
        {{x = 1, y = 1}, {x = 1, y = 2}, {x = 1, y = 3}, {x = 0, y = 1}}
      }},
      s = {color = {0,1,0,1}, form = {
        {{x = 1, y = 1}, {x = 2, y = 1}, {x = 0, y = 2}, {x = 1, y = 2}},  -- oxxo
        {{x = 1, y = 1}, {x = 1, y = 2}, {x = 2, y = 2}, {x = 2, y = 3}},
        {{x = 1, y = 2}, {x = 2, y = 2}, {x = 0, y = 3}, {x = 1, y = 3}},
        {{x = 0, y = 1}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 1, y = 3}}
      }},
      z = {color = {1,0,0,1}, form = {
        {{x = 0, y = 1}, {x = 1, y = 1}, {x = 1, y = 2}, {x = 2, y = 2}},  -- oxxo
        {{x = 2, y = 1}, {x = 1, y = 2}, {x = 2, y = 2}, {x = 1, y = 3}},
        {{x = 0, y = 2}, {x = 1, y = 2}, {x = 1, y = 3}, {x = 2, y = 3}},
        {{x = 1, y = 1}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 0, y = 3}}
      }},
      t = {color = {0.667,0,1,1}, form = {                                 -- oxoo
        {{x = 1, y = 1}, {x = 0, y = 2}, {x = 1, y = 2}, {x = 2, y = 2}},  -- xxxo
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
  grid.tetrominoStartingPosition = ((grid.width - 4) / 2)

  bggrid = {img = love.graphics.newImage("assets/tiles/backgroundgrid.png")}
  bggrid.quad = love.graphics.newQuad(0,0,window.width,window.height,grid.scaleFactor.width,grid.scaleFactor.width)
  bggrid.img:setWrap("repeat","repeat")

  game = {
    controls = {pressStart = 0},
    gravity = {tick = nil, max = 0.25},
    isPaused = nil, started = false
  }
  game.gravity.normal, game.gravity.double = game.gravity.max, game.gravity.max/2

  font = {
    hobo = {
      h2 = love.graphics.newFont("/assets/fonts/hobo.ttf", 64)
    }
  }
end

function love.update(dt)
  --Utilities
  window.width, window.height, window.flags = love.window.getMode() --Setting this in the update function for adaptive window resizing
  grid.scaleFactor = {width = window.width/grid.width, height = window.height/grid.height}
  if not love.keyboard.isDown("escape") then --Reset stuff
    quittimer = 3
    quitmessage = false
  end
  if love.keyboard.isDown("escape") then --Good ol' hold-to-quit, thanks toby
    quitmessage = true
    quittimer = quittimer - dt
    if quittimer < 0 then
      love.event.push("quit")
    end
  end

  --Countdown at the beginning of the game
  if game.started == false then
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
    if game.gravity.tick == nil then
      game.gravity.tick = love.timer.getTime()
    elseif (love.timer.getTime() - game.gravity.tick) >= game.gravity.max and block.current.active == true then
      if ltrs.blockCollides(block.current.set, "bottom") or ltrs.blockCollides(block.current.set, "below") then
        --Store the block and get a new one. Each block's data is stored in block.stored with a key which is a concatenation of its xcoord and ycoord.
        block.current.active = false
        for i,v in ipairs(block.current.set) do
          block.stored[tostring(block.current.set[i].x)..tostring(block.current.set[i].y)] = {x = block.current.set[i].x, y = block.current.set[i].y, color = block.current.color} --This will eventually have to be done for every block in a tetromino
        end
      else
        --Debugging purposes
        --for i,v in ipairs(block.current.set) do
        --  print("["..tostring(block.current.set[i].x)..", "..tostring(block.current.set[i].y).."]")
        --end
        --Drop all blocks in the current set by one
        for i=1,4 do
          block.current.set[i].y = block.current.set[i].y + 1
        end
        game.gravity.tick = love.timer.getTime()
      end
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
      nextTetromino = tetromino.nextList[1] --For testing only.
      table.remove(tetromino.nextList, 1)

      --Create the blocks
      for i,v in ipairs(tetromino.shapes[nextTetromino].form[1]) do
        block.current.set[i] = {
          x = tetromino.shapes[nextTetromino].form[1][i].x + grid.tetrominoStartingPosition,
          y = tetromino.shapes[nextTetromino].form[1][i].y - 3
        }
      end
      block.current.active, block.current.rotation, block.current.color, block.current.tetromino = true, 1, tetromino.shapes[nextTetromino].color, nextTetromino
    end

    --Controls--
    --Rotation
    --This could also be made more efficient.
    if love.keyboard.isDown("x") and block.current.tetromino ~= "o" and not rotateHeld then --You wouldn't rotate an "o" tetromino...
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
      rotateHeld = true
    end
    if love.keyboard.isDown("z") and block.current.tetromino ~= "o" and not rotateHeld then --You wouldn't rotate an "o" tetromino... again
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
      rotateHeld = true
    end

    if not love.keyboard.isDown("x") and not love.keyboard.isDown("z") and rotateHeld then
      rotateHeld = false
    end

    --Left and Right--
    --Is this efficient? I don't think so. Will I do it? Yes.
    if love.keyboard.isDown("left") and (love.timer.getTime() - game.controls.pressStart) >= 0.25 and block.current.active == true and not ltrs.blockCollides(block.current.set, "left") and not ltrs.blockCollides(block.current.set, "leftedge") then
      for i=1,4 do
        block.current.set[i].x = block.current.set[i].x - 1
      end
      game.controls.pressStart = love.timer.getTime()
    elseif love.keyboard.isDown("right") and (love.timer.getTime() - game.controls.pressStart) >= 0.25 and block.current.active == true and not ltrs.blockCollides(block.current.set, "right") and not ltrs.blockCollides(block.current.set, "rightedge") then
      for i=1,4 do
        block.current.set[i].x = block.current.set[i].x + 1
      end
      game.controls.pressStart = love.timer.getTime()
    end
    if not love.keyboard.isDown("left") and not love.keyboard.isDown("right") then --Reset the press cooldown when nothing is pressed down
      game.controls.pressStart = 0
    end


    --Fast Drop--
    if love.keyboard.isDown("down") then
      game.gravity.max = game.gravity.double
    elseif not love.keyboard.isDown("down") then
      game.gravity.max = game.gravity.normal
    end
  end
end

function love.draw(dt)
  love.graphics.setNewFont(12)
  love.graphics.draw(bggrid.img,bggrid.quad,0,0)
  love.graphics.push()
    love.graphics.scale(grid.scaleFactor.width/block.data.width) --Adaptive window rescaling
    if block.current.active == true then
      love.graphics.setColor(block.current.color)
      for i=1,4 do
        love.graphics.draw(block.data.img, block.current.set[i].x * block.data.width, block.current.set[i].y * block.data.height)
      end
      love.graphics.setColor(1,0,0,0.5)
      love.graphics.draw(block.data.img, (block.current.set[1].x - tetromino.shapes[block.current.tetromino].form[block.current.rotation][1].x) * block.data.width, (block.current.set[1].y - tetromino.shapes[block.current.tetromino].form[block.current.rotation][1].y) * block.data.height)
      love.graphics.setColor(1,1,1,1)
    end
    for k,v in pairs(block.stored) do
      love.graphics.setColor(block.stored[k].color)
      love.graphics.draw(block.data.img, block.stored[k].x * block.data.width, block.stored[k].y * block.data.height)
    end
    love.graphics.setColor(1,1,1,1)
  love.graphics.pop()
  love.graphics.print(love.timer.getFPS().." fps")
  love.graphics.print("Block Size: "..grid.scaleFactor.width.."px\nNext Blocks: "..table.concat(tetromino.nextList,", ").."\nCurrent Tetromino: "..tostring(block.current.tetromino), 100, 124)
  if quitmessage then
    love.graphics.print("Quitting in "..math.abs(math.ceil(quittimer)).."...", 100, 100)
  end

  if countdownTimer ~= nil and not (countdownTimer >= 3) then
    love.graphics.setFont(font.hobo.h2)
    love.graphics.print(math.ceil(countdownTimer), (window.width/2)-(font.hobo.h2:getWidth(math.ceil(countdownTimer))/2), (window.height/2)-(font.hobo.h2:getAscent()/2)) --Centering is hard
  elseif countdownTimer >= 3 and countdownTimer <= 4 then
    love.graphics.setFont(font.hobo.h2)
    love.graphics.print("Go!", (window.width/2)-(font.hobo.h2:getWidth("Go!")/2), (window.height/2)-(font.hobo.h2:getAscent()/2))
  end
end

function love.quit()
  print("The game is now done.")
end
