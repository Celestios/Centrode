import os
import sys
import json
from pathlib import Path
from safetensors.numpy import load_file
import numpy as np

sys.stdout.reconfigure(encoding='utf-8')

OUTPUT_DIR = Path("assets/models/multilingual_5lang")

# Comprehensive Multi-Language Knowledge Graph Relation Test Pairs
# Format: (Language / Category, Term A, Synonym / Equivalent, Antonym / Distinct)
TEST_PAIRS = [
    # --- English ---
    ("EN", "causes", "leads to", "contradicts"),
    ("EN", "depends on", "requires", "supports"),
    ("EN", "contradicts", "opposes", "reinforces"),
    ("EN", "supports", "reinforces", "blocks"),
    ("EN", "part of", "belongs to", "causes"),
    ("EN", "blocks", "prevents", "allows"),
    ("EN", "is married to", "spouse of", "opposes"),
    ("EN", "created by", "authored by", "destroys"),
    ("EN", "similar to", "resembles", "differs from"),
    ("EN", "located in", "situated in", "originates from"),
    ("EN", "contains", "includes", "excludes"),
    ("EN", "derives from", "originates from", "leads to"),
    ("EN", "implies", "suggests", "denies"),
    ("EN", "subclass of", "type of", "instance of"),
    ("EN", "competes with", "rivals", "collaborates with"),
    ("EN", "precedes", "comes before", "follows"),
    ("EN", "succeeds", "comes after", "precedes"),
    ("EN", "connects to", "links to", "isolates from"),
    ("EN", "transforms into", "becomes", "remains"),
    ("EN", "influences", "affects", "ignores"),

    # --- Persian (فارسی) ---
    ("FA", "علت", "منجر می‌شود به", "مخالف"),
    ("FA", "وابسته به", "نیاز دارد به", "همسو"),
    ("FA", "مخالف", "رد می‌کند", "تقویت می‌کند"),
    ("FA", "پشتیبانی می‌کند", "حمایت می‌کند", "مانع می‌شود"),
    ("FA", "بخشی از", "متعلق به", "جدا از"),
    ("FA", "مانع", "جلوگیری می‌کند", "تسهیل می‌کند"),
    ("FA", "همسر", "ازدواج کرده با", "بیگانه"),
    ("FA", "خالق", "نویسنده", "نابودکننده"),
    ("FA", "مشابه", "شبیه به", "متفاوت از"),
    ("FA", "واقع در", "مستقر در", "خارج از"),
    ("FA", "شامل", "حاوی", "فاقد"),
    ("FA", "ناشی از", "برگرفته از", "منجر به"),
    ("FA", "نشان می‌دهد", "بیانگر", "انکار می‌کند"),
    ("FA", "نوعی از", "دسته‌ای از", "مستقل از"),
    ("FA", "رقابت با", "حریف", "همکار"),
    ("FA", "قبل از", "پیش از", "بعد از"),
    ("FA", "بعد از", "پس از", "قبل از"),
    ("FA", "متصل به", "مرتبط با", "جدا از"),
    ("FA", "تبدیل می‌شود به", "تغییر می‌یابد به", "ثابت می‌ماند"),
    ("FA", "تأثیر می‌گذارد بر", "اثرگذار بر", "بی‌تأثیر"),

    # --- Spanish (Español) ---
    ("ES", "causa", "produce", "contradice"),
    ("ES", "depende de", "requiere", "apoya"),
    ("ES", "contradice", "opone", "refuerza"),
    ("ES", "apoya", "respalda", "bloquea"),
    ("ES", "parte de", "pertenece a", "ajeno a"),
    ("ES", "bloquea", "previene", "permite"),
    ("ES", "casado con", "esposo de", "desconocido"),
    ("ES", "creado por", "autor", "destructor"),
    ("ES", "similar a", "parecido a", "diferente de"),
    ("ES", "ubicado en", "situado en", "lejos de"),
    ("ES", "contiene", "incluye", "carece"),
    ("ES", "deriva de", "proviene de", "conduce a"),
    ("ES", "implica", "sugiere", "niega"),
    ("ES", "tipo de", "clase de", "independiente de"),
    ("ES", "compite con", "rival de", "aliado de"),
    ("ES", "antes de", "precede a", "después de"),
    ("ES", "después de", "sigue a", "antes de"),
    ("ES", "conecta con", "enlazado a", "separado de"),
    ("ES", "se transforma en", "se convierte en", "permanece"),
    ("ES", "influye en", "afecta a", "ignora"),

    # --- Arabic (العربية) ---
    ("AR", "سبب", "يؤدي إلى", "يعارض"),
    ("AR", "يعتمد على", "يتطلب", "يدعم"),
    ("AR", "يعارض", "يناقض", "يعزز"),
    ("AR", "يدعم", "يساند", "يعيق"),
    ("AR", "جزء من", "ينتمي إلى", "منفصل عن"),
    ("AR", "يمنع", "يحظر", "يسمح"),
    ("AR", "متزوج من", "زوج", "غريب عن"),
    ("AR", "من تأليف", "مؤلف", "مهدم"),
    ("AR", "مشابه لـ", "يشبه", "يختلف عن"),
    ("AR", "يقع في", "موجود في", "خارج"),
    ("AR", "يحتوي على", "يتضمن", "يخلو من"),
    ("AR", "مشتق من", "ينبع من", "يؤدي إلى"),
    ("AR", "يدل على", "يوحي بـ", "ينكر"),
    ("AR", "نوع من", "فئة من", "مستقل عن"),
    ("AR", "يتنافس مع", "غريم", "حليف"),
    ("AR", "قبل", "يسبق", "بعد"),
    ("AR", "بعد", "يلي", "قبل"),
    ("AR", "متصل بـ", "مرتبط بـ", "منفصل عن"),
    ("AR", "يتحول إلى", "يصبح", "يبقى"),
    ("AR", "يؤثر على", "ينعكس على", "يتجاهل"),

    # --- Chinese (中文) ---
    ("ZH", "导致", "引起", "反对"),
    ("ZH", "依赖", "需要", "支持"),
    ("ZH", "反对", "矛盾", "增强"),
    ("ZH", "支持", "赞成", "阻止"),
    ("ZH", "部分", "属于", "独立于"),
    ("ZH", "阻止", "妨碍", "允许"),
    ("ZH", "配偶", "结婚", "陌生人"),
    ("ZH", "作者", "创作", "破坏"),
    ("ZH", "相似", "类似", "不同于"),
    ("ZH", "位于", "处于", "离开"),
    ("ZH", "包含", "包括", "缺少"),
    ("ZH", "衍生于", "来源于", "通往"),
    ("ZH", "意味着", "表明", "否认"),
    ("ZH", "类型", "种类", "无关"),
    ("ZH", "竞争", "对手", "合作"),

    # --- Cross-Lingual Semantic Equivalences ---
    ("CROSS", "causes (EN)", "علت (FA)", "contradicts (EN)"),
    ("CROSS", "causes (EN)", "causa (ES)", "blocks (EN)"),
    ("CROSS", "causes (EN)", "سبب (AR)", "opposes (EN)"),
    ("CROSS", "causes (EN)", "导致 (ZH)", "prevents (EN)"),
    ("CROSS", "contradicts (EN)", "مخالف (FA)", "supports (EN)"),
    ("CROSS", "contradicts (EN)", "contradice (ES)", "reinforces (EN)"),
    ("CROSS", "contradicts (EN)", "يعارض (AR)", "apoya (ES)"),
    ("CROSS", "contradicts (EN)", "反对 (ZH)", "leads to (EN)"),
    ("CROSS", "depends on (EN)", "وابسته به (FA)", "contradicts (EN)"),
    ("CROSS", "depends on (EN)", "depende de (ES)", "blocks (EN)"),
    ("CROSS", "depends on (EN)", "يعتمد على (AR)", "destroys (EN)"),
    ("CROSS", "depends on (EN)", "依赖 (ZH)", "opposes (EN)"),
    ("CROSS", "part of (EN)", "بخشی از (FA)", "causes (EN)"),
    ("CROSS", "part of (EN)", "parte de (ES)", "contradicts (EN)"),
    ("CROSS", "part of (EN)", "جزء من (AR)", "blocks (EN)"),
    ("CROSS", "part of (EN)", "部分 (ZH)", "opposes (EN)"),
    ("CROSS", "supports (EN)", "پشتیبانی می‌کند (FA)", "blocks (EN)"),
    ("CROSS", "supports (EN)", "apoya (ES)", "contradice (ES)"),
    ("CROSS", "supports (EN)", "يدعم (AR)", "يعارض (AR)"),
    ("CROSS", "supports (EN)", "支持 (ZH)", "反对 (ZH)"),
    ("CROSS", "blocks (EN)", "مانع (FA)", "causes (EN)"),
    ("CROSS", "blocks (EN)", "bloquea (ES)", "leads to (EN)"),
    ("CROSS", "blocks (EN)", "يمنع (AR)", "produces (EN)"),
    ("CROSS", "blocks (EN)", "阻止 (ZH)", "supports (EN)"),
    ("CROSS", "similar to (EN)", "شبیه به (FA)", "different from (EN)"),
    ("CROSS", "similar to (EN)", "parecido a (ES)", "opposite of (EN)"),
    ("CROSS", "similar to (EN)", "مشابه لـ (AR)", "rivals (EN)"),
    ("CROSS", "similar to (EN)", "相似 (ZH)", "blocks (EN)"),
]

def dequantize_int8(tensors, prefix=""):
    weight = tensors[f"{prefix}weight"]
    scale = tensors[f"{prefix}weight.scale"][0]
    return (weight.astype(np.float32) * scale)

def dequantize_q4(tensors, prefix=""):
    packed = tensors[f"{prefix}weight"]
    scales = tensors[f"{prefix}weight.scale"].astype(np.float32)
    orig_shape = tuple(tensors[f"{prefix}weight.shape"])
    
    low = (packed & 0x0F).astype(np.int8)
    high = ((packed >> 4) & 0x0F).astype(np.int8)
    low = np.where(low >= 8, low - 16, low)
    high = np.where(high >= 8, high - 16, high)
    
    unpacked = np.empty((packed.shape[0], packed.shape[1] * 2), dtype=np.int8)
    unpacked[:, 0::2] = low
    unpacked[:, 1::2] = high
    
    unpacked_f32 = unpacked.astype(np.float32) * scales
    flat = unpacked_f32.flatten()
    total_elements = np.prod(orig_shape)
    return flat[:total_elements].reshape(orig_shape)

def get_word_embedding(tensors, token_id, mode="fp16"):
    for k in tensors.keys():
        if "word_embeddings.weight" in k and not k.endswith(".scale") and not k.endswith(".shape"):
            if mode == "fp16":
                return tensors[k][token_id].astype(np.float32)
            elif mode == "int8":
                return dequantize_int8(tensors, prefix=k[:-6])[token_id]
            elif mode == "q4":
                return dequantize_q4(tensors, prefix=k[:-6])[token_id]
    return np.zeros(384, dtype=np.float32)

def cosine_sim(a, b):
    norm_a = np.linalg.norm(a)
    norm_b = np.linalg.norm(b)
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return float(np.dot(a, b) / (norm_a * norm_b))

def clean_term(t: str) -> str:
    # Strip language tag like 'causes (EN)' -> 'causes'
    if " (" in t and t.endswith(")"):
        return t[:t.find(" (")].strip()
    return t.strip()

def evaluate():
    with open(OUTPUT_DIR / "tokenizer.json", "r", encoding="utf-8") as f:
        tok_data = json.load(f)
    
    vocab = {item[0]: idx for idx, item in enumerate(tok_data["model"]["vocab"])}
    
    fp16_tensors = load_file(str(OUTPUT_DIR / "model_fp16.safetensors"))
    int8_tensors = load_file(str(OUTPUT_DIR / "model_int8.safetensors"))
    q4_tensors = load_file(str(OUTPUT_DIR / "model_q4.safetensors"))
    
    print("=" * 88)
    print(f"{'Lang':<5} | {'Target Term':<18} <=> {'Synonym / Match':<20} | {'FP16':<7} | {'INT8':<7} | {'Q4':<7}")
    print("-" * 88)
    
    lang_scores = {"EN": [], "FA": [], "ES": [], "AR": [], "ZH": [], "CROSS": []}
    
    for lang, term_a_raw, term_syn_raw, term_ant_raw in TEST_PAIRS:
        word_a = clean_term(term_a_raw)
        word_syn = clean_term(term_syn_raw)
        
        id_a = vocab.get(f" {word_a}", vocab.get(word_a, 0))
        id_syn = vocab.get(f" {word_syn}", vocab.get(word_syn, 0))
        
        # FP16
        v_a_16 = get_word_embedding(fp16_tensors, id_a, "fp16")
        v_syn_16 = get_word_embedding(fp16_tensors, id_syn, "fp16")
        s_16 = cosine_sim(v_a_16, v_syn_16)
        
        # INT8
        v_a_8 = get_word_embedding(int8_tensors, id_a, "int8")
        v_syn_8 = get_word_embedding(int8_tensors, id_syn, "int8")
        s_8 = cosine_sim(v_a_8, v_syn_8)
        
        # Q4
        v_a_4 = get_word_embedding(q4_tensors, id_a, "q4")
        v_syn_4 = get_word_embedding(q4_tensors, id_syn, "q4")
        s_4 = cosine_sim(v_a_4, v_syn_4)
        
        lang_scores[lang].append((s_16, s_8, s_4))
        
        print(f"{lang:<5} | {term_a_raw:<18} <=> {term_syn_raw:<20} | {s_16:>6.3f}  | {s_8:>6.3f}  | {s_4:>6.3f}")

    print("=" * 88)
    print("\n--- Summary Breakdown by Language Category ---")
    print(f"{'Category':<20} | {'Count':<6} | {'Avg FP16':<10} | {'Avg INT8':<10} | {'Avg Q4':<10} | {'Accuracy Retained'}")
    print("-" * 88)
    
    all_16, all_8, all_4 = [], [], []
    for cat, scores in lang_scores.items():
        if not scores: continue
        avg_16 = np.mean([s[0] for s in scores])
        avg_8 = np.mean([s[1] for s in scores])
        avg_4 = np.mean([s[2] for s in scores])
        retention = (avg_4 / avg_16 * 100) if avg_16 > 0 else 100.0
        
        all_16.extend([s[0] for s in scores])
        all_8.extend([s[1] for s in scores])
        all_4.extend([s[2] for s in scores])
        
        print(f"{cat:<20} | {len(scores):<6} | {avg_16:>9.3f}  | {avg_8:>9.3f}  | {avg_4:>9.3f}  | {retention:>6.2f}%")
        
    print("-" * 88)
    total_retention = (np.mean(all_4) / np.mean(all_16) * 100)
    print(f"{'OVERALL TOTAL':<20} | {len(all_16):<6} | {np.mean(all_16):>9.3f}  | {np.mean(all_8):>9.3f}  | {np.mean(all_4):>9.3f}  | {total_retention:>6.2f}%")
    print("=" * 88)

if __name__ == "__main__":
    evaluate()
