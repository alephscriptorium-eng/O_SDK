import { defineConfig } from 'vitepress';

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
    'PUB/deploy.md'
  ],
  themeConfig: {
    back: BACK,
    backLinks,
    nav: [
      { text: 'Portada', link: '/' },
      { text: 'Proyecto', link: '/proyecto' },
      {
        text: 'Operación',
        items: [
          { text: 'Protocolo de upgrade', link: '/PUB/UPGRADE-PROTOCOL' },
          { text: 'Protocolo de recuperación', link: '/PUB/RECOVERY-PROTOCOL' }
        ]
      },
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
      {
        text: 'Operación',
        items: [
          { text: 'Protocolo de upgrade', link: '/PUB/UPGRADE-PROTOCOL' },
          { text: 'Protocolo de recuperación', link: '/PUB/RECOVERY-PROTOCOL' }
        ]
      }
    ],
    socialLinks: [{ icon: 'github', link: BACK.repo }],
    outline: { level: [2, 3] },
    search: { provider: 'local' },
    footer: {
      // VPFooter hace v-html de message → enlaces desde la misma fuente única
      message: backLinks
        .map(
          (l) =>
            `<a href="${l.link}" target="_blank" rel="noreferrer">${l.text}</a>`
        )
        .join('<span aria-hidden="true"> · </span>'),
      copyright: 'Oasis SDK · fork dockerizado FOSS'
    }
  }
});
