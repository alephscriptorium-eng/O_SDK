# Para la mesa técnica de Acampada26S · lo que hace falta decidir o medir antes del GO

Vosotros ejecutáis la activación: clonáis este repo en vuestra máquina y seguís
[`docs/PUB/TEMPLATE-RUNBOOK.md`](../../../docs/PUB/TEMPLATE-RUNBOOK.md) con el mando `pub/scripts/secretaria.sh`.
Nosotros no tocamos vuestro pub; os damos la plantilla, el kit, la guía y el método. Antes de empezar hay nueve cosas
que solo vosotros podéis decir. Cada una lleva nuestra recomendación; la decisión es vuestra y se escribe en el JSON
(`entrada/acampada26s_organigrama.json`, `instancia.activacion`) para que todo se regenere de ahí.

| # | Qué | Por qué importa | Recomendación |
|---|---|---|---|
| 1 | **¿Con qué está desplegado `acampada26s.net`?** Este repo (o-sdk) o un Oasis upstream montado a mano | Cambia la red (`caps.shs`) y la variante del runbook (A junto al pub / B en otra máquina). Medido desde fuera: `/c` responde y el pie dice **1.2.5**; la plantilla se escribió para 1.2.3 y los objetos son los mismos | si es este repo, variante **A** en el host; si no, **B** en vuestra máquina |
| 2 | **El `caps.shs` del pub** | Sin el mismo valor la secretaría no puede ni saludar al pub. Está en el `ssb-config` del pub (`pub/config/ssb/config` si es este repo; el de `ssb-caps` por defecto si es upstream sin caps propio) | medirlo y escribirlo con `secretaria.sh 26s caps <valor>`; no es secreto, pero es vuestro |
| 3 | **Un invite del pub** | Es lo que une a la secretaría. Lo genera quien administra el pub (`ssb-admin.js invite.create 1` o `npm run pub:invite`) | de un uso, en un fichero que se borra tras `join`; nunca por chat ni correo |
| 4 | **Quién es la mesa técnica** (nombres, cuántas personas) | Es quien reparte la hoja de códigos y pide los códigos de un uso; sale en la guía de reparto (`meta.reparto.mesa_tecnica`) | dos personas como mínimo, una con el backup |
| 5 | **Dónde vive la secretaría** | Su `secret` y las claves de las tribus están donde ella corre. Si muere la máquina sin backup, nadie puede crear más códigos de las estrictas ni deshacer nada | la máquina de la mesa técnica (B) con backup cifrado en otro sitio, o el host del pub (A) si ya tenéis backups de él |
| 6 | **Quién custodia `secret` + `oasis/keys`** | Es irremplazable (AGENTES §3). `secretaria.sh 26s backup <carpeta>` lo deja en un `.tgz` | una persona de la mesa técnica, copia cifrada fuera de git y de la máquina |
| 7 | **Las tres tribus estrictas**: Asamblea Internodos, InterCSOs, Asamblea de Colectivos | En modo estricto solo la autora (la secretaría) da códigos: **cada alta pasa por la mesa técnica** con `codigos one-use`. Las otras 22 son abiertas con código multiuso (hoja con QR) | mantenerlas estrictas solo si la mesa técnica asume dar cada alta; si no, abrirlas antes de sembrar (se cambia en el JSON y se regenera) |
| 8 | **El `about` de la secretaría** (nombre y descripción literales, avatar) | Se publica una vez y no se retira. El avatar propuesto está en `assets/avatar-secretaria-512.png` (formulario A1) | «Secretaría 26S» con la descripción de `docs/PUB/INSTANCIA-PLANTILLA.md` §4 adaptada; GO por escrito |
| 9 | **GO** | Nada de esto se ejecuta sin vuestro GO explícito, y cada paso irreversible pide permiso en el momento | un GO para unirse + `about`, y un GO por bloque de siembra (10) |

## Lo que ya tenéis listo en el repo

- La plantilla `pub/templates/acampada26s.json` (25 tribus, 7 salas, calendarios, eventos, listas, 12 páginas de wiki,
  mapas) derivada del organigrama; el kit visual con vuestra marca en `pub/templates/assets/acampada26s/`.
- La guía de reparto (`guia-reparto-acampada26s.md`, también como wiki) con la sección **Primer acceso**; el guion de
  activación a mano (`guion-acampada26s.md`) por si preferís crear algo desde la interfaz.
- La vista previa real (`vista-previa/`) de cómo quedará: web pública y cliente.
- Las herramientas probadas en seco contra un ensayo local: `secretaria.sh` (unirse, `about`, sembrar, medir, backup) y
  `codigos` (hoja de códigos con QR, código de un uso). Lo que no está probado todavía: la unión a **vuestro** pub, que
  depende del punto 1 y 2.

## Qué pasa después del GO

Unos 40 minutos de ejecución si todo cuadra: levantar (5), unirse (3), `about` (2), ensayo (2), diez bloques (15), hoja
de códigos (5), verificación y backup (8). Al terminar tenéis: la secretaría unida al pub, todo sembrado, la hoja de
códigos impresa, la guía con enlaces, el backup custodiado y la ficha al día.
