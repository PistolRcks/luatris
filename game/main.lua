debug = true
function love.load(arg)
  window = {}
  window.width, window.height, window.flags = love.window.getMode()

  block = {img = love.graphics.newImage("assets/tiles/block.png")}
  block.width, block.height = block.img:getDimensions()
  currentblock = {x = 0, y = 0, rotation = 0, active = true} --x and y are relative to the grid position

  grid = {width = 10, height=20}
  grid.scaleFactor = {width = window.width/grid.width, height = window.height/grid.height}
  bggrid = {img = love.graphics.newImage("assets/tiles/backgroundgrid.png")}
  bggrid.quad = love.graphics.newQuad(0,0,window.width,window.height,grid.scaleFactor.width,grid.scaleFactor.width)
  bggrid.img:setWrap("repeat","repeat")

  game = {controls = {pressStart = 0},
          gravity = {tick = nil, max = 0.5},
          isPaused = nil, started = false}

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

  if game.started == false then --Do starting timer later, currently need to get to sleep
    if countdownTimerStart == nil then
      countdownTimerStart = love.timer.getTime()
    end
    countdownTimer = love.timer.getTime() - countdownTimerStart
    if countdownTimer > 4 then
      countdownTimerStart = nil
      game.started = true
      game.isPaused = false
    end
  end

  if game.isPaused == false and game.started == true then
    --Gravity--
    if game.gravity.tick == nil then
      game.gravity.tick = love.timer.getTime()
    elseif (love.timer.getTime() - game.gravity.tick) >= game.gravity.max then
      if currentblock.y == 19 then
        --Set the block and get a new Block
        currentblock.active = false
      else
        currentblock.y = currentblock.y + 1
        game.gravity.tick = love.timer.getTime()
      end
    end

    --Controls--
    if love.keyboard.isDown("left") and (love.timer.getTime() - game.controls.pressStart) >= 0.25 and currentblock.x > 0 and currentblock.active == true then
      currentblock.x = currentblock.x - 1
      game.controls.pressStart = love.timer.getTime()
    elseif love.keyboard.isDown("right") and (love.timer.getTime() - game.controls.pressStart) >= 0.25 and currentblock.x < grid.width - 1 and currentblock.active == true then -- -1 because there are 10 available grid spots (0-9), but 10 goes off the window
      currentblock.x = currentblock.x + 1
      game.controls.pressStart = love.timer.getTime()
    end
    if not love.keyboard.isDown("left") and not love.keyboard.isDown("right") then --Reset the press cooldown when nothing is pressed down
      game.controls.pressStart = 0
    end
  end
end

function love.draw(dt)
  love.graphics.setNewFont(12)
  love.graphics.draw(bggrid.img,bggrid.quad,0,0)
  love.graphics.push()
    love.graphics.scale(grid.scaleFactor.width/block.width) --Adaptive window rescaling
    love.graphics.draw(block.img, currentblock.x * block.width, currentblock.y * block.height)
  love.graphics.pop()
  love.graphics.print(love.timer.getFPS().." fps")

  if countdownTimer ~= nil and not (countdownTimer >= 3) then
    love.graphics.setFont(font.hobo.h2)
    love.graphics.print(math.ceil(countdownTimer), (window.width/2)-(font.hobo.h2:getWidth(math.ceil(countdownTimer))/2), (window.height/2)-(font.hobo.h2:getAscent()/2)) --Centering is hard
  elseif countdownTimer >= 3 and countdownTimer <= 4 then
    love.graphics.setFont(font.hobo.h2)
    love.graphics.print("Go!", (window.width/2)-(font.hobo.h2:getWidth("Go!")/2), (window.height/2)-(font.hobo.h2:getAscent()/2))
  end
  love.graphics.setNewFont(12)
  love.graphics.print("Block Grid X: "..currentblock.x.." Block Size: "..grid.scaleFactor.width.."px", 100, 124)
  if quitmessage then
    love.graphics.print("Quitting in "..math.abs(math.ceil(quittimer)).."...", 100, 100)
  end
end

function love.quit()
  print("The game is now done.")
end
