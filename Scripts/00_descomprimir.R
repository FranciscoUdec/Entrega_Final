# ==============================================================================
# 00_descomprimir.R
# Proyecto : Rendimiento escolar 2025 - Educación pública vs. particular
#            subvencionada
# Autores  : Francisco Inostroza y Sebastián Navarrete
#
# Qué hace : Extrae el CSV de la base original (data/raw/*.rar, tal como se
#            descargó del MINEDUC) dentro de data/raw/. El .rar no se modifica.
#            Se hace en R porque Stata no puede leer archivos .rar.
#
# Cómo correrlo: abrir Entrega_Final.Rproj en RStudio y ejecutar este script
# (el .Rproj deja el directorio de trabajo en la raíz del repositorio).
#
# Alternativa sin R: descomprimir el .rar a mano con 7-Zip o WinRAR dentro
# de data/raw/.
# ==============================================================================

# install.packages("archive")   # solo la primera vez

# El paquete archive sabe abrir archivos .rar (R base no puede).
library(archive)

# Del .rar se extrae solo el CSV (unos 600 MB, puede tardar un minuto).
# El diccionario (PDF) y la tabla de frecuencias no se necesitan.
archive_extract("data/raw/Rendimiento-por-estudiante-2025.rar",
                dir   = "data/raw",
                files = "20260210_Rendimiento_2025_20260202_WEB.csv")
