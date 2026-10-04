import { defineConfig } from 'vitepress';
import { readFileSync } from 'node:fs';

/**
 * O_SDK docs portal — Oasis (SSB) dockerized fork.
 *
 * base Pages (custom domain o-sdk.escrivivir.co): `/` también en Actions.
 * Local / docs:dev: `/`. Override opcional OASIS_DOCS_BASE (sin slash
 * inicial: Git Bash/MSYS reescribe rutas tipo `/foo/`). Frágil #2.
 */
function resolveDocsBase() {
  const raw = process.env.OASIS_DOCS_BASE?.trim();
  if (raw) {
    // MSYS path conversion → `C:/Program Files/Git/...` — no es un base válido
    if (/^[A-Za-z]:[\\/]/.test(raw)) return '/';
    const cleaned = raw.replace(/^\/+|\/+$/g, '');
    return cleaned ? `/${cleaned}/` : '/';
  }
  return '/';
}

/** Back-links del mundo (fuente única · B11 / DC-24). No duplicar en páginas. */
const BACK = {
  repo: 'https://github.com/alephscriptorium-eng/O_SDK',
  registry: 'https://npm.scriptorium.escrivivir.co',
  actions: 'https://github.com/alephscriptorium-eng/O_SDK/actions',
  pages: 'https://o-sdk.escrivivir.co',
  changelog:
    'https://github.com/alephscriptorium-eng/O_SDK/blob/main/CHANGELOG.md',
  issues: 'https://github.com/alephscriptorium-eng/O_SDK/issues'
};

/**
 * Datos vivos: se leen del sistema al construir y no se escriben a mano en ninguna página
 * (BASE-1 §6: «versiones paramétricas»). Se pintan con el componente Vivo; el gate de verdad
 * (docs/.vitepress/verdad-checks.json) falla si salen vacíos o si alguien vuelve a escribirlos.
 * El workflow reconstruye el portal cuando cambia src/server/package.json.
 */
const VIVO = {
  oasisVersion: JSON.parse(
    readFileSync(new URL('../../src/server/package.json', import.meta.url), 'utf8')
  ).version
};

/** Puertas por rol: una página por rol en docs/roles/, que es a la vez la receta del agente. */
const puertas = [
  { text: 'Todas las puertas', link: '/roles/' },
  { text: 'Cliente Oasis · tu nodo en tu máquina', link: '/roles/cliente' },
  { text: 'Pub Oasis · un pub en tu servidor', link: '/roles/pub' },
  { text: 'Economía Oasis · ECOin', link: '/roles/economia' },
  { text: 'Hazlo tuyo · tu propia instancia', link: '/roles/tu-pub' },
  { text: 'Mantener · subir de versión, recuperar', link: '/roles/mantener' },
  { text: 'Agente · el protocolo', link: '/AGENTES' }
];

const backLinks = [
  { text: 'Repositorio', link: BACK.repo },
  { text: 'Registry', link: BACK.registry },
  { text: 'CI / Actions', link: BACK.actions },
  { text: 'Pages', link: BACK.pages },
  { text: 'Issues', link: BACK.issues }
];

export default defineConfig({
  title: 'Oasis SDK',
  description:
    'Fork dockerizado de Oasis (SSB): red social descentralizada auto-alojada — cliente + pub + IA local. Identidad soberana, sin nube.',
  lang: 'es',
  base: resolveDocsBase(),
  cleanUrls: true,
  ignoreDeadLinks: false,
  // Solo entran al portal las superficies que controlamos. La doc técnica
  // importada de upstream se enlaza a la forja, no se re-renderiza aquí.
  srcExclude: [
    'AI/**',
    'devs/**',
    'install/**',
    'CHANGELOG.md',
    'security.md',
    'PUB/deploy.md',
    'PUB/clearnet.md'
  ],
  themeConfig: {
    back: BACK,
    backLinks,
    vivo: VIVO,
    nav: [
      { text: 'Portada', link: '/' },
      { text: '¿Quién llega?', items: puertas },
      { text: 'Proyecto', link: '/proyecto' },
      {
        text: 'Operación',
        items: [
          { text: 'Protocolo para agentes', link: '/AGENTES' },
          { text: 'Ficha de instancia · Scriptorium', link: '/PUB/INSTANCIA-SCRIPTORIUM' },
          { text: 'Ficha de instancia · plantilla', link: '/PUB/INSTANCIA-PLANTILLA' },
          { text: 'Protocolo de upgrade', link: '/PUB/UPGRADE-PROTOCOL' },
          { text: 'Protocolo de recuperación', link: '/PUB/RECOVERY-PROTOCOL' },
          { text: 'Capacidad', link: '/PUB/CAPACIDAD' },
          { text: 'Protocolo del Teatro', link: '/PUB/TEATRO-PROTOCOL' },
          { text: 'Protocolo del sidecar de RRSS', link: '/PUB/RRSS-SIDECAR-PROTOCOL' },
          { text: 'Protocolo del Teatro P2P', link: '/PUB/TEATRO-P2P-PROTOCOL' },
          { text: 'Protocolo de curaduría del Teatro', link: '/PUB/TEATRO-CURADURIA-PROTOCOL' },
          { text: 'Protocolo del HUB clearnet', link: '/PUB/HUB-PROTOCOL' },
          { text: 'Protocolo de ECOin (hub-wallet)', link: '/PUB/ECOIN-PROTOCOL' },
          { text: 'Protocolo del cliente', link: '/CLIENT-PROTOCOL' }
        ]
      },
      { text: 'Roadmap', link: '/ROADMAP/' },
      { text: 'Repo', link: BACK.repo }
    ],
    sidebar: [
      {
        text: 'Oasis SDK',
        items: [
          { text: 'Portada', link: '/' },
          { text: 'Proyecto · DevOps', link: '/proyecto' }
        ]
      },
      { text: '¿Quién llega?', items: puertas },
      {
        text: 'Operación',
        items: [
          { text: 'Protocolo para agentes', link: '/AGENTES' },
          { text: 'Ficha de instancia · Scriptorium', link: '/PUB/INSTANCIA-SCRIPTORIUM' },
          { text: 'Ficha de instancia · plantilla', link: '/PUB/INSTANCIA-PLANTILLA' },
          { text: 'Protocolo de upgrade', link: '/PUB/UPGRADE-PROTOCOL' },
          { text: 'Protocolo de recuperación', link: '/PUB/RECOVERY-PROTOCOL' },
          { text: 'Capacidad', link: '/PUB/CAPACIDAD' },
          { text: 'Protocolo del Teatro', link: '/PUB/TEATRO-PROTOCOL' },
          { text: 'Protocolo del sidecar de RRSS', link: '/PUB/RRSS-SIDECAR-PROTOCOL' },
          { text: 'Protocolo del Teatro P2P', link: '/PUB/TEATRO-P2P-PROTOCOL' },
          { text: 'Protocolo de curaduría del Teatro', link: '/PUB/TEATRO-CURADURIA-PROTOCOL' },
          { text: 'Protocolo del HUB clearnet', link: '/PUB/HUB-PROTOCOL' },
          { text: 'Protocolo de ECOin (hub-wallet)', link: '/PUB/ECOIN-PROTOCOL' },
          { text: 'Protocolo del cliente', link: '/CLIENT-PROTOCOL' }
        ]
      },
      {
        text: 'Roadmap futuro',
        items: [
          { text: 'Los dosieres', link: '/ROADMAP/' },
          { text: 'Aleph net', link: '/ROADMAP/aleph-net/00-indice' },
          { text: 'Relacional', link: '/ROADMAP/relacional/00-dictamen' },
          { text: 'Colectivizaciones', link: '/ROADMAP/colectivizaciones/00-dictamen' },
          { text: 'Res publica', link: '/ROADMAP/res-publica/00-dictamen' },
          { text: 'Oasis · FairCoin', link: '/ROADMAP/oasis-faircoin/00-informe' },
          { text: 'Publicidad y redes', link: '/ROADMAP/publicidad-rrss/00-indice' },
          { text: 'P2P', link: '/ROADMAP/p2p/00-indice' }
        ]
      }
    ],
    socialLinks: [{ icon: 'github', link: BACK.repo }],
    outline: { level: [2, 3], label: 'En esta página' },
    docFooter: { prev: 'Anterior', next: 'Siguiente' },
    returnToTopLabel: 'Volver arriba',
    sidebarMenuLabel: 'Menú',
    darkModeSwitchLabel: 'Apariencia',
    search: { provider: 'local' },
    footer: {
      // Marca Scriptorium (misma línea que Z_SDK/S_SDK). VPFooter hace v-html
      // de message → enlaces desde la fuente única BACK.
      message: [
        'Back:',
        `<a href="${BACK.repo}">repo</a>`,
        '·',
        `<a href="${BACK.registry}">registry</a>`,
        '·',
        `<a href="${BACK.actions}">CI</a>`,
        '·',
        '<a href="/proyecto">proyecto</a>',
        '· Animus Iocandi AIPLv1'
      ].join(' '),
      copyright: 'Scriptorium · Oasis SDK'
    }
  }
});
