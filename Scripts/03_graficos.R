# ==============================================================================
# 03_graficos.R
# Proyecto : Rendimiento escolar 2025 - Educación pública vs. particular
#            subvencionada
# Autores  : Francisco Inostroza y Sebastián Navarrete
# ==============================================================================

# install.packages(c("readxl", "dplyr", "ggplot2"))   # solo la primera vez
library(readxl)
library(dplyr)
library(ggplot2)

# ---- Parámetros ---------------------------------------------------------------
n_minimo <- 100   # celdas con menos estudiantes evaluados se omiten
fuente   <- "Fuente: MINEDUC, Rendimiento por estudiante 2025. Elaboración propia."
nota     <- paste0("Se omiten celdas región x zona donde algún grupo tiene menos de ",
                   n_minimo, " estudiantes evaluados.")

# Orden de las regiones en el eje: el primer nivel queda abajo en el gráfico,
# así que va de sur a norte (Arica arriba, Magallanes abajo). Los nombres son
# los mismos de las etiquetas de region en 01_limpieza.do.
orden_regiones <- c("Magallanes", "Aysén", "Los Lagos", "Los Ríos", "Araucanía",
                    "Biobío", "Ñuble", "Maule", "O'Higgins", "Metropolitana",
                    "Valparaíso", "Coquimbo", "Atacama", "Antofagasta",
                    "Tarapacá", "Arica y Parinacota")

# ---- Datos --------------------------------------------------------------------
tasas <- read_excel("data/processed/tasas_region_rural_dependencia.xlsx")

# Agrupar Municipal + SLEP en "Pública": se suman los aprobados y los evaluados
# de cada celda, y la tasa se recalcula (promedio ponderado por evaluados).
tasas_pub <- tasas |>
  mutate(grupo = if_else(dependencia == 0, "Particular subvencionado", "Pública"),
         region_nombre = factor(region_nombre, levels = orden_regiones),
         zona = factor(zona, levels = c("Urbano", "Rural"))) |>
  group_by(region_nombre, zona, grupo) |>
  summarise(aprobados = sum(tasa_aprob * n_eval, na.rm = TRUE),
            n_eval    = sum(n_eval)) |>
  mutate(tasa = 100 * aprobados / n_eval)

# Celdas región x zona donde están los dos grupos y ambos tienen al menos
# n_minimo evaluados.
celdas_validas <- tasas_pub |>
  group_by(region_nombre, zona) |>
  mutate(n_grupos = length(grupo),
         n_menor  = min(n_eval)) |>
  filter(n_grupos == 2 & n_menor >= n_minimo)

# ---- Figura 1: tasas por región, zona y dependencia ---------------------------
fig1 <- ggplot(celdas_validas, aes(x = tasa, y = region_nombre)) +
  geom_line(aes(group = region_nombre), color = "grey70") +
  geom_point(aes(color = grupo), size = 3) +
  facet_wrap(~ zona) +
  labs(title    = "Tasa de aprobación por región, zona y dependencia (2025)",
       subtitle = "Básica y media regular de niños y jóvenes; promovidos sobre promovidos + reprobados",
       x = "Tasa de aprobación (%)", y = NULL, color = NULL,
       caption = paste(fuente, nota, sep = "\n")) +
  theme_minimal() +
  theme(legend.position = "top")

ggsave("output/figuras/fig1_tasas_region_zona.png", fig1,
       width = 9, height = 7, dpi = 300, bg = "white")

# ---- Figura 2: brecha pública - particular subvencionado ---------------------
# Se separan los dos grupos y se vuelven a juntar con left_join por celda,
# para tener las dos tasas en la misma fila y restarlas.
pub <- celdas_validas |>
  filter(grupo == "Pública") |>
  select(region_nombre, zona, tasa) |>
  rename(tasa_pub = tasa)

ps <- celdas_validas |>
  filter(grupo == "Particular subvencionado") |>
  select(region_nombre, zona, tasa) |>
  rename(tasa_ps = tasa)

brechas <- left_join(pub, ps, by = c("region_nombre", "zona")) |>
  mutate(brecha_pp = tasa_pub - tasa_ps,
         signo = if_else(brecha_pp >= 0,
                         "Pública aprueba más",
                         "Particular subvencionado aprueba más"))

fig2 <- ggplot(brechas, aes(x = brecha_pp, y = region_nombre, fill = signo)) +
  geom_col() +
  geom_vline(xintercept = 0) +
  facet_wrap(~ zona) +
  labs(title    = "Brecha de aprobación: pública menos particular subvencionado (2025)",
       subtitle = "Diferencia en puntos porcentuales dentro de cada región y zona",
       x = "Brecha (puntos porcentuales)", y = NULL, fill = NULL,
       caption = paste(fuente, nota, sep = "\n")) +
  theme_minimal() +
  theme(legend.position = "top")

ggsave("output/figuras/fig2_brecha_region_zona.png", fig2,
       width = 9, height = 7, dpi = 300, bg = "white")

# ---- Figura 3: coeficientes estimados en Stata -------------------------------
# Los coeficientes están en proporciones: x 100 = puntos porcentuales.
coefs <- read_excel("output/tablas/coef_publico.xlsx") |>
  mutate(etiqueta = if_else(modelo == "M5",
                            paste0(modelo, ": ", termino, " (por separado)"),
                            paste0(modelo, ": ", descripcion)),
         coef_pp   = 100 * coef,
         ic_inf_pp = 100 * ic_inf,
         ic_sup_pp = 100 * ic_sup)

fig3 <- ggplot(coefs, aes(x = coef_pp, y = etiqueta)) +
  geom_vline(xintercept = 0) +
  geom_errorbar(aes(xmin = ic_inf_pp, xmax = ic_sup_pp), width = 0.2) +
  geom_point(size = 3) +
  geom_text(aes(label = round(coef_pp, 2)), vjust = -1) +
  labs(title    = "Efecto de estudiar en un establecimiento público sobre la aprobación",
       subtitle = "Coeficiente en puntos porcentuales e intervalo de confianza al 95 %",
       x = "Diferencia respecto a particular subvencionado (pp)", y = NULL,
       caption = paste(fuente, "Modelos estimados en Stata (scripts/02_modelos.do).",
                       sep = "\n")) +
  theme_minimal()

ggsave("output/figuras/fig3_coeficientes.png", fig3,
       width = 9, height = 5, dpi = 300, bg = "white")
