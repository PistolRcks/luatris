--[[TODO: Spawn tetrominoes and put their coordinates and color in block.current.set
          Multiple block movement
  ]]
debug = true

function anyBlockCollides(set, direction)
   for i,v in ipairs(set) do
     if direction == "above" then
       if block.stored[tostring(set[i].x)..tostring(set[i].y-1)] ~= nil then return true end
     elseif direction == "below" then
       if block.stored[tostring(set[i].x)..tostring(set[i].y+1)] ~= nil then return true end
     elseif direction == "left" then
       if block.stored[tostring(set[i].x-1)..tostring(set[i].y)] ~= nil then return true end
     elseif direction == "right" then
       if block.stored[tostring(set[i].x+1)..tostring(set[i].y)] ~= nil then return true end
     elseif direction == "leftedge" then
       if set[i].x-1 == -1 then return true end
     elseif direction == "rightedge" then
       if set[i].x+1 == grid.width then return true end
     elseif direction == "bottom" then
       if set[i].y == grid.height - 1 then return true end
     end
   end
   return false
end

function love.load(arg)
  window = {}
  window.width, window.height, window.flags = love.window.getMode()

  block = {
    data = {img = love.graphics.newImage("assets/tiles/block.png")},
    current = {set = {}, rotation = 0, active = false},
    stored = {}
  }
  block.data.width, block.data.height = block.data.img:getDimensions()

  tetromino = {
    shapes = {--Offset all shapes by the top-left corner of a 2x4 rectangle
      i = {color = {0,1,1,1}, form = {                                  -- oooo
        {x = 0, y = 1}, {x = 1, y = 1}, {x = 2, y = 1}, {x = 3, y = 1}  -- xxxx
      }},
      o = {color = {1,1,0,1}, form = {                                  -- oxxo
        {x = 1, y = 0}, {x = 2, y = 0}, {x = 1, y = 1}, {x = 2, y = 1}  -- oxxo
      }},
      j = {color = {0,0,1,1}, form = {                                  -- xooo
        {x = 0, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}, {x = 2, y = 1}  -- xxxo
      }},
      l = {color = {1,0.667,0,1}, form = {                              -- ooox
        {x = 3, y = 0}, {x = 1, y = 1}, {x = 2, y = 1}, {x = 3, y = 1}  -- oxxx
      }},
      s = {color = {0,1,0,1}, form = {                                  -- ooxx
        {x = 2, y = 0}, {x = 3, y = 0}, {x = 1, y = 1}, {x = 2, y = 1}  -- oxxo
      }},
      z = {color = {1,0,0,1}, form = {                                  -- xxoo
        {x = 0, y = 0}, {x = 1, y = 0}, {x = 1, y = 1}, {x = 2, y = 1}  -- oxxo
      }},
      t = {color = {0.667,0,1,1}, form = {                              -- oxoo
        {x = 1, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}, {x = 2, y = 1}  -- xxxo
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
      if anyBlockCollides(block.current.set, "bottom") or anyBlockCollides(block.current.set, "below") then
        --Store the block and get a new one. Each block's data is stored in block.stored with a key which is a concatenation of its xcoord and ycoord.
        block.current.active = false
        for i,v in ipairs(block.current.set) do
          block.stored[tostring(block.current.set[i].x)..tostring(block.current.set[i].y)] = {x = block.current.set[i].x, y = block.current.set[i].y, color = block.current.color} --This will eventually have to be done for every block in a tetromino
        end
      else
        for i,v in ipairs(block.current.set) do
          print("["..tostring(block.current.set[i].x)..", "..tostring(block.current.set[i].y).."]")
        end
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
      for i,v in ipairs(tetromino.shapes[nextTetromino].form) do
        block.current.set[i] = {
          x = tetromino.shapes[nextTetromino].form[i].x + grid.tetrominoStartingPosition,
          y = tetromino.shapes[nextTetromino].form[i].y - 2
        }
      end
      block.current.active, block.current.rotation, block.current.color = true, 0, tetromino.shapes[nextTetromino].color
    end

    --Controls--
    --Left and Right--
    --Is this efficient? I don't think so. Will I do it? Yes.
    if love.keyboard.isDown("left") and (love.timer.getTime() - game.controls.pressStart) >= 0.25 and block.current.active == true and not anyBlockCollides(block.current.set, "left") and not anyBlockCollides(block.current.set, "leftedge") then
      for i=1,4 do
        block.current.set[i].x = block.current.set[i].x - 1
      end
      game.controls.pressStart = love.timer.getTime()
    elseif love.keyboard.isDown("right") and (love.timer.getTime() - game.controls.pressStart) >= 0.25 and block.current.active == true and not anyBlockCollides(block.current.set, "right") and not anyBlockCollides(block.current.set, "rightedge") then
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
      love.graphics.setColor(1,1,1,1)
    end
    for k,v in pairs(block.stored) do
      love.graphics.setColor(block.stored[k].color)
      love.graphics.draw(block.data.img, block.stored[k].x * block.data.width, block.stored[k].y * block.data.height)
    end
    love.graphics.setColor(1,1,1,1)
  love.graphics.pop()
  love.graphics.print(love.timer.getFPS().." fps")
  love.graphics.print("Block Size: "..grid.scaleFactor.width.."px\nNext Blocks: "..table.concat(tetromino.nextList,", "), 100, 124)
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
