# Rendimiento Escolar en Chile — Educación Pública vs. Particular Subvencionada

Comparación de las tasas de aprobación escolar entre colegios públicos
(municipales y SLEP) y particulares subvencionados dentro de una misma
región y zona de ruralidad en Chile.

## Pregunta

¿Los estudiantes de colegios públicos (municipales y SLEP) tienen una menor
tasa de aprobación que los de particulares subvencionados, comparando
dentro de una misma región y ruralidad?

## Datos

- `data/raw/2025_Rendimiento_por_estudiante.csv`: Base de Rendimiento por
  Estudiante 2025 del MINEDUC (SIGE), descargada el 12 de noviembre de 2026.

## Cómo correrlo

1. **R** — abrir `Entrega_Final.Rproj` en RStudio y correr
   `scripts/00_descomprimir.R`. Extrae el CSV dentro de `data/raw/`.
   (Alternativa: descomprimir el `.rar` a mano con 7-Zip o WinRAR en `data/raw/`.)
2. **Stata** — `cd` a la raíz del repositorio y correr:
   ```stata
   do scripts/01_limpieza.do
   do scripts/02_modelos.do
   ```
3. **R** — correr `scripts/03_graficos.R`.

4. Las salidas gráficas quedarán exportadas en `output/figuras/`.

## Estructura
```
├── data/
│   ├── raw/
│   │   └── Rendimiento-por-estudiante-2025.rar    # original, sin editar
│   └── processed/                                  # generado por 01_limpieza.do
│       ├── rendimiento_limpio.dta                  # (no se sube: se regenera)
│       └── tasas_region_rural_dependencia.xlsx
├── scripts/
│   ├── 00_descomprimir.R
│   ├── 01_limpieza.do
│   ├── 02_modelos.do
│   └── 03_graficos.R
├── output/
│   ├── logs/        # 01_limpieza.log, 02_modelos.log
│   ├── tablas/      # coef_publico.xlsx
│   └── figuras/     # fig1, fig2, fig3 (.png)
├── Hito01.pdf
├── README.md
└── Entrega_Final.Rproj
```

## Autor

Francisco Inostroza y Sebastián Navarrete — Noviembre 2026

## Declaración de autoría y uso de IA
- Herramienta utilizada: Gemini
- Para qué la usé: Para corregir la redaccion del pdf.
- Verificación: confirmo que entiendo y puedo explicar todo lo que entrego.
