import { createContentLoader } from 'vitepress';

// Fuente única de las puertas por rol: el frontmatter de docs/roles/*.md.
// La portada, el índice /roles/ y cada página leen ESTO; un estado no se escribe dos veces.
//
// Frontmatter de una página de rol:
//   rol: cliente            id estable de la puerta
//   orden: 1                posición en las listas
//   puerta: Cliente Oasis   nombre de la puerta
//   lema: …                 una línea
//   encargos:               lo que se le puede pedir a un agente
//     - id: cliente-con-cartera
//       titulo: …
//       estado: en-obras    probado | ejercido | en-obras
//       medido: '2026-10-01'            fecha de la medida (entre comillas: si no, YAML la lee como fecha)
//       prueba: plan/REPORTES/….md      ruta en el repo del reporte que lo sostiene
//       falta: …                        qué falta para el siguiente estado
//
// Regla (la impone docs/.vitepress/verdad-checks.json): «probado» y «ejercido» llevan prueba.
export default createContentLoader('roles/*.md', {
  transform(raw) {
    return raw
      .filter((p) => p.frontmatter && p.frontmatter.rol)
      .map((p) => ({
        url: p.url,
        rol: p.frontmatter.rol,
        orden: p.frontmatter.orden ?? 99,
        puerta: p.frontmatter.puerta,
        lema: p.frontmatter.lema,
        encargos: p.frontmatter.encargos || []
      }))
      .sort((a, b) => a.orden - b.orden);
  }
});
