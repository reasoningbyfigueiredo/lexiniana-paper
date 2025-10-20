use anyhow::Result;
use clap::{Parser, Subcommand};
use std::fs;
use std::io::Write;
use std::path::PathBuf;

use l4_core::{
    L1Terms, L2Outputs, L2Slots,
    validate_semantic, validate_structural, validate_functional,
    delta_sem_bow,
};

#[derive(Parser, Debug)]
#[command(name="l4-cli", about="L4 - Matemática Léxiniana (Full minimal)")]
struct Cli{
    #[command(subcommand)]
    cmd: Cmd
}
#[derive(Subcommand, Debug)]
enum Cmd{
    /// Valida L1-L2-L3 e grava métricas em metrics/delta_sem.csv
    Validate{
        #[arg(long, default_value="./lexicons")] root: PathBuf,
        #[arg(short='t', long, default_value_t=0.12)] semantic_threshold: f32
    }
}

fn append_metric(ts:&str, pair:&str, a:&str, b:&str, delta:f32, pass:bool)->Result<()>{
    let path = PathBuf::from("metrics").join("delta_sem.csv");
    if !path.exists(){
        fs::create_dir_all("metrics")?;
        fs::write(&path, "timestamp,lexicon_pair,term_a,term_b,delta_sem,pass\n")?;
    }
    let mut f = fs::OpenOptions::new().create(true).append(true).open(&path)?;
    writeln!(
        f,
        "{},{},{},{},{:.4},{}",
        ts,
        pair,
        a.replace(",", " "),
        b.replace(",", " "),
        delta,
        pass
    )?;
    f.flush()?;
    Ok(())
}

fn main()->Result<()>{
    let cli = Cli::parse();
    match cli.cmd {
        Cmd::Validate{root, semantic_threshold} => {
            // carrega artefatos
            let l1: L1Terms       = serde_json::from_str(&fs::read_to_string(root.join("L4_validation/tests/l1_terms.json"))?)?;
            let l2: L2Slots       = serde_json::from_str(&fs::read_to_string(root.join("L4_validation/tests/l2_slots.json"))?)?;
            let l2_out: L2Outputs = serde_json::from_str(&fs::read_to_string(root.join("L4_validation/tests/l2_outputs.json"))?)?;
            let l3 = serde_json::from_str::<serde_json::Value>(&fs::read_to_string(root.join("L4_validation/tests/l3_contract.json"))?)?;

            // relatórios
            let r1 = validate_semantic(&l1,&l2,semantic_threshold);
            let r2 = validate_structural(&l2,&l3);
            let r3 = validate_functional(&l2_out,&l3);

            // métricas reais L1-L2
            let id2name: std::collections::HashMap<_,_>=l1.terms.iter().map(|t| (t.id.clone(), t.name.clone())).collect();
            let now = chrono::Utc::now().to_rfc3339();
            let mut written = 0usize;
            let total_slots = l2.slots.len();
            let mut hits_maps_to = 0usize;

            for s in &l2.slots{
                if let Some(nm)=id2name.get(&s.maps_to){
                    hits_maps_to += 1;
                    let d = delta_sem_bow(nm, &s.slot_name);
                    let pass = d <= semantic_threshold;
                    append_metric(&now,"L1-L2", nm, &s.slot_name, d, pass)?;
                    written += 1;
                }
            }

            let all_ok = r1.passed && r2.passed && r3.passed;
            let report = serde_json::json!({
                "suite":"L4 Full Minimal",
                "results":[r1,r2,r3],
                "all_passed":all_ok,
                "diagnostics":{
                    "slots_total": total_slots,
                    "hits_maps_to": hits_maps_to,
                    "metrics_appended": written
                }
            });
            println!("{}", serde_json::to_string_pretty(&report)?);

            std::process::exit(if all_ok {0} else {1});
        }
    }
}
