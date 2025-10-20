#!/usr/bin/env bash
set -euo pipefail
cd /workspace

echo "==> Preparando diretórios..."
mkdir -p metrics paper/build

echo "==> Inspecionando fixtures:"
ls -lah lexicons/L4_validation/tests || true
echo "---- l1_terms.json ----"
sed -n '1,200p' lexicons/L4_validation/tests/l1_terms.json || true
echo "---- l2_slots.json ----"
sed -n '1,200p' lexicons/L4_validation/tests/l2_slots.json || true

# garante cabeçalho do CSV
if [[ ! -f metrics/delta_sem.csv ]]; then
  echo "timestamp,lexicon_pair,term_a,term_b,delta_sem,pass" > metrics/delta_sem.csv
fi
CSV_BEFORE_BYTES=$(wc -c < metrics/delta_sem.csv || echo 0)

echo "==> Validando L1–L4 (l4-cli)..."
# Captura STDOUT em JSON e STDERR (diagnósticos) separadamente
# - stdout -> /tmp/l4_report.json
# - stderr -> /tmp/l4_stderr.log
set +e
l4-cli validate --root ./lexicons --semantic-threshold 0.12 \
  1> /tmp/l4_report.json \
  2> /tmp/l4_stderr.log
CLI_EXIT=$?
set -e

echo "==> STDERR do l4-cli (diagnóstico):"
sed -n '1,200p' /tmp/l4_stderr.log || true

echo "==> STDOUT do l4-cli (relatório JSON):"
sed -n '1,200p' /tmp/l4_report.json || true

# Se o STDOUT estiver vazio, já sinaliza
if [[ ! -s /tmp/l4_report.json ]]; then
  echo "ERRO: l4-cli não produziu JSON no STDOUT (arquivo vazio). Exit code: ${CLI_EXIT}"
  exit 3
fi

# Usa jq para puxar métricas
APP=$(jq -r '.diagnostics.metrics_appended // 0' /tmp/l4_report.json 2>/dev/null || echo 0)
HIT=$(jq -r '.diagnostics.hits_maps_to // 0' /tmp/l4_report.json 2>/dev/null || echo 0)
SLO=$(jq -r '.diagnostics.slots_total // 0' /tmp/l4_report.json 2>/dev/null || echo 0)
echo "==> Diagnóstico: slots_total=${SLO} hits_maps_to=${HIT} metrics_appended=${APP}"

echo "==> CSV após validação:"
sed -n '1,200p' metrics/delta_sem.csv

CSV_AFTER_BYTES=$(wc -c < metrics/delta_sem.csv || echo 0)
if [[ "$CSV_AFTER_BYTES" -le "$CSV_BEFORE_BYTES" ]]; then
  echo "ERRO: nenhuma métrica foi gravada em metrics/delta_sem.csv (bytes antes=$CSV_BEFORE_BYTES, depois=$CSV_AFTER_BYTES)."
  echo "Dica: verifique hits_maps_to no JSON e mapeamentos L2.maps_to vs L1.terms[].id"
  exit 2
fi

echo "==> Gerando gráfico δ_sem..."
python3 scripts/plot_semantic_evolution.py

echo "==> Compilando PDF do paper (XeLaTeX, Unicode-ready)..."
pandoc paper/Matematica_Lexiniana_Paper.md \
  -f markdown+tex_math_dollars+raw_tex \
  -V geometry:margin=2.5cm \
  -V mainfont="Noto Serif" \
  --pdf-engine=xelatex \
  -o paper/build/Matematica_Lexiniana_Paper.pdf

echo "==> Finalizado. Artefatos:"
ls -lh metrics/* || true
ls -lh paper/build/*.pdf
