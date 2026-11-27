* ==============================================================================
* 01_limpieza.do
* Proyecto : Rendimiento escolar 2025 - Educación pública vs. particular
*            subvencionada (Entrega Final, Fundamentos de la programación
*            para análisis económico)
* Autores  : Francisco Inostroza y Sebastián Navarrete
* ==============================================================================

version 14
clear all
set more off
capture log close

* ------------------------------------------------------------------------------
* 0. Rutas y verificaciones
* ------------------------------------------------------------------------------
* Si Stata no está en la raíz del repositorio, confirm file detiene el
* do-file con "file ... not found". Solución: cd a la carpeta Entrega_Final.
confirm file "Entrega_Final.Rproj"

* Si no encuentra el CSV: primero hay que correr scripts/00_descomprimir.R
* (o descomprimir a mano el .rar dentro de data/raw/).
local raw_csv "data/raw/20260210_Rendimiento_2025_20260202_WEB.csv"
confirm file "`raw_csv'"

capture mkdir "data/processed"
capture mkdir "output"
capture mkdir "output/logs"

log using "output/logs/01_limpieza.log", replace text

* ------------------------------------------------------------------------------
* 1. Importar la base cruda
* ------------------------------------------------------------------------------
* El archivo viene separado por ";" y en UTF-8 .
import delimited "`raw_csv'", clear varnames(1) encoding("utf-8") delimiter(";")
rename *, lower

* Nos quedamos solo con las variables que usa el análisis.
keep rbd cod_reg_rbd cod_depe2 rural_rbd estado_estab cod_ense2 cod_grado ///
     gen_alu edad_alu sit_fin_r

* Registros en la base cruda
count

* EDAD_ALU trae 372 celdas con un espacio en blanco (" "): por eso Stata la
* puede leer como texto. destring con ignore(" ") la pasa a número y esas
* celdas quedan como missing. Si ya era numérica, destring
* solo avisa "already numeric" y no cambia nada.
destring edad_alu, replace ignore(" ")

* Situación final: los vacíos vienen como " "; strtrim quita los espacios.
replace sit_fin_r = strtrim(sit_fin_r)
tabulate sit_fin_r, missing

* ------------------------------------------------------------------------------
* 2. Filtros de la población objetivo
* ------------------------------------------------------------------------------
* Después de cada filtro, count muestra cuántos registros quedan.
* Para quedarse con varios códigos se botan los que NO son ninguno de ellos:
* drop if x != 1 & x != 2 & x != 5.

* 2.1 Establecimientos funcionando
keep if estado_estab == 1
count

* 2.2 Municipal (1), Particular Subvencionado (2) y SLEP (5)
drop if cod_depe2 != 1 & cod_depe2 != 2 & cod_depe2 != 5
count

* 2.3 Básica niños (2), Media HC jóvenes (5), Media TP/Artística jóvenes (7)
drop if cod_ense2 != 2 & cod_ense2 != 5 & cod_ense2 != 7
count

* 2.4 Situación final: promovido, reprobado o retirado (sin trasladados)
drop if sit_fin_r != "P" & sit_fin_r != "R" & sit_fin_r != "Y"
count

* 2.5 Sexo registral informado y edad no perdida
drop if gen_alu != 1 & gen_alu != 2
drop if missing(edad_alu)
count

* ------------------------------------------------------------------------------
* 3. Variables de análisis
* ------------------------------------------------------------------------------

* 3.1 Variable dependiente
*  aprueba        = 1 si promovido, 0 si reprobado (missing para retirados).
*  aprueba_amplia = 1 si promovido, 0 si reprobado o retirado (robustez).
generate aprueba = (sit_fin_r == "P") if sit_fin_r != "Y"
generate aprueba_amplia = (sit_fin_r == "P")
label variable aprueba        "Promovido (1) vs. reprobado (0)"
label variable aprueba_amplia "Promovido (1) vs. reprobado o retirado (0)"
label define si_no 0 "No" 1 "Sí"
label values aprueba si_no
label values aprueba_amplia si_no

* 3.2 Dependencia administrativa
generate dependencia = .
replace dependencia = 0 if cod_depe2 == 2
replace dependencia = 1 if cod_depe2 == 1
replace dependencia = 2 if cod_depe2 == 5
label define dependencia 0 "Particular subvencionado" 1 "Municipal" 2 "SLEP"
label values dependencia dependencia
label variable dependencia "Dependencia administrativa"

* Indicadora de establecimiento público (Municipal o SLEP): todo lo que no
* es particular subvencionado. dependencia no tiene missing después de los filtros.
generate publico = (dependencia != 0)
label define publico 0 "Particular subvencionado" 1 "Pública (Municipal + SLEP)"
label values publico publico
label variable publico "Establecimiento público (Municipal o SLEP)"

* Indicadoras de Municipal y SLEP por separado (para el modelo M5).
* La categoría base es particular subvencionado (las dos valen 0).
generate municipal = (dependencia == 1)
generate slep      = (dependencia == 2)
label variable municipal "Municipal"
label variable slep      "SLEP"

* 3.3 Territorio: región, ruralidad y su combinación (efecto fijo)
generate region = cod_reg_rbd
label define region ///
     1 "Tarapacá"            2 "Antofagasta"    3 "Atacama"      ///
     4 "Coquimbo"            5 "Valparaíso"     6 "O'Higgins"    ///
     7 "Maule"               8 "Biobío"         9 "Araucanía"    ///
    10 "Los Lagos"          11 "Aysén"         12 "Magallanes"   ///
    13 "Metropolitana"      14 "Los Ríos"      15 "Arica y Parinacota" ///
    16 "Ñuble"
label values region region
label variable region "Región del establecimiento"

generate rural = rural_rbd
label define rural 0 "Urbano" 1 "Rural"
label values rural rural
label variable rural "Zona del establecimiento"

* Celda región x zona: código de región x 10 + zona.
* Ej.: 130 = Metropolitana urbana, 131 = Metropolitana rural.
* Con i.reg_rural, cada celda tiene su propio efecto fijo en la regresión.
generate reg_rural = region * 10 + rural
label variable reg_rural "Celda región x ruralidad (región x 10 + zona)"

* 3.4 Características del estudiante y nivel
generate mujer = (gen_alu == 2)
label define mujer_lbl 0 "Hombre" 1 "Mujer"
label values mujer mujer_lbl
label variable mujer "Mujer"

rename edad_alu edad
label variable edad "Edad al 30 de junio"

* Nivel y grado: tipo de enseñanza x 10 + grado (ej. 21 = 1° básico)
generate nivel = cod_ense2 * 10 + cod_grado
label define nivel ///
    21 "1° básico"  22 "2° básico"  23 "3° básico"  24 "4° básico"  ///
    25 "5° básico"  26 "6° básico"  27 "7° básico"  28 "8° básico"  ///
    51 "1° medio HC" 52 "2° medio HC" 53 "3° medio HC" 54 "4° medio HC" ///
    71 "1° medio TP" 72 "2° medio TP" 73 "3° medio TP" 74 "4° medio TP"
label values nivel nivel
label variable nivel "Nivel y grado"

label variable rbd       "RBD del establecimiento"
label variable sit_fin_r "Situación final con indicador de traslado"

* ------------------------------------------------------------------------------
* 4. Revisión rápida
* ------------------------------------------------------------------------------
tabulate dependencia rural
tabulate nivel
tabstat aprueba aprueba_amplia, by(dependencia) stat(mean n)
tabstat aprueba, by(reg_rural) stat(mean n)

* ------------------------------------------------------------------------------
* 5. Guardar microdatos limpios
* ------------------------------------------------------------------------------
keep rbd region rural reg_rural dependencia publico municipal slep ///
     nivel mujer edad sit_fin_r aprueba aprueba_amplia
save "data/processed/rendimiento_limpio.dta", replace

* ------------------------------------------------------------------------------
* 6. Tabla agregada para los gráficos en R
* ------------------------------------------------------------------------------
* collapse: una fila por región x zona x dependencia.
* preserve/restore: la base de estudiantes vuelve intacta después.
preserve
collapse (mean)  tasa_aprob = aprueba tasa_aprob_amplia = aprueba_amplia ///
         (count) n_eval = aprueba n_total = aprueba_amplia,              ///
         by(region rural dependencia)

* Nombres en texto, para que R no tenga que volver a escribir las etiquetas.
decode region,      generate(region_nombre)
decode rural,       generate(zona)
decode dependencia, generate(dependencia_nombre)
list in 1/5

* nolabel: exporta los códigos (0, 1, 2) y no las etiquetas.
export excel using "data/processed/tasas_region_rural_dependencia.xlsx", ///
    firstrow(variables) nolabel replace
restore

* Estudiantes en la muestra limpia
count

log close
