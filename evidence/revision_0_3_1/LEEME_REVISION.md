# Procedencia de las evidencias de la revisión 0.3.1

El recorrido integrado vigente y la compilación Android aprobaron el 29 de octubre de 2026 en [GitHub Actions](https://github.com/yorilopez/Proyecto-CASA-VIP-INMOBILIARIA/actions/runs/40899104478), sobre el commit `83ac6f0369d4d7685e037aaa0fbae5ab2dea0c34`.

- [APK Android arm64](https://github.com/yorilopez/Proyecto-CASA-VIP-INMOBILIARIA/actions/runs/40899104478/artifacts/12907684576): compilación de depuración; sin prueba en teléfono físico.
- [Capturas y resultado del navegador de la revisión vigente](https://github.com/yorilopez/Proyecto-CASA-VIP-INMOBILIARIA/actions/runs/40899104478/artifacts/12908263137).
- `ci_web_20261029.txt`, `ci_android_20261029.txt` y `ci_web_verificacion.json` conservan los registros de esta ejecución. El flujo recorre las 14 pantallas con API real, titular, cotitular, cuatro imágenes ficticias, plan de 24 cuotas y descarga de ficha y constancia.

Las imágenes de `screens/` y la comparación HTML se obtuvieron el 27 de octubre en una ejecución real anterior de la misma revisión. La versión vigente agrega la etapa a la ficha comercial (RF-30); las capturas locales anteriores no incluyen ese último texto. Las capturas vigentes se encuentran en el artefacto de navegador enlazado arriba. Los documentos académicos usan las capturas locales con esa limitación.

Las suites registran 35 casos Java repetidos en H2 y PostgreSQL 17.6 y 11 casos Flutter: 46 casos distintos y 81 ejecuciones. El navegador y la actualización de la base se comprueban por separado. La cámara y el envío efectivo por WhatsApp en teléfono físico siguen pendientes de validación.

Los artefactos de Actions tienen retención de 30 días y requieren acceso al repositorio privado. Las fuentes y el procedimiento de compilación se incluyen en la entrega para reproducirlos.
