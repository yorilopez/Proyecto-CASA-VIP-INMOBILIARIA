# Evidencias del avance 3

Los archivos terminados en -final contienen la última suite de 26 casos Java, aprobada con H2 y PostgreSQL. Los XML TEST-*.xml conservan los resultados de casos sin propiedades del entorno de compilación. Flutter tiene cinco casos y análisis sin incidencias.

Los registros integration-tests.txt y postgresql-tests.txt corresponden a un incremento anterior de 24 casos. Los archivos tdd-red y tdd-green documentan las primeras cuatro reglas y su evolución. Se conservan como historial, no se suman otra vez al conteo de 31 casos únicos.

screens y ABRIR_EVIDENCIAS.html contienen las 14 capturas del recorrido real. navegador-resultados.json confirma el flujo con API; navegador-errores.json contiene los errores de página capturados (lista vacía).

android-ci.json y android-ci-build.txt identifican la compilación Android satisfactoria. android-firma.txt registra la verificación del APK. La firma es de depuración y el teléfono físico no fue validado.

El paquete integrado usa H2 en archivo con escritura inmediata. La comprobación package-smoke.json verifica inicio, web integrada, acceso y persistencia de sesión después de un reinicio abrupto. Las cuentas y los datos utilizados son ficticios.
