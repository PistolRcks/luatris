debug = true
function love.load(arg)
  block = {img = love.graphics.newImage("assets/block.png")}
  block.width, block.height = block.img:getDimensions()
  currentblock = {x=0, y=0, rotation=0} --x and y are relative to the grid position
  grid = {width = 10, height=20} --Width with a '+ 1' because we need to account for being a tile which goes off the screen
  window = {}
  pressStart = 0
  love.graphics.setNewFont(12)
end

function love.update(dt)
  window.width, window.height, window.flags = love.window.getMode() --Setting this in the update function for adaptive window resizing
  if not love.keyboard.isDown("escape") then --Reset stuff
    quittimer = 3
    quitmessage = false
  end
  if love.keyboard.isDown("escape") then --Good ol' hold-to-quit
    quitmessage = true
    quittimer = quittimer - dt
    if quittimer < 0 then
      love.event.push("quit")
    end
  end
  if love.keyboard.isDown("left") and (love.timer.getTime() - pressStart) > 0.25 and currentblock.x > 0 then
    currentblock.x = currentblock.x - 1
    pressStart = love.timer.getTime()
  elseif love.keyboard.isDown("right") and (love.timer.getTime() - pressStart) > 0.25 and currentblock.x < grid.width - 1 then -- -1 because there are 10 available grid spots (0-9), but 10 goes off the window
    currentblock.x = currentblock.x + 1
    pressStart = love.timer.getTime()
  end

  if not love.keyboard.isDown("left") or not love.keyboard.isDown("right") then --Reset the press cooldown when nothing is pressed down
    pressCooldown = 0
  end
end

function love.draw(dt)
  love.graphics.push()
    blocksize = window.height/(grid.height)
    love.graphics.scale(blocksize/block.width) --Adaptive window rescaling
    love.graphics.draw(block.img, currentblock.x * block.width, currentblock.y * block.height)
  love.graphics.pop()
  love.graphics.print(love.timer.getFPS().." fps")
  love.graphics.print("Block Grid X: "..currentblock.x.." Block Size: "..blocksize.."px", 100, 124)
  if quitmessage then
    love.graphics.print("Quitting in "..math.abs(math.ceil(quittimer)).."...", 100, 100)
  end
end

function love.quit()
  print("The game is now done.")
end
