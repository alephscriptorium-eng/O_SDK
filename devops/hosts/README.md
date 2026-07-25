# devops/hosts/ — instancias

Separación **método vs datos**: los scripts de `devops/scripts/` son genéricos;
cada instancia (un host remoto que corre un pub) declara sus datos aquí.

```
hosts/
├── default                      ← nombre de la instancia activa por defecto
├── ejemplo/host.env.example     ← plantilla para nuevas instancias
└── scriptorium/host.env         ← instancia real (VPS Gandi del Scriptorium)
```

- Selección puntual: `DEVOPS_HOST=<nombre> npm run devops:status`
- Selección permanente: escribir el nombre en `hosts/default`
- Prioridad de valores: entorno del usuario → `host.env` → default del script.

**Nunca** guardes secretos aquí: `host.env` se versiona. Las claves privadas
viven en `devops/.ssh/` (ignorado, deny-by-default) y se generan con
`devops/scripts/init-ssh-key.sh`.
