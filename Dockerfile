# =========================
# Stage 1 — Builder (Rust)
# =========================
FROM rust:1.81-slim AS builder
WORKDIR /src

# Dependências de build
RUN apt-get update && apt-get install -y --no-install-recommends \
      pkg-config libssl-dev ca-certificates build-essential \
    && rm -rf /var/lib/apt/lists/*

ENV CARGO_TERM_COLOR=always CARGO_BUILD_JOBS=12

# 1) Copia apenas manifestos (aproveitar cache)
COPY Cargo.toml ./
COPY crates/l4-core/Cargo.toml crates/l4-core/Cargo.toml
COPY crates/l4-cli/Cargo.toml  crates/l4-cli/Cargo.toml

# 2) Stubs para habilitar lockfile (evita "no targets specified")
RUN mkdir -p crates/l4-core/src crates/l4-cli/src && \
    printf "pub fn noop(){}\n" > crates/l4-core/src/lib.rs && \
    printf "fn main(){}\n"     > crates/l4-cli/src/main.rs

# 3) Lockfile + build "fake" para cachear deps
RUN cargo generate-lockfile
RUN cargo build --release -p l4-cli || true

# 4) Copia código real e compila binário final (com verificação)
COPY . .

# Mostra topo do main.rs para garantir que o código REAL foi copiado
RUN test -f crates/l4-cli/src/main.rs && sed -n '1,80p' crates/l4-cli/src/main.rs

# Limpa qualquer resíduo e recompila do zero
RUN cargo clean && cargo build --release -p l4-cli

# Sanity check: o binário PRECISA conter as strings abaixo; se não, FAIL
RUN apt-get update && apt-get install -y --no-install-recommends binutils && rm -rf /var/lib/apt/lists/*
RUN strings target/release/l4-cli | grep -E "L4 Full Minimal|metrics_appended|\\+metric: pair=L1-L2" -n

# =========================
# Stage 2 — Runtime (Python + LaTeX + l4-cli)
# =========================
FROM python:3.11-slim
WORKDIR /workspace
ENV DEBIAN_FRONTEND=noninteractive

# Pandoc/LaTeX + fontes Unicode + utilitários de debug
RUN apt-get update && apt-get install -y --no-install-recommends \
      pandoc \
      texlive-latex-base texlive-latex-recommended texlive-latex-extra \
      texlive-fonts-recommended lmodern texlive-xetex \
      fonts-noto-core ca-certificates \
      jq binutils \
    && rm -rf /var/lib/apt/lists/*

# Bibliotecas Python para o gráfico
RUN pip install --no-cache-dir pandas matplotlib

# Binário e script
COPY --from=builder /src/target/release/l4-cli /usr/local/bin/l4-cli
COPY run_all.sh /usr/local/bin/run_all.sh
RUN chmod +x /usr/local/bin/run_all.sh /usr/local/bin/l4-cli

ENTRYPOINT ["/usr/local/bin/run_all.sh"]
