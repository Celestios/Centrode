#!/usr/bin/env python3
"""
Consolidated ML Embedding Model Pipeline for Centrode.
Downloads sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2,
prunes the vocabulary to the 5 target languages (English, Spanish, Chinese, Arabic, Persian),
applies 4-bit (Q4) or INT8 quantization, and generates production assets for Flutter/Rust.

Usage:
    python scripts/prepare_embedding_model.py [--precision q4|int8|fp16] [--clean-cache]
"""

import os
import sys
import json
import argparse
import urllib.request
from pathlib import Path

# Ensure UTF-8 output on all platforms
if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

try:
    import numpy as np
    from safetensors.numpy import load_file, save_file
except ImportError:
    print("Error: Missing required Python dependencies (numpy, safetensors).")
    print("Please install them using: pip install numpy safetensors")
    sys.exit(1)

MODEL_ID = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
BASE_URL = f"https://huggingface.co/{MODEL_ID}/resolve/main"

FILES = ["config.json", "tokenizer.json", "model.safetensors"]

def download_file(filename: str, cache_dir: Path) -> Path:
    local_path = cache_dir / filename
    if not local_path.exists():
        url = f"{BASE_URL}/{filename}"
        print(f"Downloading {filename} from {url}...")
        urllib.request.urlretrieve(url, local_path)
        print(f"Downloaded {filename} ({local_path.stat().st_size / 1024 / 1024:.2f} MB)")
    else:
        print(f"Using cached {filename} ({local_path.stat().st_size / 1024 / 1024:.2f} MB)")
    return local_path

def is_excluded_script(char: str) -> bool:
    cp = ord(char)
    # Cyrillic
    if 0x0400 <= cp <= 0x052F:
        return True
    # Indic / Devanagari / Bengali / Tamil / Telugu
    if 0x0900 <= cp <= 0x0D7F:
        return True
    # Greek
    if 0x0370 <= cp <= 0x03FF:
        return True
    # Hebrew
    if 0x0590 <= cp <= 0x05FF:
        return True
    # Thai / Lao / Khmer / Myanmar
    if 0x0E00 <= cp <= 0x109F:
        return True
    # Hangul (Korean)
    if (0xAC00 <= cp <= 0xD7AF) or (0x1100 <= cp <= 0x11FF):
        return True
    # Japanese Hiragana / Katakana
    if 0x3040 <= cp <= 0x30FF:
        return True
    return False

def is_target_language_token(token: str) -> bool:
    clean = token.replace(" ", "").replace("##", "").strip()
    if not clean:
        return True
    
    # Exclude if any character belongs to an unselected foreign script
    for char in clean:
        if is_excluded_script(char):
            return False
            
    return True

def quantize_to_int8(tensor: np.ndarray):
    """Symmetric per-tensor INT8 quantization."""
    max_val = np.max(np.abs(tensor))
    if max_val == 0:
        return tensor.astype(np.int8), 1.0
    scale = max_val / 127.0
    q = np.clip(np.round(tensor / scale), -128, 127).astype(np.int8)
    return q, scale

def quantize_to_q4(tensor: np.ndarray):
    """4-bit block-wise quantization (block size 32)."""
    orig_shape = tensor.shape
    flat = tensor.flatten()
    block_size = 32
    pad_len = (block_size - (len(flat) % block_size)) % block_size
    if pad_len > 0:
        flat = np.pad(flat, (0, pad_len))
    
    blocks = flat.reshape(-1, block_size)
    max_vals = np.max(np.abs(blocks), axis=1, keepdims=True)
    scales = np.where(max_vals == 0, 1.0, max_vals / 7.0).astype(np.float16)
    
    q_blocks = np.clip(np.round(blocks / scales), -8, 7).astype(np.int8)
    # Pack two 4-bit signed integers into one uint8 byte
    q_low = q_blocks[:, 0::2] & 0x0F
    q_high = (q_blocks[:, 1::2] & 0x0F) << 4
    packed = (q_low | q_high).astype(np.uint8)
    
    return packed, scales, orig_shape

def build_model(precision: str = "q4", clean_cache: bool = False):
    root_dir = Path(__file__).resolve().parent.parent
    cache_dir = root_dir / "scratch" / "raw_model"
    output_dir = root_dir / "assets" / "models" / "multilingual_5lang"
    
    cache_dir.mkdir(parents=True, exist_ok=True)
    output_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 70)
    print(f"Centrode ML Embedder Preparation [Target: en, es, zh, ar, fa | Precision: {precision.upper()}]")
    print("=" * 70)

    # 1. Download / Load Raw Model Files
    config_path = download_file("config.json", cache_dir)
    tokenizer_path = download_file("tokenizer.json", cache_dir)
    safetensors_path = download_file("model.safetensors", cache_dir)

    # 2. Prune Vocabulary to Target Languages
    print("\n[Step 1/3] Pruning Tokenizer Vocabulary...")
    with open(tokenizer_path, "r", encoding="utf-8") as f:
        tok_data = json.load(f)

    vocab = tok_data["model"]["vocab"]
    kept_old_ids = []
    old_to_new_id = {}

    if isinstance(vocab, list):
        new_vocab = []
        for old_id, item in enumerate(vocab):
            token = item[0] if isinstance(item, (list, tuple)) else item
            score = item[1] if isinstance(item, (list, tuple)) and len(item) > 1 else 0.0
            if is_target_language_token(token):
                new_id = len(kept_old_ids)
                old_to_new_id[old_id] = new_id
                if isinstance(item, (list, tuple)):
                    new_vocab.append([token, score])
                else:
                    new_vocab.append(token)
                kept_old_ids.append(old_id)
    else:
        new_vocab = {}
        for token, old_id in sorted(vocab.items(), key=lambda x: x[1]):
            if is_target_language_token(token):
                new_id = len(kept_old_ids)
                old_to_new_id[old_id] = new_id
                new_vocab[token] = new_id
                kept_old_ids.append(old_id)

    print(f"Vocabulary reduced: {len(vocab):,} -> {len(kept_old_ids):,} tokens (kept ~{len(kept_old_ids)/len(vocab)*100:.1f}%)")
    kept_indices = np.array(kept_old_ids, dtype=np.int64)

    tok_data["model"]["vocab"] = new_vocab
    if "added_tokens" in tok_data and isinstance(tok_data["added_tokens"], list):
        new_added = []
        for item in tok_data["added_tokens"]:
            if item.get("id") in old_to_new_id:
                item["id"] = old_to_new_id[item["id"]]
                new_added.append(item)
        tok_data["added_tokens"] = new_added

    out_tok_path = output_dir / "tokenizer.json"
    with open(out_tok_path, "w", encoding="utf-8") as f:
        json.dump(tok_data, f, ensure_ascii=False)
    print(f"Saved pruned tokenizer: {out_tok_path}")

    # 3. Update config.json
    print("\n[Step 2/3] Updating Architecture Config...")
    with open(config_path, "r", encoding="utf-8") as f:
        cfg_data = json.load(f)
    cfg_data["vocab_size"] = len(kept_old_ids)
    out_cfg_path = output_dir / "config.json"
    with open(out_cfg_path, "w", encoding="utf-8") as f:
        json.dump(cfg_data, f, indent=2)
    print(f"Saved config: {out_cfg_path}")

    # 4. Slice Embedding Table & Quantize
    print(f"\n[Step 3/3] Slicing and Quantizing Weights ({precision.upper()})...")
    raw_tensors = load_file(str(safetensors_path))
    sliced_tensors = {}

    for name, tensor in raw_tensors.items():
        if "word_embeddings.weight" in name or "embeddings.word_embeddings.weight" in name:
            sliced_tensors[name] = tensor[kept_indices, :]
        else:
            sliced_tensors[name] = tensor

    final_tensors = {}
    if precision == "fp16":
        final_tensors = {k: v.astype(np.float16) for k, v in sliced_tensors.items()}
    elif precision == "int8":
        for k, v in sliced_tensors.items():
            if "weight" in k and "layer_norm" not in k and "bias" not in k and v.ndim >= 2:
                q, scale = quantize_to_int8(v)
                final_tensors[k] = q
                final_tensors[f"{k}.scale"] = np.array([scale], dtype=np.float32)
            else:
                final_tensors[k] = v.astype(np.float16)
    elif precision == "q4":
        for k, v in sliced_tensors.items():
            if "weight" in k and "layer_norm" not in k and "bias" not in k and v.ndim >= 2:
                packed, scales, orig_shape = quantize_to_q4(v)
                final_tensors[k] = packed
                final_tensors[f"{k}.scale"] = scales
                final_tensors[f"{k}.shape"] = np.array(orig_shape, dtype=np.int32)
            else:
                final_tensors[k] = v.astype(np.float16)

    out_model_path = output_dir / "model.safetensors"
    save_file(final_tensors, str(out_model_path))
    final_size_mb = out_model_path.stat().st_size / 1024 / 1024
    print(f"Saved model asset: {out_model_path} ({final_size_mb:.2f} MB)")

    if clean_cache and cache_dir.exists():
        import shutil
        shutil.rmtree(cache_dir)
        print("Cleaned temporary download cache.")

    print("\n" + "=" * 70)
    print("SUCCESS: Embedder assets ready in assets/models/multilingual_5lang/")
    print("=" * 70)

def main():
    parser = argparse.ArgumentParser(description="Prepare Centrode ML Embedding Model")
    parser.add_argument(
        "--precision",
        choices=["q4", "int8", "fp16"],
        default="q4",
        help="Quantization precision (default: q4)",
    )
    parser.add_argument(
        "--clean-cache",
        action="store_true",
        help="Remove scratch download cache after generating assets",
    )
    args = parser.parse_args()
    build_model(precision=args.precision, clean_cache=args.clean_cache)

if __name__ == "__main__":
    main()
