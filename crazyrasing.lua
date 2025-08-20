function createCar()
  -- Crea el objeto carro con sus propiedades físicas
  objects.car = {}
  -- Posiciona el carro en el centro inferior de la pantalla
  objects.car.body = love.physics.newBody(world, 400, 424 - 50, "dynamic") -- Crea un cuerpo dinámico (afectado por física)
  objects.car.shape = love.physics.newRectangleShape(80, 40) -- Define la forma como un rectángulo de 80x40 píxeles
  -- Asocia la forma al cuerpo con una densidad de 1
  objects.car.fixture = love.physics.newFixture(objects.car.body, objects.car.shape, 1)
  objects.car.fixture:setRestitution(0.9) -- Establece el coeficiente de restitución para simular rebotes realistas
end

function love.load()
  love.physics.setMeter(64) -- Define cuántos píxeles representan un metro en nuestro mundo físico
  -- Crea un mundo con gravedad horizontal 0 y gravedad vertical 9.81*64 (escala a píxeles)
  world = love.physics.newWorld(0, 9.81 * 64, true) -- El factor 9.81*64 convierte la gravedad de metros a píxeles
  bg = love.graphics.newImage("bg-rasing.png") -- Carga la imagen de fondo del juego
  car = love.graphics.newImage("car.png") -- Carga la imagen del carro
  createCar()
end