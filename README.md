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

1. Descomprimir `data/raw/2025_Rendimiento_por_estudiante.rar` dentro de la
   misma carpeta `data/raw/` para obtener el archivo `.csv`.
2. Abrir el proyecto en RStudio desde el archivo `Entrega_Final.Rproj`
   en la raíz del repositorio.
3. Ejecutar `scripts/Mine_mod.R`
4. Ejecutar `scripts/Mine_grafico.R`
5. Ejecutar `scripts/Mine_Limpio.R`
6. Las salidas gráficas quedarán exportadas en `output/figuras/`.
## Estructura
```
├── data/
│   └── raw/
│       └── 2025_Rendimiento_por_estudiante.rar
├── output/
│   └── figuras/
├── scripts/
│   ├── 01_limpieza_variables.R
│   ├── 02_descriptivo_graficos.R
│   └── 03_modelos.R
├── README.md
├── Hito_01.pdf
└── Entrega_Final.Rproj
```

## Autor

Francisco Inostroza y Sebastián Navarrete — Noviembre 2026

## Declaración de autoría y uso de IA
- Herramienta utilizada: Gemini
- Para qué la usé: Para corregir la redaccion del pdf.
- Verificación: confirmo que entiendo y puedo explicar todo lo que entrego.
