#!/usr/bin/env bash
set -euo pipefail

# Garante que estamos no diretório montado pelo host (bind-mount)
cd /workspace

echo "==> Preparando diretórios..."
mkdir -p metrics paper/build

# 1) Se existir um l4-cli no repositório, roda validação para registrar dados reais
if [[ -x "./l4-cli" ]]; then
  echo "==> Rodando validação L1–L4 com ./l4-cli ..."
  # IMPORTANTE: seu l4-cli deve escrever/apendar em metrics/delta_sem.csv
  ./l4-cli validate --root ./lexicons --semantic-threshold 0.12 || true
else
  echo "==> l4-cli não encontrado (opcional). Pulando validação real."
  # Garante cabeçalho do CSV para o gráfico não quebrar
  if [[ ! -f metrics/delta_sem.csv ]]; then
    echo "timestamp,lexicon_pair,term_a,term_b,delta_sem,pass" > metrics/delta_sem.csv
  fi
fi

# 2) Gera o gráfico δ_sem
if [[ -f "scripts/plot_semantic_evolution.py" ]]; then
  echo "==> Gerando gráfico δ_sem..."
  python3 scripts/plot_semantic_evolution.py || true
else
  echo "WARN: scripts/plot_semantic_evolution.py não encontrado, pulando gráfico."
fi

# 3) Compila o PDF do paper (Markdown -> PDF)
if [[ -f "paper/Matematica_Lexiniana_Paper.md" ]]; then
  echo "==> Compilando PDF do paper com Pandoc..."
  pandoc paper/Matematica_Lexiniana_Paper.md \
    -V geometry:margin=2.5cm \
    -V mainfont="Latin Modern Roman" \
    --pdf-engine=pdflatex \
    -o paper/build/Matematica_Lexiniana_Paper.pdf
  echo "OK: paper/build/Matematica_Lexiniana_Paper.pdf"
else
  echo "ERRO: paper/Matematica_Lexiniana_Paper.md não encontrado."
  exit 1
fi

echo "==> Finalizado."
echo "Artefatos:"
echo " - metrics/delta_sem.csv (dados)"
echo " - metrics/delta_sem_evolution.png (gráfico, se gerado)"
echo " - paper/build/Matematica_Lexiniana_Paper.pdf (PDF do paper)"
