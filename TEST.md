# Testear el algoritmo

* Qué pasa cuando algunos notarios mienten o tienen data corrupta? Datos
  que pueden estar mal:

    * Fingerprint no coincide con la firma

    * La firma no valida la información

    * La llave no existe en la Web of Trust

* Qué pasa cuando la mayoría de los notarios miente!

  En realidad el "criterio de verdad" es que la mayoría de los notarios
  acuerden sobre una unidad de información dada.  En este caso si todos
  los notarios "mienten" menos uno, cómo se comprueba que esa
  información es confiable?

  El cliente debería mantener su propio WoT y confiar en las llaves que
  conoce? Requeriría un paso extra y más interacción con el usuario (o
  usar el pubring de la persona).

* Qué pasa si todos los notarios mienten?

  En este caso no hay consenso y ya.

* Qué pasa si los notarios responden en grupo?

  Si la población de respuestas válidas está dividida en dos o más
  posibles y válidas, el consenso depende de a cuáles notarios le
  pregunte el cliente.

* Cuál es la cantidad mínima de notarios necesaria para tener una
  respuesta correcta?

* Qué pasa si la salida a Internet está comprometida?  Desde la NSA el
  modelo de amenaza es un enemigo que controla la conexión completa.
