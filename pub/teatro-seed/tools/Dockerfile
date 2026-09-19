# teatro-p2p-tools — herramientas efímeras para sacar una obra del Teatro a la escena P2P (WP-O110).
# Se usa con `docker run --rm` sobre la carpeta de la obra: no se instala nada en el host.
FROM debian:stable-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends mktorrent rhash transmission-cli python3 ca-certificates \
 && rm -rf /var/lib/apt/lists/*
COPY gen_p2p.py /usr/local/bin/gen_p2p.py
WORKDIR /obra
ENTRYPOINT ["python3", "/usr/local/bin/gen_p2p.py"]
