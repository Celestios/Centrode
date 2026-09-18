pub fn damerau_levenshtein(s1: &str, s2: &str) -> usize {
    let v1: Vec<char> = s1.chars().collect();
    let v2: Vec<char> = s2.chars().collect();
    let len1 = v1.len();
    let len2 = v2.len();

    if len1 == 0 {
        return len2;
    }
    if len2 == 0 {
        return len1;
    }

    let mut d = vec![vec![0usize; len2 + 1]; len1 + 1];

    for i in 0..=len1 {
        d[i][0] = i;
    }
    for j in 0..=len2 {
        d[0][j] = j;
    }

    for i in 1..=len1 {
        for j in 1..=len2 {
            let cost = if v1[i - 1].eq_ignore_ascii_case(&v2[j - 1]) {
                0
            } else {
                1
            };
            d[i][j] = (d[i - 1][j] + 1)
                .min(d[i][j - 1] + 1)
                .min(d[i - 1][j - 1] + cost);

            if i > 1
                && j > 1
                && v1[i - 1].eq_ignore_ascii_case(&v2[j - 2])
                && v1[i - 2].eq_ignore_ascii_case(&v2[j - 1])
            {
                d[i][j] = d[i][j].min(d[i - 2][j - 2] + 1);
            }
        }
    }

    d[len1][len2]
}

pub fn detect_map_language_impl(node_texts: &[String]) -> String {
    let mut fa_ar_count = 0;
    let mut fa_specific_count = 0;
    let mut zh_count = 0;
    let mut es_count = 0;
    let mut en_count = 0;

    for text in node_texts {
        for ch in text.chars() {
            let cp = ch as u32;
            if (0x0600..=0x06FF).contains(&cp) || (0xFB50..=0xFEFF).contains(&cp) {
                fa_ar_count += 1;
                if matches!(ch, 'گ' | 'چ' | 'پ' | 'ژ' | 'ی' | 'ک') {
                    fa_specific_count += 1;
                }
            } else if (0x4E00..=0x9FFF).contains(&cp) || (0x3400..=0x4DBF).contains(&cp) {
                zh_count += 1;
            } else if matches!(
                ch,
                'á' | 'é' | 'í' | 'ó' | 'ú' | 'ñ' | '¿' | '¡' | 'Á' | 'É' | 'Í' | 'Ó' | 'Ú'
                    | 'Ñ'
            ) {
                es_count += 2;
            } else if ch.is_ascii_alphabetic() {
                en_count += 1;
            }
        }
    }

    if fa_ar_count > zh_count && fa_ar_count > es_count && fa_ar_count > en_count {
        if fa_specific_count > 0 {
            "fa".to_string()
        } else {
            "ar".to_string()
        }
    } else if zh_count > fa_ar_count && zh_count > es_count && zh_count > en_count {
        "zh".to_string()
    } else if es_count > 0 && es_count >= (en_count / 3) {
        "es".to_string()
    } else {
        "en".to_string()
    }
}
