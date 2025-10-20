# 🧠 Matemática Léxiniana — Paper + L1–L4 (Rust)

Este repositório integra **pesquisa teórica** (paper) e **implementação prática** (Rust + Docker)
da **Matemática Léxiniana**, um modelo para validar relações entre léxicos científicos
(L1, L2, L3, L4) aplicados ao desenvolvimento de software — especialmente nas camadas
**Cliente → Prompt → Código → Validador (L4)**.

---

## 📂 Estrutura do Repositório



```
.
lexiniana-paper/
├── Cargo.toml                # Workspace Rust (core + CLI)
├── crates/
│   ├── l4-core/              # Core da análise léxica (delta_sem, validações)
│   └── l4-cli/               # CLI: executa validações L1–L4
├── lexicons/                 # Léxicos de teste (L1, L2, L3)
│   ├── l1_terms.json
│   ├── l2_slots.json
│   ├── l2_outputs.json
│   └── l3_contract.json
├── metrics/                  # CSV e gráficos gerados (delta_sem)
│   ├── delta_sem.csv
│   └── delta_sem_evolution.png
├── paper/
│   ├── build/Matematica_Lexiniana_Paper.pdf
│   └── templates/
├── run_all.sh                # Script principal (gera métricas + PDF)
├── Dockerfile                # Full build (Rust + Pandoc + LaTeX)
├── docker-compose.yml        # Profiles runtime / full
└── README.md

```


---

## 🚀 Rodar localmente

### Primeira execução (build completo)
```bash
# build sem cache (necessário na primeira vez)
export DOCKER_BUILDKIT=1
docker compose --profile full build --no-cache

# executar pipeline completo (valida, plota e gera PDF)
docker compose --profile full up --abort-on-container-exit

```
### Execução incremental
```bash
docker compose up --abort-on-container-exit
```

### Ajustar o threshold sem recompilar
```bash
SEM_THR=0.30 docker compose --profile full up --abort-on-container-exit

```

### 🔬 Exemplo de saída
```bash
==> Diagnóstico: slots_total=2 hits_maps_to=2 metrics_appended=2
timestamp,lexicon_pair,term_a,term_b,delta_sem,pass
2025-10-20T00:43:42Z,L1-L2,Cliente,Classificar Cliente,0.2929,false
2025-10-20T00:43:42Z,L1-L2,Pedido,Classificar Pedido,0.2929,false
```

δ_sem ≈ 0.29 → moderada similaridade semântica.

pass=false pois δ_sem > 0.12.

O resultado é visualizado em metrics/delta_sem_evolution.png
e integrado automaticamente no PDF do paper.



## ⚙️ CI/CD

O diretório .github/workflows/ contém o pipeline de GitHub Actions que:

Constrói a imagem lexiniana-full;

Executa a validação L1–L4;

Gera e publica:

metrics/delta_sem_evolution.png

Matematica_Lexiniana_Paper.pdf como artefatos.





