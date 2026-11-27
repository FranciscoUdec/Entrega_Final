# ==============================================================================
# 00_descomprimir.R
# Proyecto : Rendimiento escolar 2025 - Educación pública vs. particular
#            subvencionada
# Autores  : Francisco Inostroza y Sebastián Navarrete
# ==============================================================================

# install.packages("archive")   # solo la primera vez

# El paquete archive sabe abrir archivos .rar (R base no puede).
library(archive)

# Del .rar se extrae solo el CSV (unos 600 MB, puede tardar un minuto).
# El diccionario (PDF) y la tabla de frecuencias no se necesitan.
archive_extract("data/raw/Rendimiento-por-estudiante-2025.rar",
                dir   = "data/raw",
                files = "20260210_Rendimiento_2025_20260202_WEB.csv")
