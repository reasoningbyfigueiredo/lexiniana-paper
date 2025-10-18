# Matemática Léxiniana — Paper + L1–L4 (Rust)

Este repositório contém:
- **paper/**: Markdown bilíngue como fonte única + PDF gerado no CI
- **lexicons/**: artefatos de teste L1/L2/L3/L2_outputs (fonte da verdade do contexto)
- **metrics/**: série temporal de δ_sem (preenchida pelo validador L4)
- **scripts/**: utilidades (gráfico δ_sem)
- **.github/workflows/**: CI para validar, plotar e gerar PDF

## Como criar o repositório
```bash
export REPO=lexiniana-paper
mkdir $REPO && cd $REPO && git init
git remote add origin git@github.com:reasoningbyfigueiredo/$REPO.git

# copie o conteúdo deste pacote para dentro do diretório e então:
git add .
git commit -m "chore: initial paper + L1–L4 scaffolding"
git push -u origin main
```


## Rodar localmente
```bash
# 1) (Opcional) rodar validação L1–L4 se você tiver o l4-cli em PATH
./target/release/l4-cli validate --root ./lexicons --semantic-threshold 0.12

# 2) Gerar gráfico δ_sem
python3 scripts/plot_semantic_evolution.py
```

## Estrutura
```
.
├─ README.md
├─ paper/
│  ├─ Matematica_Lexiniana_Paper.md
│  └─ build/  (PDF gerado pelo CI)
├─ lexicons/
│  └─ L4_validation/tests/
│     ├─ l1_terms.json
│     ├─ l2_slots.json
│     ├─ l3_contract.json
│     └─ l2_outputs.json
├─ metrics/
│  ├─ delta_sem.csv
│  └─ delta_sem_evolution.png  (gerado)
├─ scripts/
│  └─ plot_semantic_evolution.py
└─ .github/workflows/
   ├─ ci.yml
   └─ docs.yml
```
