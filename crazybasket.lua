function love.load()
  love.physics.setMeter(64) -- Define cuántos píxeles representan un metro en nuestro mundo físico
  -- Crea un mundo con gravedad horizontal 0 y gravedad vertical 9.81*64 (escala a píxeles)
  world = love.physics.newWorld(0, 9.81 * 64, true) -- El factor 9.81*64 convierte la gravedad de metros a píxeles
  bg = love.graphics.newImage("bg.png") -- Carga la imagen de fondo del juego
  basketball = love.graphics.newImage("ball.png") -- Carga la imagen del balón de baloncesto
  basket = love.graphics.newImage("canasta.png") -- Carga la imagen de la canasta
  message = "" -- Almacena el mensaje que se mostrará al finalizar el juego
  mouseX = "" -- Almacena la posición actual del mouse en el eje X
  sum = 0 -- Acumulador para calcular la fuerza de impulso del balón
  points = 0 -- Contador de puntos del jugador
  time = 60 -- Tiempo total del juego en segundos
  R = 255 -- Componente rojo del color RGB
  G = 255 -- Componente verde del color RGB
  B = 255 -- Componente azul del color RGB
  goal = false -- Indica si se ha anotado un punto recientemente
  endgame = false -- Indica si el juego ha terminado
  love.audio.stop() -- Detiene cualquier audio que esté reproduciéndose
  love.audio.play(love.audio.newSource("basket-rock.mp3", "stream")) -- Inicia la música de fondo del juego

  objects = {} -- Tabla para almacenar todos los objetos físicos del juego (similar a una colección de clases)

  -- Creación del suelo del juego
  objects.ground = {}
  -- Crea un cuerpo físico para el suelo, posicionado en el centro inferior de la pantalla
  objects.ground.body = love.physics.newBody(world, 1000 / 2, 424 - 50 / 2)
  objects.ground.shape = love.physics.newRectangleShape(1000, 50) -- Define la forma como un rectángulo de 1000x50 píxeles
  objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape) -- Asocia la forma al cuerpo físico

  createBall() -- Llama a la función que crea e inicializa el balón

  -- Creación de los dos objetos que forman los bordes del aro de baloncesto
  objects.block1 = {}
  objects.block1.body = love.physics.newBody(world, 768, 125, "static") -- Crea un cuerpo estático para el primer borde
  objects.block1.shape = love.physics.newRectangleShape(0, 0, 10, 10) -- Define su forma como un cuadrado de 10x10
  objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape, 5) -- Densidad: 5

  -- El último parámetro (5) representa la densidad del objeto, aunque al ser estático no afecta su comportamiento físico

  objects.block2 = {}
  objects.block2.body = love.physics.newBody(world, 848, 70, "static") -- Crea un cuerpo estático para el segundo borde
  objects.block2.shape = love.physics.newRectangleShape(0, 0, 10, 120) -- Define su forma como un rectángulo vertical
  objects.block2.fixture = love.physics.newFixture(objects.block2.body, objects.block2.shape, 5) -- Densidad: 5

  -- Configuración de la interfaz gráfica
  love.graphics.setBackgroundColor(104, 136, 248) -- Establece el color de fondo en azul celeste (valores RGB)
  love.window.setMode(1000, 424) -- Define el tamaño de la ventana: 1000 píxeles de ancho por 424 de alto
  love.window.setTitle("Crazy Basket") -- Establece el título de la ventana del juego
  love.window.setIcon(love.image.newImageData("ball.png")) -- Usa la imagen del balón como icono de la ventana

  love.graphics.setFont(love.graphics.newFont(42)) -- Configura la fuente del texto con tamaño 42
end

function love.update(dt)
  world:update(dt) -- Actualiza la simulación física del mundo en cada fotograma

  if time > 1 then -- Si queda tiempo de juego (más de 1 segundo)
    time = time - dt -- Reduce el tiempo restante según el tiempo transcurrido entre fotogramas
    mouseX = love.mouse.getX() -- Captura la posición horizontal actual del ratón

    if love.mouse.isDown(1) then -- Si se está presionando el botón izquierdo del ratón
        sum = sum + 20 -- Incrementa el acumulador que determina la fuerza de lanzamiento
        objects.ball.fixture:destroy() -- Elimina el balón actual para evitar múltiples balones en escena
        createBall() -- Crea un nuevo balón en la posición inicial
        objects.ball.body:applyLinearImpulse(sum, -mouseX) -- Aplica un impulso al balón: fuerza horizontal (sum) y vertical (-mouseX)
        goal = false -- Reinicia el estado de anotación
    else
        sum = 0 -- Reinicia el acumulador de fuerza cuando no se presiona el botón
    end

    -- Detecta cuando el balón atraviesa la canasta para anotar un punto
    if objects.block1.body:getY() < objects.ball.body:getY() and objects.block1.body:getY() + 10 >= objects.ball.body:getY()
        and objects.block1.body:getX() < objects.ball.body:getX() 
        and objects.block2.body:getX() > objects.ball.body:getX() 
        and goal == false then
        points = points + 1
        goal = true -- Marca que ya se contó esta canasta para evitar puntos múltiples
    end

    -- Mantiene el color de pantalla normal (blanco) durante el juego
    R = 255
    G = 255
    B = 255
  else
    -- Se ejecuta cuando el tiempo ha llegado a cero
    if endgame == false then
      -- Cambia el color de pantalla a rojo para indicar fin del juego
      R = 255
      G = 0
      B = 0

      -- Reproduce el sonido de bocina final y muestra el mensaje de fin de juego
      sfx = love.audio.newSource("buzzer.mp3", "static")
      love.audio.play(sfx)
      message = "GAME OVER"
      mouseX = 0 -- Reinicia la posición del ratón
      endgame = true -- Marca que el juego ha terminado para evitar repetición del código
    end
  end
end

function love.draw()
  love.graphics.draw(bg, 0, 0) -- Dibuja la imagen de fondo en la posición (0,0)

  -- Muestra la información de puntos y tiempo restante en pantalla
  love.graphics.setColor(255, 255, 255) -- Establece color blanco para el texto
  love.graphics.print(points, 800, 25) -- Muestra el puntaje actual
  love.graphics.print(math.floor(time) .. "s", 825, 25) -- Muestra el tiempo restante en segundos
  love.graphics.setColor(R, G, B) -- Aplica el color actual del juego (normal o rojo al finalizar)

  -- Dibuja el balón en su posición física actual con la rotación correcta
  love.graphics.draw(basketball, objects.ball.body:getX(), objects.ball.body:getY(), objects.ball.body:getAngle(), 1, 1,
      basketball:getWidth() / 2, basketball:getHeight() / 2)

  -- Dibuja la canasta en una posición fija
  love.graphics.draw(basket, 815, 162, math.rad(0), 1, 1, basket:getWidth() / 2, basket:getHeight() / 2)

  -- Dibuja una barra verde vertical que representa la fuerza de impulso acumulada
  love.graphics.setColor(0, 255, 0)
  love.graphics.rectangle("fill", 5, 424, 5, -sum)

  -- Dibuja una barra amarilla vertical que representa la posición del ratón (altura de lanzamiento)
  love.graphics.setColor(255, 255, 0)
  love.graphics.rectangle("fill", 0, 424, 5, -mouseX)

  -- Muestra el mensaje de fin de juego cuando corresponda
  love.graphics.setColor(255, 255, 255)
  love.graphics.printf(message, 250, 180, 500, "center")

  -- Restaura el color actual del juego
  love.graphics.setColor(R, G, B)
end

function createBall()
  -- Crea el objeto balón con sus propiedades físicas
  objects.ball = {}
  -- Posiciona el balón en la esquina inferior izquierda de la pantalla
  objects.ball.body = love.physics.newBody(world, 40, 424 - 100, "dynamic") -- Crea un cuerpo dinámico (afectado por física)
  objects.ball.shape = love.physics.newCircleShape(20) -- Define la forma como un círculo con radio de 20 píxeles
  -- Asocia la forma al cuerpo con una densidad de 1
  objects.ball.fixture = love.physics.newFixture(objects.ball.body, objects.ball.shape, 1)
  objects.ball.fixture:setRestitution(0.9) -- Establece el coeficiente de restitución para simular rebotes realistas
end