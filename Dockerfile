# imagem leve com Python; adicionamos pandoc + texlive para gerar PDF
FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Instala dependências de sistema (pandoc + texlive mínimo)
RUN apt-get update && apt-get install -y --no-install-recommends \
    pandoc \
    texlive-latex-base texlive-latex-recommended texlive-latex-extra \
    fonts-lmodern ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Bibliotecas Python para o gráfico
RUN pip install --no-cache-dir pandas matplotlib

# Diretório de trabalho dentro do container
WORKDIR /workspace

# Script de execução (vamos copiar já)
COPY run_all.sh /usr/local/bin/run_all.sh
RUN chmod +x /usr/local/bin/run_all.sh

# Deixe o entrypoint no script; os arquivos do projeto virão via bind-mount
ENTRYPOINT ["/usr/local/bin/run_all.sh"]