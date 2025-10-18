import pandas as pd, matplotlib.pyplot as plt
import os

path = "metrics/delta_sem.csv"
if not os.path.exists(path):
    raise SystemExit("metrics/delta_sem.csv não encontrado")
df = pd.read_csv(path)
if df.empty:
    print("Aviso: metrics/delta_sem.csv está vazio (sem dados).")
    raise SystemExit(0)
df["timestamp"] = pd.to_datetime(df["timestamp"], errors="coerce")
df = df.dropna(subset=["timestamp"]).sort_values("timestamp")
plt.figure(figsize=(10,5))
plt.plot(df["timestamp"], df["delta_sem"], marker="o")
plt.axhline(0.15, linestyle="--", label="Ciência normal (≤0.15)")
plt.axhline(0.30, linestyle="--", label="Crise (0.15–0.30)")
plt.title("Evolução Léxica — δ_sem")
plt.xlabel("Tempo"); plt.ylabel("δ_sem"); plt.legend(); plt.grid(True)
os.makedirs("metrics", exist_ok=True)
out = "metrics/delta_sem_evolution.png"
plt.tight_layout(); plt.savefig(out, dpi=150)
print("OK:", out)
