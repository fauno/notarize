# Notary

Nodo testigo, recibe información, la guarda criptográficamente y
responde lo que vió si le preguntás amablemente.

* Recibe información (una llave de LibreVPN por ejemplo) firmada con GPG
* La almacena
* Si se la pedís, te responde lo que tiene
* Si le mandás nueva información con la misma firma, actualiza lo que
  sabe

La idea es tener muchos notarios/testigos almacenando información y que
otros nodos puedan pedírselas y comparar qué vio cada uno

* Qué pasa si el atacante controla tantos notarios como para controlar
  el consenso sobre la información?

  La idea es que uses notarios en los que confíes

* Cómo se consensua?

  El cliente le pide a una cantidad de notarios y compara los
  resultados, si hay un nivel de acuerdo se determina que hay consenso
  sobre la información (usar el algoritmo de Perspectives)


## Protocolo

* Cliente postea al notario el { key, value, sig } donde sig es la firma
  gpg del valor y key una cadena arbitraria para identificarlo
* Notario chequea la firma
* Si la firma es válida y conocida, guarda/actualiza la información

* Cliente pide una llave al Notario
* Notario responde con la información firmada
