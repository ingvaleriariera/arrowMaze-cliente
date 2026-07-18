# AI Usage Documentation — Frontend (Arrow Maze)

**Proyecto:** Arrow Maze — Cliente Flutter + Riverpod + Dio + sqflite
**Arquitectura:** Clean Architecture de 4 capas (Domain → Application → Adapters → Infrastructure)
**NRC:** 25783

Este documento registra el uso de herramientas de inteligencia artificial durante el desarrollo del cliente Flutter, conforme a la Sección 7 del enunciado. El equipo declara este uso de forma transparente: la IA escribió la mayor parte del código bajo dirección del equipo, que definió la arquitectura, redactó las especificaciones, probó cada resultado en dispositivo real y corrigió a la IA cuando sus resultados fueron incorrectos o no correspondían a la visión del producto.

---

## 1. Herramientas utilizadas

| Herramienta | Modelo / Versión | Rol en el flujo de trabajo |
|---|---|---|
| Claude (claude.ai) | Claude Sonnet 4.5 / 4.6 / 5 | Diseño de arquitectura y diagramas PlantUML, análisis del HTML de referencia del juego, diagnóstico de bugs, redacción de prompts detallados para Claude Code, revisión de conceptos (DDD, teoría de grafos). |
| Claude Code (CLI) | Claude Sonnet 5, Claude Opus 4.8, Claude Haiku 4.5, Claude Fable (según la fase) | Herramienta principal de implementación: escritura del código Dart de las 4 capas, corrección de bugs, refactors, `flutter analyze`/tests, gestión de ramas Git y commits. |
| Gemini (Google / Antigravity) | Gemini / Gemini Pro | Respaldo cuando Claude Code no estaba disponible (parte de las capas 3 y 4), análisis de endpoints del backend, y colaboración en la reescritura del motor de renderizado 3D con `ditredi`. |

---

## 2. Registro de uso por tarea

### 2.1 Diseño de arquitectura y diagramas

El diseño de las 4 capas del cliente y los diagramas PlantUML se elaboraron en conversaciones de diseño con Claude: el equipo planteaba la estructura y las restricciones (regla de dependencia, patrones GoF del enunciado) y la IA proponía el detalle de clases y relaciones, que el equipo aprobaba o ajustaba. Varias entregas de la IA requirieron corrección: clases mal ubicadas por capa, relaciones omitidas entre capas, y elementos ya descartados que reaparecían en diagramas posteriores. Estas correcciones fueron detectadas por revisión activa del equipo contra el histórico de decisiones.

### 2.2 Implementación de las 4 capas

Claude Code implementó el código Dart de las cuatro capas a partir de los diagramas y de un archivo de especificaciones (`CLAUDE.md`) escrito por el equipo. El flujo fue por capas, compilando y probando cada una antes de avanzar. El HTML de referencia del juego original (`arrow_maze_v5.html`) fue el ancla para replicar fielmente la lógica del motor (generador de niveles, grafo de bloqueos, renderizado de flechas con `CustomPainter`). El equipo verificó la integración con el backend endpoint por endpoint contra Swagger, ya que la IA asumía en ocasiones contratos de API genéricos que no existían en el backend real.

### 2.3 Motor de juego y grafo de bloqueos

La lógica central (cada flecha como nodo de un grafo dirigido de bloqueos; resolver el puzzle equivale a un orden topológico de eliminación) se implementó en Dart puro con tests unitarios. Aquí ocurrió el error más costoso del proyecto: un intercambio de coordenadas x/y en la deserialización del tablero que la IA no detectó en múltiples iteraciones y que el equipo encontró analizando manualmente las claves generadas. También se corrigieron con varias iteraciones los casos límite de tableros irregulares (flechas que cruzan huecos del tablero y re-entran), donde la primera propuesta de la IA modificaba lógica existente pese a instrucciones de no hacerlo.

### 2.4 Sistemas de juego: audio, vidas, monedas, comodines, puntuación

Cada sistema siguió el mismo patrón: el equipo definía el comportamiento esperado y las restricciones arquitectónicas, la IA implementaba, y el equipo validaba en dispositivo físico. Destacan: el sistema de audio con patrón Observer (donde una revisión pedida por el equipo detectó que el plan inicial contradecía los UML ya entregados, y el enunciado exigía el Observer explícitamente), la economía de monedas (cuya primera implementación tenía un bug silencioso que solo se detectó jugando el flujo completo), y la persistencia de progreso (donde se descubrió que una implementación previa "simulaba" el almacenamiento local sin implementarlo realmente — se reemplazó por sqflite real con estrategia de lectura en tres niveles).

### 2.5 Soporte 3D (6 direcciones)

El requerimiento del profesor (celdas con 6 conexiones en lugar de 4) se abordó en tres etapas:

1. **Lógica de dominio:** extensión de `Position` con eje Z, direcciones `forward`/`back`, y extrusión del tablero 2D en un prisma de capas — todo del lado del cliente, sin modificar el formato del backend. Implementado por Claude Code con tests, sobre un diseño de dominio validado previamente en conversaciones de modelado UML.
2. **Renderizado:** las dos primeras aproximaciones (visor por capas, proyección isométrica en cascada) fueron implementadas, probadas en dispositivo por el equipo y descartadas por no lograr el efecto tridimensional buscado. La versión final usa el motor `ditredi` (geometría 3D real: cuerpos con curvas Bézier, cabezas piramidales, cámara con rotación libre), desarrollada con Claude y Gemini Pro y pulida después con Claude Code.
3. **Pulido:** correcciones de geometría (la punta de la flecha, huecos de renderizado en las curvas), efectos visuales de los comodines en 3D, y un botón para visualizar las líneas de salida del tablero.

### 2.6 Modo de tablero hexagonal

Como experimento aparte del juego principal, se pidió a Claude Code un tablero con celdas de 6 vecinos en coordenadas axiales (hexágonos) en lugar de la cuadrícula habitual. La IA reutilizó las entidades de dominio ya existentes (`GameSession`, las clases de comodines) en vez de duplicar lógica, lo cual redujo bastante la superficie de bugs nuevos. El resultado inicial se probó en dispositivo y se pidieron varias rondas de ajuste antes de aceptarlo como funcionalidad real: dos presets de tablero (uno simple y otro más grande y complejo con forma de anillo), un renderizado fiel al estilo del resto del juego, comodines y límite de movimientos, y la animación de salida de las flechas. Solo al validar que todo funcionaba bien en dispositivo se le pidió a la IA integrarlo como parte permanente de Configuración (antes vivía en una rama de prueba) y localizarlo a los dos idiomas del proyecto.

### 2.7 Depuración y verificación

La práctica constante fue: reportar el síntoma a la IA, pedir diagnóstico antes de tocar código, validar el fix en dispositivo físico. Los bugs resueltos así incluyen condiciones de carrera en el audio, estado de UI que no se refrescaba tras compras, animaciones duplicadas, y errores de arranque. La verificación con `flutter analyze` sin errores y la suite de tests fueron requisito antes de cada commit.

---

## 3. Porcentaje aproximado de código con asistencia de IA

**Estimación: ~75–80% del código del cliente fue escrito directamente por IA.**

Ese porcentaje mide autoría del texto del código, no autonomía de decisión. El equipo aportó: la arquitectura y los diagramas base, las especificaciones y prompts (varios de ellos documentos extensos con contratos de clases y restricciones explícitas), el testeo manual en dispositivo real de cada entrega, el rechazo de implementaciones completas que no correspondían a la visión del producto, ajustes de diseño de juego (distribución de longitudes de flechas, reglas de puntuación), y la corrección de errores de proceso de la IA. El nivel de revisión no fue uniforme: profundo en arquitectura, lógica de dominio y todo lo que el enunciado exige justificar; más ligero en código repetitivo de UI, donde la validación principal fue funcional (compila, corre, se comporta como el juego de referencia).

---

## 4. Casos donde la IA produjo resultados incorrectos o subóptimos

| Caso | Cómo se detectó | Cómo se corrigió |
|---|---|---|
| Intercambio de coordenadas x/y en la deserialización del tablero — el error más costoso del proyecto; la IA no lo encontró en varias iteraciones. | Análisis manual del equipo sobre las claves de celdas generadas. | Se corrigió el orden col/fila; lección: explicitar siempre el sistema de coordenadas en los prompts. |
| Persistencia de progreso "simulada": código que compilaba y parecía funcionar pero guardaba solo en memoria. | Prueba en dispositivo físico (el progreso se perdía en un flujo específico). | Se implementó la persistencia real con sqflite; lección: el código de infraestructura generado por IA debe probarse contra su contrato, no solo leerse. |
| Endpoints de API asumidos que no existían en el backend real (errores 404). | Logs de red y verificación contra Swagger. | Se corrigieron los contratos; se adoptó verificar cada endpoint antes de aceptar código de integración. |
| Dos implementaciones completas del renderizado 3D funcionalmente correctas pero visualmente insuficientes. | Prueba en dispositivo por el equipo. | Se descartaron y se migró a un motor 3D real (`ditredi`); lección: la IA puede cumplir la letra del requerimiento sin lograr la intención visual — el criterio final es humano. |
| Un commit realizado en la rama incorrecta (`main` en lugar de `develop`). | El equipo lo notó y detuvo a la IA de inmediato. | Se movió el commit con `cherry-pick` y se restauró `main`; se estableció la regla explícita de trabajar solo en `develop`. |
| Modificación de lógica existente pese a instrucciones de solo agregar (caso de tableros irregulares); tomó 4–5 iteraciones llegar al fix correcto. | Validación en dispositivo tras cada intento. | Se refinó el prompt con las restricciones al inicio y con los casos esperados explícitos. |
| Inconsistencias en conversaciones largas: decisiones "olvidadas", elementos descartados que reaparecían, nivel de detalle que se degradaba. | Revisión del equipo contra lo acordado. | Corrección explícita en cada caso; auditoría sistemática de cada entrega. |

---

## 5. Reflexión del equipo sobre el impacto de la IA

**En productividad:** el impacto fue decisivo. Un cliente con motor de juego propio (grafo de bloqueos, generación procedural de niveles resolubles, animaciones), 4 capas de arquitectura limpia, más de una decena de pantallas, sistemas de audio/vidas/monedas/comodines, internacionalización y un modo 3D con motor de renderizado real no habría sido viable en el plazo del curso escribiendo cada línea manualmente. La IA también aceleró el aprendizaje: conceptos como el ordenamiento topológico del grafo o la separación estricta de capas se entendieron mejor al discutirlos y verlos aplicados en el propio código.

**En calidad:** la experiencia dejó una conclusión matizada. El código generado por IA es estructuralmente bueno y consistente con la arquitectura cuando las especificaciones son precisas, pero los errores que produce son de un tipo particular: silenciosos, plausibles y difíciles de ver leyendo — coordenadas invertidas, persistencia simulada, contratos de API inventados. Ninguno de esos errores se habría detectado sin pruebas funcionales reales. Por eso el hábito más valioso que adoptó el equipo no fue escribir mejores prompts (aunque ayudó), sino **no aceptar nada sin probarlo en dispositivo físico**. La calidad final del proyecto la garantizaron las pruebas y el criterio del equipo, con la IA como multiplicador de velocidad.

**Práctica adoptada:** especificación detallada antes de generar (diagramas, contratos, restricciones explícitas de "no tocar"); implementación por fases compilando entre cada una; verificación funcional obligatoria en dispositivo antes de aceptar; y trabajo en la rama `develop` con revisión del equipo antes de integrar a `main`.
