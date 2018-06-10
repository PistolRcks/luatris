debug = true
function love.load(arg)
  window = {}
  window.width, window.height, window.flags = love.window.getMode()

  block = {data = {img = love.graphics.newImage("assets/tiles/block.png")},
          current = {x = 4, y = 0, color = nil, rotation = 0, active = false}, --x and y are relative to the grid position
          positional = {},
          stored = {}}
  block.data.width, block.data.height = block.data.img:getDimensions()

  grid = {width = 10, height=20}
  grid.scaleFactor = {width = window.width/grid.width, height = window.height/grid.height}

  bggrid = {img = love.graphics.newImage("assets/tiles/backgroundgrid.png")}
  bggrid.quad = love.graphics.newQuad(0,0,window.width,window.height,grid.scaleFactor.width,grid.scaleFactor.width)
  bggrid.img:setWrap("repeat","repeat")

  game = {controls = {pressStart = 0},
          gravity = {tick = nil, max = 0.5},
          isPaused = nil, started = false}
  game.gravity.normal, game.gravity.double = game.gravity.max, game.gravity.max/2

  font = {hobo = {h2 = love.graphics.newFont("/assets/fonts/hobo.ttf", 64)}}
end

function love.update(dt)
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

  if game.isPaused == false and game.started == true then
    block.positional.above = tostring(block.current.x)..tostring(block.current.y-1)
    block.positional.below = tostring(block.current.x)..tostring(block.current.y+1)
    block.positional.left = tostring(block.current.x-1)..tostring(block.current.y)
    block.positional.right = tostring(block.current.x+1)..tostring(block.current.y)
    --Gravity--
    if game.gravity.tick == nil then
      game.gravity.tick = love.timer.getTime()
    elseif (love.timer.getTime() - game.gravity.tick) >= game.gravity.max and block.current.active == true then
      if block.current.y == 19 or block.stored[block.positional.below] ~= nil then
        --Store the block and get a new one
        block.current.active = false
        block.stored[tostring(block.current.x)..tostring(block.current.y)] = {x = block.current.x, y = block.current.y, color = block.current.color} --This will eventually have to be done for every block in a tetromino
      else
        block.current.y = block.current.y + 1
        game.gravity.tick = love.timer.getTime()
      end
    end

    --Block Spawning--
    if block.current.active == false then
      --TODO: Pick a random tetromino
      block.current.x, block.current.y, block.current.active, block.current.rotation = 4, 0, true, 0
    end

    --Controls--
    if love.keyboard.isDown("left") and (love.timer.getTime() - game.controls.pressStart) >= 0.25 and block.current.x > 0 and block.current.active == true and block.stored[block.positional.left] == nil then
      block.current.x = block.current.x - 1
      game.controls.pressStart = love.timer.getTime()
    elseif love.keyboard.isDown("right") and (love.timer.getTime() - game.controls.pressStart) >= 0.25 and block.current.x < grid.width - 1 and block.current.active == true and block.stored[block.positional.right] == nil then -- -1 because there are 10 available grid spots (0-9), but 10 goes off the window
      block.current.x = block.current.x + 1
      game.controls.pressStart = love.timer.getTime()
    end
    if not love.keyboard.isDown("left") and not love.keyboard.isDown("right") then --Reset the press cooldown when nothing is pressed down
      game.controls.pressStart = 0
    end
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
      love.graphics.draw(block.data.img, block.current.x * block.data.width, block.current.y * block.data.height)
    end
    love.graphics.setColor(1,0,0,1)
    for k,v in pairs(block.stored) do
      love.graphics.draw(block.data.img, block.stored[k].x * block.data.width, block.stored[k].y * block.data.height)
    end
    love.graphics.setColor(1,1,1,1)
  love.graphics.pop()
  love.graphics.print(love.timer.getFPS().." fps")
  love.graphics.print("Block Grid X: "..block.current.x.." Block Size: "..grid.scaleFactor.width.."px", 100, 124)
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
