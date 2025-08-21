local crazyrace = {}

-- Definición de carriles
local lanes = {330, 498, 640}
local car_lane_index = 2 -- El carro inicia en el carril central
local objects, world, bg, car, cars, meters, speed, message, endgame, speedFactor
local resource_direction = "resource/crazyrace/"
local lastKeyReleased = nil -- Variable para guardar la última tecla soltada
local baseSpeed = 200

-- Cargar imágenes de carros para obstáculos
local car_images = {}
function loadCarImages()
  car_images = {}
  lfs = love.filesystem
  car_folder = resource_direction .. "cars/"
  -- Obtiene la lista de archivos en la carpeta cars
  for _, file in ipairs(lfs.getDirectoryItems(car_folder)) do
    if file:match("%.png$") then
      table.insert(car_images, love.graphics.newImage(car_folder .. file))
    end
  end
end

function crazyrace.createCar()
  -- Crea el objeto carro con sus propiedades físicas
  objects.car = {}
  objects.car.body = love.physics.newBody(world, lanes[car_lane_index], 306, "dynamic")
  objects.car.shape = love.physics.newRectangleShape(71, 131)
  objects.car.fixture = love.physics.newFixture(objects.car.body, objects.car.shape, 1)
  objects.car.fixture:setRestitution(0) -- Sin rebote
  objects.car.body:setFixedRotation(true) -- No rota
end

function crazyrace.start()
  love.physics.setMeter(64) -- Define cuántos píxeles representan un metro en nuestro mundo físico
  -- Crea un mundo con gravedad horizontal 0 y gravedad vertical 9.81*64 (escala a píxeles)
  world = love.physics.newWorld(0, 0, true) -- Sin gravedad vertical
  bg = love.graphics.newImage(resource_direction .."bg.png") -- Carga la imagen de fondo del juego
  car = love.graphics.newImage(resource_direction .."car_blue.png") -- Carga la imagen del carro
  cars = {}
  meters = 0 -- Cantidad de metros recorridos
  speed = 0 -- Velocidad del carro en km/h
  message = "" -- Mensaje a mostrar en pantalla al finalizar el juego
  endgame = false -- Indica si el juego ha terminado
  love.audio.stop() -- Detiene cualquier audio que esté reproduciéndose
  love.audio.play(love.audio.newSource(resource_direction .."rasing-music.mp3", "stream")) -- Inicia la música de fondo del juego

  objects = {} -- Tabla para almacenar todos los objetos físicos del juego (similar a una colección de clases)

  loadCarImages() -- <--- Carga las imágenes de carros para obstáculos
  crazyrace.createCar()
  crazyrace.createObstacles()

  -- Configuración de la interfaz gráfica
  love.graphics.setBackgroundColor(0, 200, 0) -- Establece el color de fondo en verde (valores RGB)
  love.window.setMode(1000, 382) -- Define el tamaño de la ventana: 1000 píxeles de ancho por 382 de alto
  love.window.setTitle("Crazy Race") -- Establece el título de la ventana del juego
  love.window.setIcon(love.image.newImageData(resource_direction .. "car_blue.png")) -- Usa la imagen del balón como icono de la ventana

  love.graphics.setFont(love.graphics.newFont(42)) -- Configura la fuente del texto con tamaño 42

  world:setCallbacks(beginContact)
end

function crazyrace.createObstacles()
  objects.obstacles = {}
  -- Selecciona aleatoriamente 2 carriles distintos para los obstáculos
  local lane_indices = {1, 2, 3}
  -- Mezcla los índices de los carriles
  for i = #lane_indices, 2, -1 do
    local j = math.random(1, i)
    lane_indices[i], lane_indices[j] = lane_indices[j], lane_indices[i]
  end
  -- Solo coloca obstáculos en los dos primeros carriles mezclados
  for i = 1, 2 do
    obstacle = {}
    obstacle.image = car_images[math.random(1, #car_images)]
    obsWidth = obstacle.image:getWidth()
    obsHeight = obstacle.image:getHeight()
    obstacle.body = love.physics.newBody(world, lanes[lane_indices[i]], math.random(-200, 0), "static")
    obstacle.shape = love.physics.newRectangleShape(obsWidth, obsHeight)
    obstacle.fixture = love.physics.newFixture(obstacle.body, obstacle.shape)
    obstacle.fixture:setRestitution(0)
    table.insert(objects.obstacles, obstacle)
  end
end

function love.keyreleased(key)
  if key == "left" or key == "right" then
    lastKeyReleased = key
  end
end

function crazyrace.keypressed(key)
  if endgame and key == "r" then
    crazyrace.start()
  end
end

-- Mueve el carro al carril indicado por la dirección ("left" o "right")
function moveCarLane(direction)
  if direction == "left" and car_lane_index > 1 then
    car_lane_index = car_lane_index - 1
    objects.car.body:setX(lanes[car_lane_index])
  elseif direction == "right" and car_lane_index < #lanes then
    car_lane_index = car_lane_index + 1
    objects.car.body:setX(lanes[car_lane_index])
  end
end

function crazyrace.update(dt)
  if not endgame then
    world:update(dt)

    -- Aumenta la velocidad de los obstáculos con el tiempo
    speedFactor = baseSpeed + meters * 0.2

    -- Lógica para mover el carro entre carriles al soltar la tecla
    if lastKeyReleased and not love.keyboard.isDown("left") and not love.keyboard.isDown("right") then
      moveCarLane(lastKeyReleased)
      lastKeyReleased = nil
    end

    -- Mueve cada obstáculo y verifica colisiones
    for _, obs in ipairs(objects.obstacles) do
      x, y = obs.body:getPosition()
      -- Desplaza el obstáculo hacia abajo según la velocidad
      obs.body:setY(y + speedFactor * dt)
      -- Si el obstáculo sale de la pantalla, lo reposiciona arriba con nueva posición X aleatoria
      if y > 382 then
        -- Cuando el obstáculo sale de pantalla, elige un carril libre
        -- Primero, determina los carriles ocupados
        occupied = {}
        for _, o in ipairs(objects.obstacles) do
          if o ~= obs then
            ox = o.body:getX()
            for i, lane_x in ipairs(lanes) do
              if math.abs(ox - lane_x) < 1 then
                occupied[i] = true
              end
            end
          end
        end
        -- Busca carriles libres
        free_lanes = {}
        for i, lane_x in ipairs(lanes) do
          if not occupied[i] then
            table.insert(free_lanes, lane_x)
          end
        end
        -- Elige aleatoriamente uno de los carriles libres
        new_x = free_lanes[math.random(1, #free_lanes)]
        obs.body:setPosition(new_x, -40)
        -- Selecciona una nueva imagen aleatoria para el obstáculo
        obs.image = car_images[math.random(1, #car_images)]
      end
    end

    meters = meters + speedFactor * dt * 0.2 -- Avanza metros según velocidad
    speed = speedFactor -- Actualiza la velocidad actual
  end
  -- Si el juego terminó, no hacer nada hasta que se reinicie
end

function crazyrace.draw()
  love.graphics.draw(bg, 244, 0)
  love.graphics.draw(car, objects.car.body:getX(), objects.car.body:getY(), 0, 1, 1, car:getWidth() / 2, car:getHeight() / 2)
  -- Dibuja obstáculos con imagen aleatoria
  for _, obs in ipairs(objects.obstacles) do
    if obs.image then
      love.graphics.draw(obs.image, obs.body:getX(), obs.body:getY(), 0, 1, 1, obs.image:getWidth() / 2, obs.image:getHeight() / 2)
    else
      love.graphics.setColor(255, 0, 0)
      love.graphics.rectangle("fill", obs.body:getX() - 40, obs.body:getY() - 20, 80, 40)
      love.graphics.setColor(255, 255, 255)
    end
  end
  -- Indicador de velocidad (km/h) en esquina superior derecha
  love.graphics.setFont(love.graphics.newFont(24))
  love.graphics.setColor(255,255,255)
  love.graphics.print(string.format("Velocidad: \n\t%d km/h", math.floor(speed)), 775, 10)
  -- Indicador de metros recorridos en esquina inferior derecha
  love.graphics.print(string.format("Metros: %d", math.floor(meters)), 775, love.graphics.getHeight() - 40)
  -- Muestra el texto en la esquina superior izquierda
  love.graphics.print("Menu(Esc)", 10, 15)

  -- Mensaje de instrucciones
  instruction = "Usa las teclas izquierda/derecha\npara mover el carro\n\n\nEvita los obstáculos"
  boxWidth, boxHeight = 224, 120
  boxX, boxY = 10, 70
  love.graphics.setColor(255, 255, 0)
  love.graphics.setFont(love.graphics.newFont(24))
  love.graphics.printf(instruction, boxX, boxY + 20, boxWidth, "center")
  love.graphics.setColor(255,255,255)

  -- Muestra mensaje si termina el juego
  love.graphics.setFont(love.graphics.newFont(32))
  love.graphics.printf(message, 0, 50, 1000, "center")
  if endgame then
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.setColor(180,180,0)
    love.graphics.printf("Presiona 'R' para reiniciar", 0, 150, 1000, "center")
    love.graphics.setColor(255,255,255)
  end
end

function crazyrace.finish()
  love.audio.stop() -- Detiene la música de fondo
  -- Limpia el mensaje de fin de juego
  message = ""
  -- Permite que el juego se reinicie correctamente
  endgame = false
end

-- Añade esta función para detectar colisiones físicas
function beginContact(a, b, coll)
  if (a == objects.car.fixture or b == objects.car.fixture) and not endgame then
    for _, obs in ipairs(objects.obstacles) do
      if a == obs.fixture or b == obs.fixture then
        endgame = true
        message = "¡Chocaste! Fin del juego.\nMetros recorridos: " .. math.floor(meters)
      end
    end
  end
end

return crazyrace