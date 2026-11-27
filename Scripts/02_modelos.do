* ==============================================================================
* 02_modelos.do
* Proyecto : Rendimiento escolar 2025 - Educación pública vs. particular
*            subvencionada
* Autores  : Francisco Inostroza y Sebastián Navarrete
* Software : Stata 14 o superior
* Requiere : haber corrido scripts/01_limpieza.do
*
* Pregunta : ¿Los estudiantes de establecimientos públicos (Municipal + SLEP)
*            tienen menor probabilidad de aprobar que los de particulares
*            subvencionados, comparando dentro de una misma región y zona
*            (urbana/rural)?
*
* Modelos de probabilidad lineal (regress):
*   M1  aprueba ~ publico                                  (sin controles)
*   M2  aprueba ~ publico + EF región x ruralidad
*   M3  M2 + mujer + edad + EF de nivel/grado              (principal)
*   M4  M3 con aprueba_amplia (retirados = no aprueba)     (robustez)
*   M5  M3 separando Municipal y SLEP                      (heterogeneidad)
*
* No se usan PROM_GRAL ni ASISTENCIA como controles: son parte del criterio
* de promoción (resultado), no características previas del estudiante.
*
* Limitación: los errores estándar suponen que cada estudiante es
* independiente, pero los alumnos de un mismo colegio se parecen entre sí.
* Por eso los errores estándar (y los intervalos del gráfico 3) probablemente
* son más chicos de lo que deberían: hay que leerlos con cautela.
*
* Salidas:
*   output/logs/02_modelos.log        salida completa de Stata
*   output/tablas/coef_publico.xlsx   coeficientes de interés (insumo de R)
* ==============================================================================

version 14
clear all
set more off
capture log close

* ------------------------------------------------------------------------------
* 0. Rutas y verificaciones
* ------------------------------------------------------------------------------
* Si alguno no se encuentra, Stata se detiene con "file ... not found":
* cd a la raíz del repositorio, o correr antes scripts/01_limpieza.do.
confirm file "Entrega_Final.Rproj"
confirm file "data/processed/rendimiento_limpio.dta"

capture mkdir "output"
capture mkdir "output/logs"
capture mkdir "output/tablas"
capture mkdir "output/figuras"     // aquí guarda R los gráficos (03_graficos.R)

log using "output/logs/02_modelos.log", replace text

use "data/processed/rendimiento_limpio.dta", clear

* --- Parámetros de los modelos (se cambian aquí, en un solo lugar) ---
local ef        "i.reg_rural"            // efecto fijo de cada celda región x zona
local controles "mujer edad i.nivel"     // características del estudiante y nivel
local salida    "output/tablas/coef_publico.xlsx"

* ------------------------------------------------------------------------------
* 1. Descriptivos
* ------------------------------------------------------------------------------
tabstat aprueba aprueba_amplia, by(publico) stat(mean n)

* Tasa de aprobación por región y por zona, para cada tipo de establecimiento
* (0 = particular subvencionado, 1 = pública).
forvalues p = 0/1 {
    display _newline "===== publico = `p' ====="
    tabstat aprueba if publico == `p', by(region) stat(mean n)
    tabstat aprueba if publico == `p', by(rural)  stat(mean n)
}

* ------------------------------------------------------------------------------
* 2. Matriz de resultados y programa auxiliar
* ------------------------------------------------------------------------------
* Matriz C: una fila por coeficiente de interés (6 filas) y 5 columnas:
* coeficiente, error estándar, límites del intervalo al 95 % y N.
matrix C = J(6, 5, .)

* guardar_coef  fila  variable
*   `1' = fila de la matriz C donde se guarda
*   `2' = variable cuyo coeficiente se guarda (ej. publico)
* Lee _b[] y _se[] de la ÚLTIMA regresión.
* Intervalo al 95 %: coeficiente +/- 1,96 errores estándar.
capture program drop guardar_coef
program guardar_coef
    matrix C[`1', 1] = _b[`2']
    matrix C[`1', 2] = _se[`2']
    matrix C[`1', 3] = _b[`2'] - 1.96 * _se[`2']
    matrix C[`1', 4] = _b[`2'] + 1.96 * _se[`2']
    matrix C[`1', 5] = e(N)
end

* ------------------------------------------------------------------------------
* 3. Modelos
* ------------------------------------------------------------------------------
* publico es 0/1: su coeficiente es la diferencia en la probabilidad de
* aprobar entre pública y particular subvencionado (x 100 = puntos porcentuales).

* M1: diferencia bruta
regress aprueba publico
estimates store M1
guardar_coef 1 publico

* M2: comparación dentro de cada celda región x ruralidad
regress aprueba publico `ef'
estimates store M2
guardar_coef 2 publico

* M3: + características del estudiante y nivel (modelo principal)
regress aprueba publico `controles' `ef'
estimates store M3
guardar_coef 3 publico

* M4: robustez, retirados cuentan como no aprobados
regress aprueba_amplia publico `controles' `ef'
estimates store M4
guardar_coef 4 publico

* M5: Municipal y SLEP por separado (base: particular subvencionado)
regress aprueba municipal slep `controles' `ef'
estimates store M5
guardar_coef 5 municipal
guardar_coef 6 slep

* ------------------------------------------------------------------------------
* 4. Tablas de resultados
* ------------------------------------------------------------------------------
* Variable dependiente: aprueba (1 = promovido, 0 = reprobado); M4 usa
* aprueba_amplia (retirados = 0). Categoría base: particular subvencionado.
* La tabla también muestra los coeficientes de los efectos fijos.
estimates dir
estimates table M1 M2 M3 M4, b(%9.4f) se stats(N r2) stfmt(%5.3f)
estimates table M5, b(%9.4f) se stats(N r2) stfmt(%5.3f)

* Resumen de los coeficientes de interés
matrix colnames C = coef se ic_inf ic_sup n
matrix rownames C = M1 M2 M3 M4 M5_mun M5_slep
matrix list C, format(%9.4f)

* A Excel: encabezados, la matriz desde D2 y los nombres
* de cada fila en las columnas A a C. Es el insumo del gráfico 3 en R.
putexcel set "`salida'", replace
putexcel A1 = ("modelo") B1 = ("descripcion") C1 = ("termino") ///
         D1 = ("coef") E1 = ("se") F1 = ("ic_inf") G1 = ("ic_sup") H1 = ("n")
putexcel D2 = matrix(C)
putexcel A2 = ("M1") B2 = ("Sin controles")                     C2 = ("Pública")
putexcel A3 = ("M2") B3 = ("EF región x ruralidad")             C3 = ("Pública")
putexcel A4 = ("M3") B4 = ("EF región x ruralidad + controles") C4 = ("Pública")
putexcel A5 = ("M4") B5 = ("Robustez: retirados = no aprueba")  C5 = ("Pública")
putexcel A6 = ("M5") B6 = ("Municipal y SLEP por separado")     C6 = ("Municipal")
putexcel A7 = ("M5") B7 = ("Municipal y SLEP por separado")     C7 = ("SLEP")

log close
