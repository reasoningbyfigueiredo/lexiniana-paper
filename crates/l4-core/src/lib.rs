use anyhow::Result;
use regex::Regex;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct L1Term { pub id:String, pub name:String, #[serde(default)] pub aliases:Vec<String> }
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct L1Terms { pub terms: Vec<L1Term> }

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct L2Slot { pub slot_name:String, pub maps_to:String }
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct L2Slots { pub slots:Vec<L2Slot>, #[serde(default)] pub output_schema_required:Vec<String> }

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct L2Outputs { pub samples: Vec<Value> }

#[derive(Debug, Serialize, Deserialize)]
pub struct Report { pub validator:String, pub passed:bool, pub details:Value }

fn tokenize(s:&str)->Vec<String>{
    let re = Regex::new(r"[A-Za-zÀ-ÿ0-9]+").unwrap();
    re.find_iter(&s.to_lowercase()).map(|m| m.as_str().to_string()).collect()
}
fn bag(words:&[String])->HashMap<String,f32>{
    let mut m=HashMap::new();
    for w in words { *m.entry(w.clone()).or_insert(0.0)+=1.0; }
    m
}
fn cosine_bow(a:&HashMap<String,f32>, b:&HashMap<String,f32>)->f32{
    let mut keys:Vec<String>=a.keys().cloned().collect();
    for k in b.keys(){ if !a.contains_key(k){ keys.push(k.clone()); } }
    let mut dot=0.0; let mut na=0.0; let mut nb=0.0;
    for k in keys{
        let va=*a.get(&k).unwrap_or(&0.0);
        let vb=*b.get(&k).unwrap_or(&0.0);
        dot+=va*vb; na+=va*va; nb+=vb*vb;
    }
    if na==0.0 || nb==0.0 { return 0.0; }
    dot/(na.sqrt()*nb.sqrt())
}
pub fn delta_sem_bow(a:&str,b:&str)->f32{ 1.0 - cosine_bow(&bag(&tokenize(a)), &bag(&tokenize(b))) }

pub fn validate_semantic(l1:&L1Terms, l2:&L2Slots, thr:f32)->Report{
    let id2name:HashMap<_,_>=l1.terms.iter().map(|t| (t.id.clone(), t.name.clone())).collect();
    let mut checks=Vec::new(); let mut ok=true;
    for s in &l2.slots{
        if let Some(nm)=id2name.get(&s.maps_to){
            let d=delta_sem_bow(nm, &s.slot_name);
            let pass=d<=thr; ok&=pass;
            checks.push(serde_json::json!({"slot":s.slot_name,"l1_term":nm,"delta_sem":(d*10000.0).round()/10000.0,"pass":pass}));
        }
    }
    Report{ validator:"semantic".into(), passed:ok, details:serde_json::json!({"threshold":thr,"checks":checks}) }
}

pub fn validate_structural(l2:&L2Slots, l3:&Value)->Report{
    let required=l2.output_schema_required.clone();
    let mut available=Vec::new();
    if let Some(map)=l3.get("properties").and_then(|v| v.as_object()){ for k in map.keys(){ available.push(k.clone()); } }
    let missing:Vec<String>=required.iter().filter(|r| !available.contains(r)).cloned().collect();
    let ok=missing.is_empty();
    Report{ validator:"structural".into(), passed:ok,
        details:serde_json::json!({"required_in_L2":required,"available_in_L3":available,"missing_in_L3":missing}) }
}

fn json_schema_min_validate(obj:&Value, schema:&Value)->Vec<String>{
    let mut errs=Vec::new();
    if let Some(reqs)=schema.get("required").and_then(|v| v.as_array()){
        for r in reqs{ if let Some(nm)=r.as_str(){ if obj.get(nm).is_none(){ errs.push(format!("Missing required field: {}", nm)); } } }
    }
    errs
}
pub fn validate_functional(samples:&L2Outputs, l3:&Value)->Report{
    let mut cases=Vec::new(); let mut ok=true;
    for (i,s) in samples.samples.iter().enumerate(){
        let errs=json_schema_min_validate(s,l3); ok&=errs.is_empty();
        cases.push(serde_json::json!({"index":i,"errors":errs}));
    }
    Report{ validator:"functional".into(), passed:ok, details:serde_json::json!({"cases":cases}) }
}
