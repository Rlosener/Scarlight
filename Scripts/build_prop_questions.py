#!/usr/bin/env python3
"""Generate prop_questions.json from embedded prop-specific card content."""

import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

sys.path.insert(0, str(Path(__file__).resolve().parent))
from card_content_utils import duration_from_text, normalize_field_text

REPO_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_PATH = REPO_ROOT / "Scarlight/Resources/prop_questions.json"
TIER_CONTENT_PATH = REPO_ROOT / "Scripts/prop_tier_content.json"
TIER_CONTENT_BATCH2_PATH = REPO_ROOT / "Scripts/prop_tier_content_batch2.json"
STIM_CONTENT_PATH = REPO_ROOT / "Scripts/prop_stim_content.json"
DECK_PACKS_PATH = REPO_ROOT / "Scarlight/Resources/deck_packs.json"

TIER_INTENSITY = {
    "beginning": 2,
    "medium": 3,
    "hot": 5,
}

INTENSITY = 5
CONTENT_TIER = "hot"
MIN_PLAYERS = 2
MAX_PLAYERS = 3
HT_DEFAULT_DURATION = 45
TASK_DEFAULT_DURATION = 60

DECK_CONFIG = {
    "nhi": {
        "deckType": "neverHaveI",
        "phase": "boldQuestion",
        "type": "question",
        "id_prefix": "prop_nhi",
    },
    "ht": {
        "deckType": "hardTruth",
        "phase": "boldQuestion",
        "type": "question",
        "id_prefix": "prop_ht",
    },
    "ha": {
        "deckType": "hardAction",
        "phase": "timedTask",
        "type": "task",
        "id_prefix": "prop_ha",
    },
    "fr": {
        "deckType": "fantasyRole",
        "phase": "roleDuo",
        "type": "roleDuo",
        "id_prefix": "prop_fr",
    },
}

# slug, prop_id, title, prop_category, nhi[5], ht[5], ha[5], fr[5]
PROP_SECTIONS: List[Dict] = [
    {
        "slug": "kelepce",
        "prop_id": "hot_0",
        "title": "Kelepçe",
        "prop_category": "hotStimulating",
        "nhi": [
            "Ben hiç kelepçeyi birine takıp anahtarı saklamadım. (Yaptıysan: {HO}'yu kelepçele, anahtarı 5 dakika sakla.)",
            "Ben hiç kelepçeli birini yatakta bağlıyken yalayıp durdurmadım. (Yaptıysan: {HO}'yu kelepçele, 3 dakika yala, durdur, 1 dakika bekle.)",
            "Ben hiç kelepçeyi birinin boynuna takıp tasma gibi gezdirmedi. (Yaptıysan: {HO}'nun boynuna kelepçeyi tak, 3 dakika gezdir.)",
            "Ben hiç kelepçeli birini duvara yaslayıp arkadan zorlamadım. (Yaptıysan: {HO}'yu kelepçele, duvara yasla, 3 dakika arkadan zorla.)",
            "Ben hiç kelepçeyi birinin ayak bileklerine takıp bacaklarını açmadım. (Yaptıysan: {HO}'nun ayak bileklerine kelepçeyi tak, 3 dakika bacaklarını açık tut.)",
        ],
        "ht": [
            "Kelepçe takıldığında en çok hangi fantezi aklına gelir?",
            "Kelepçeli birini en çok neresinden yalamak istersin?",
            "Kelepçeyi birine takarken en çok ne söylemek istersin?",
            "Kelepçeli birini izlerken en çok ne yapmak istersin?",
            "Kelepçe sesi duyduğunda vücudunda ne hissediyorsun?",
        ],
        "ha": [
            "{AO}, {HO}'yu kelepçele, 4 dakika boyunca her yerini yala.",
            "{AO}, {HO}'nun ellerini kelepçele, 3 dakika boyunca em.",
            "{AO}, {HO}'yu kelepçele, 4 dakika boyunca duvara yasla ve zorla.",
            "{AO}, {HO}'nun ayak bileklerini kelepçele, 3 dakika boyunca bacaklarını aç.",
            "{AO}, {HO}'yu kelepçele, 4 dakika boyunca gözlerinin içine bakarak yala.",
        ],
        "fr": [
            "Kelepçe Sorgusu: {AO}, {HO}'yu kelepçeler ve 5 dakika boyunca en derin fantezilerini sorgular.",
            "Kelepçeli Köle: {HO} kelepçelenir, 5 dakika boyunca {AO}'nun her dediğini yapar.",
            "Kelepçeli Dans: {AO}, {HO}'yu kelepçeler ve 5 dakika boyunca müzikle dans ettirir.",
            "Kelepçeli İtaat: {HO} kelepçelenir, 5 dakika boyunca {AO}'ya itaat eder.",
            "Kelepçeli Şehvet: {AO}, {HO}'yu kelepçeler ve 5 dakika boyunca şehvetle okşar.",
        ],
    },
    {
        "slug": "tuy",
        "prop_id": "hot_1",
        "title": "Tüy",
        "prop_category": "hotStimulating",
        "nhi": [
            "Ben hiç tüyle birini gıdıklayıp kıvrandırmadım. (Yaptıysan: {HO}'yu 3 dakika tüyle gıdıkla.)",
            "Ben hiç tüyü birinin vücudunda gezdirip tahrik etmedim. (Yaptıysan: {HO}'nun vücudunda 3 dakika tüy gezdir.)",
            "Ben hiç tüyle birinin meme ucunu uyarmadım. (Yaptıysan: {HO}'nun meme ucunu 3 dakika tüyle uyar.)",
            "Ben hiç tüyü birinin bacak arasında kullanmadım. (Yaptıysan: {HO}'nun bacak arasında 3 dakika tüy gezdir.)",
            "Ben hiç tüyle birinin boynunu okşayıp ürpertmedi. (Yaptıysan: {HO}'nun boynunu 3 dakika tüyle okşa.)",
        ],
        "ht": [
            "Tüy vücudunda en çok nerede tahrik eder?",
            "Tüyle gıdıklanmak mı, okşanmak mı daha çok hoşuna gider?",
            "Tüyü birine karşı kullanırken en çok neresine odaklanırsın?",
            "Tüyün teması mı, sesi mi seni daha çok etkiler?",
            "Tüyle en çok hangi fanteziyi gerçekleştirmek istersin?",
        ],
        "ha": [
            "{AO}, {HO}'nun vücudunda 4 dakika tüy gezdir.",
            "{AO}, {HO}'nun meme uçlarını 3 dakika tüyle uyar.",
            "{AO}, {HO}'nun bacak arasında 4 dakika tüy gezdir.",
            "{AO}, {HO}'nun boynunu 3 dakika tüyle okşa.",
            "{AO}, {HO}'yu 4 dakika tüyle gıdıkla, kıvrandır.",
        ],
        "fr": [
            "Tüy Oyunu: {AO}, {HO}'yu 5 dakika tüyle okşar, {HO} kıvranır.",
            "Gıdıklama Seansı: {AO}, {HO}'yu 5 dakika tüyle gıdıklar, {HO} inler.",
            "Tüy Keşfi: {AO}, {HO}'nun vücudunu 5 dakika tüyle keşfeder.",
            "Tüy İşkencesi: {AO}, {HO}'yu 5 dakika tüyle zorlar, {HO} yalvarır.",
            "Tüy Şehvet: {AO}, {HO}'yu 5 dakika tüyle tahrik eder.",
        ],
    },
    {
        "slug": "ip",
        "prop_id": "hot_2",
        "title": "İp",
        "prop_category": "hotStimulating",
        "nhi": [
            "Ben hiç ipi birinin bileklerine bağlayıp kontrol etmedim. (Yaptıysan: {HO}'nun bileklerini bağla, 3 dakika yönlendir.)",
            "Ben hiç ipi birinin bacaklarına dolayıp açık tutmadım. (Yaptıysan: {HO}'nun bacaklarına ip dol, 3 dakika açık tut.)",
            "Ben hiç ipi birinin boynuna dolayıp çekmedim. (Yaptıysan: {HO}'nun boynuna ip dol, 3 dakika çek.)",
            "Ben hiç ipi birinin gözlerine bağlayıp yönlendirmedim. (Yaptıysan: {HO}'nun gözlerini bağla, 3 dakika yönlendir.)",
            "Ben hiç ipi birinin beline bağlayıp çekmedim. (Yaptıysan: {HO}'nun beline ip bağla, 3 dakika çek.)",
        ],
        "ht": [
            "İp bağlandığında en çok hangi his ağır basar?",
            "İpi birine bağlarken en çok ne düşünürsün?",
            "İp vücudunda en çok nerede tahrik eder?",
            "İple bağlanmak mı, bağlamak mı daha çok hoşuna gider?",
            "İple en çok hangi fanteziyi gerçekleştirmek istersin?",
        ],
        "ha": [
            "{AO}, {HO}'nun bileklerini bağla, 4 dakika yönlendir.",
            "{AO}, {HO}'nun bacaklarını bağla, 3 dakika açık tut.",
            "{AO}, {HO}'nun boynuna ip dol, 4 dakika çek.",
            "{AO}, {HO}'nun gözlerini bağla, 3 dakika yönlendir.",
            "{AO}, {HO}'nun beline ip bağla, 4 dakika çek.",
        ],
        "fr": [
            "İp Kölesi: {AO}, {HO}'yu iple bağlar, 5 dakika her dediğini yaptırır.",
            "İp Oyunu: {AO}, {HO}'yu iple bağlar, 5 dakika oynar.",
            "İp İtaat: {HO} iple bağlanır, 5 dakika {AO}'ya itaat eder.",
            "İp Keşfi: {AO}, {HO}'yu iple bağlar, 5 dakika vücudunu keşfeder.",
            "İp Şehvet: {AO}, {HO}'yu iple bağlar, 5 dakika şehvetle okşar.",
        ],
    },
    {
        "slug": "goz_bandi",
        "prop_id": "hot_3",
        "title": "Göz bandı",
        "prop_category": "hotStimulating",
        "nhi": [
            "Ben hiç göz bandını birine takıp yönlendirmedim. (Yaptıysan: {HO}'nun gözlerini bağla, 3 dakika yönlendir.)",
            "Ben hiç göz bandı takılı birini okşayıp şaşırtmadım. (Yaptıysan: {HO}'nun gözlerini bağla, 3 dakika okşa, yer değiştir.)",
            "Ben hiç göz bandı takılı birini emzirip tahrik etmedim. (Yaptıysan: {HO}'nun gözlerini bağla, 3 dakika em.)",
            "Ben hiç göz bandı takılı birini yalarken ses çıkarmasını sağlamadım. (Yaptıysan: {HO}'nun gözlerini bağla, 3 dakika yala.)",
            "Ben hiç göz bandı takılı birini bekletip çıldırtmadım. (Yaptıysan: {HO}'nun gözlerini bağla, 3 dakika bekle.)",
        ],
        "ht": [
            "Göz bandı takıldığında en çok hangi duyun keskinleşir?",
            "Göz bandı takılıyken en çok ne yapılmasını istersin?",
            "Göz bandını birine takarken en çok ne hissedersin?",
            "Göz bandı takılıyken tahrik olmak mı, korkmak mı?",
            "Göz bandıyla en çok hangi fanteziyi gerçekleştirmek istersin?",
        ],
        "ha": [
            "{AO}, {HO}'nun gözlerini bağla, 4 dakika yönlendir.",
            "{AO}, {HO}'nun gözlerini bağla, 3 dakika okşa, yer değiştir.",
            "{AO}, {HO}'nun gözlerini bağla, 4 dakika em.",
            "{AO}, {HO}'nun gözlerini bağla, 3 dakika yala.",
            "{AO}, {HO}'nun gözlerini bağla, 4 dakika bekle.",
        ],
        "fr": [
            "Kör Oyun: {AO}, {HO}'nun gözlerini bağlar, 5 dakika yönlendirir.",
            "Kör İtaat: {HO}'nun gözleri bağlanır, 5 dakika {AO}'ya itaat eder.",
            "Kör Keşif: {AO}, {HO}'nun gözlerini bağlar, 5 dakika vücudunu keşfeder.",
            "Kör Şehvet: {AO}, {HO}'nun gözlerini bağlar, 5 dakika şehvetle okşar.",
            "Kör Sürpriz: {AO}, {HO}'nun gözlerini bağlar, 5 dakika sürprizler yapar.",
        ],
    },
    {
        "slug": "agiz_topu",
        "prop_id": "hot_4",
        "title": "Ağız topu",
        "prop_category": "hotStimulating",
        "nhi": [
            "Ben hiç ağız tıkacını birine takıp susturmadım. (Yaptıysan: {HO}'nun ağzına tıkacı tak, 3 dakika sustur.)",
            "Ben hiç ağız tıkacı takılı birini yalayıp inlemesini dinlemedim. (Yaptıysan: {HO}'nun ağzına tıkacı tak, 3 dakika yala.)",
            "Ben hiç ağız tıkacı takılı birini zorlayıp çırpınmasını izlemedim. (Yaptıysan: {HO}'nun ağzına tıkacı tak, 3 dakika zorla.)",
            "Ben hiç ağız tıkacı takılı birini emzirip sesini duymadım. (Yaptıysan: {HO}'nun ağzına tıkacı tak, 3 dakika em.)",
            "Ben hiç ağız tıkacını birinin ağzına tıkayıp göz teması kurmadım. (Yaptıysan: {HO}'nun ağzına tıkacı tak, 3 dakika gözlerinin içine bak.)",
        ],
        "ht": [
            "Ağız tıkacı takıldığında en çok hangi duygu ağır basar?",
            "Ağız tıkacı takılıyken en çok ne yapılmasını istersin?",
            "Ağız tıkacını birine takarken en çok ne hissedersin?",
            "Ağız tıkacı takılıyken konuşamamak mı, inleyememek mi?",
            "Ağız tıkacıyla en çok hangi fanteziyi gerçekleştirmek istersin?",
        ],
        "ha": [
            "{AO}, {HO}'nun ağzına tıkacı tak, 4 dakika sustur.",
            "{AO}, {HO}'nun ağzına tıkacı tak, 3 dakika yala.",
            "{AO}, {HO}'nun ağzına tıkacı tak, 4 dakika zorla.",
            "{AO}, {HO}'nun ağzına tıkacı tak, 3 dakika em.",
            "{AO}, {HO}'nun ağzına tıkacı tak, 4 dakika göz teması kur.",
        ],
        "fr": [
            "Sessiz Köle: {HO}'nun ağzına tıkacı takılır, 5 dakika {AO}'ya itaat eder.",
            "Sessiz İtaat: {HO}'nun ağzına tıkacı takılır, 5 dakika {AO}'nun her dediğini yapar.",
            "Sessiz Şehvet: {HO}'nun ağzına tıkacı takılır, 5 dakika {AO} şehvetle okşar.",
            "Sessiz Oyun: {HO}'nun ağzına tıkacı takılır, 5 dakika {AO} oynar.",
            "Sessiz Sorgu: {HO}'nun ağzına tıkacı takılır, 5 dakika {AO} sorar, {HO} başla cevap verir.",
        ],
    },
    {
        "slug": "tasma",
        "prop_id": "hot_5",
        "title": "Tasma",
        "prop_category": "hotStimulating",
        "nhi": [
            "Ben hiç tasmayı birinin boynuna takıp gezdirmedi. (Yaptıysan: {HO}'nun boynuna tasma tak, 3 dakika gezdir.)",
            "Ben hiç tasma takılı birini emzirip kontrol etmedim. (Yaptıysan: {HO}'nun boynuna tasma tak, 3 dakika em.)",
            "Ben hiç tasmayı birinin boynuna takıp çekmedim. (Yaptıysan: {HO}'nun boynuna tasma tak, 3 dakika çek.)",
            "Ben hiç tasma takılı birini diz çöktürüp yalvartmadım. (Yaptıysan: {HO}'nun boynuna tasma tak, diz çöktür, 3 dakika yalat.)",
            "Ben hiç tasmayı birinin boynuna takıp duvara yaslamadım. (Yaptıysan: {HO}'nun boynuna tasma tak, duvara yasla, 3 dakika zorla.)",
        ],
        "ht": [
            "Tasma takıldığında en çok hangi his ağır basar?",
            "Tasma takılıyken en çok ne yapılmasını istersin?",
            "Tasmayı birine takarken en çok ne hissedersin?",
            "Tasma takılıyken hayvanlaştırılmak mı, sahiplenilmek mi?",
            "Tasmayla en çok hangi fanteziyi gerçekleştirmek istersin?",
        ],
        "ha": [
            "{AO}, {HO}'nun boynuna tasma tak, 4 dakika gezdir.",
            "{AO}, {HO}'nun boynuna tasma tak, 3 dakika em.",
            "{AO}, {HO}'nun boynuna tasma tak, 4 dakika çek.",
            "{AO}, {HO}'nun boynuna tasma tak, diz çöktür, 3 dakika yalat.",
            "{AO}, {HO}'nun boynuna tasma tak, duvara yasla, 4 dakika zorla.",
        ],
        "fr": [
            "Köle Tasma: {HO}'nun boynuna tasma takılır, 5 dakika {AO}'nun kölesi olur.",
            "Tasma İtaat: {HO}'nun boynuna tasma takılır, 5 dakika {AO}'ya itaat eder.",
            "Tasma Gezdirme: {AO}, {HO}'yu tasmayla 5 dakika gezdirir.",
            "Tasma Şehvet: {HO}'nun boynuna tasma takılır, 5 dakika {AO} şehvetle okşar.",
            "Tasma Oyunu: {HO}'nun boynuna tasma takılır, 5 dakika {AO} oynar.",
        ],
    },
    {
        "slug": "kirbac",
        "prop_id": "hot_8",
        "title": "Kırbaç",
        "prop_category": "hotStimulating",
        "nhi": [
            "Ben hiç kırbacı birinin kalçasında kullanmadım. (Yaptıysan: {HO}'nun kalçasına 3 dakika kırbaçla vur.)",
            "Ben hiç kırbacı birinin sırtında kullanmadım. (Yaptıysan: {HO}'nun sırtına 3 dakika kırbaçla vur.)",
            "Ben hiç kırbacı birinin bacaklarında kullanmadım. (Yaptıysan: {HO}'nun bacaklarına 3 dakika kırbaçla vur.)",
            "Ben hiç kırbacı birinin göğsünde kullanmadım. (Yaptıysan: {HO}'nun göğsüne 3 dakika kırbaçla vur.)",
            "Ben hiç kırbacı birinin yüzünde kullanmadım. (Yaptıysan: {HO}'nun yüzüne 3 dakika kırbaçla vur.)",
        ],
        "ht": [
            "Kırbaç darbesi vücudunda en çok nerede tahrik eder?",
            "Kırbaçlanmak mı, kırbaçlamak mı daha çok hoşuna gider?",
            "Kırbacı birine vururken en çok ne hissedersin?",
            "Kırbaç sesi duyduğunda vücudunda ne hissediyorsun?",
            "Kırbaçla en çok hangi fanteziyi gerçekleştirmek istersin?",
        ],
        "ha": [
            "{AO}, {HO}'nun kalçasına 4 dakika kırbaçla vur.",
            "{AO}, {HO}'nun sırtına 3 dakika kırbaçla vur.",
            "{AO}, {HO}'nun bacaklarına 4 dakika kırbaçla vur.",
            "{AO}, {HO}'nun göğsüne 3 dakika kırbaçla vur.",
            "{AO}, {HO}'nun yüzüne 4 dakika kırbaçla vur.",
        ],
        "fr": [
            "Kırbaç Kölesi: {AO}, {HO}'yu 5 dakika kırbaçlar, {HO} itaat eder.",
            "Kırbaç Oyunu: {AO}, {HO}'yu 5 dakika kırbaçlar, {HO} inler.",
            "Kırbaç İtaat: {HO}, 5 dakika {AO}'nun kırbacına itaat eder.",
            "Kırbaç Şehvet: {AO}, {HO}'yu 5 dakika kırbaçlar, şehvetle okşar.",
            "Kırbaç Sorgu: {AO}, {HO}'yu 5 dakika kırbaçlarken sorular sorar.",
        ],
    },
    {
        "slug": "vibrator",
        "prop_id": "hot_21",
        "title": "Vibratör",
        "prop_category": "hotStimulating",
        "nhi": [
            "Ben hiç vibratörü birinin vücudunda gezdirip tahrik etmedim. (Yaptıysan: {HO}'nun vücudunda 3 dakika vibratör gezdir.)",
            "Ben hiç vibratörü birinin meme ucunda kullanmadım. (Yaptıysan: {HO}'nun meme ucunda 3 dakika vibratör kullan.)",
            "Ben hiç vibratörü birinin bacak arasında kullanmadım. (Yaptıysan: {HO}'nun bacak arasında 3 dakika vibratör kullan.)",
            "Ben hiç vibratörü birinin ağzına verip ses çıkarmasını sağlamadım. (Yaptıysan: {HO}'nun ağzına vibratör ver, 3 dakika ses çıkarsın.)",
            "Ben hiç vibratörü birinin boynunda kullanıp ürpertmedi. (Yaptıysan: {HO}'nun boynunda 3 dakika vibratör kullan.)",
        ],
        "ht": [
            "Vibratör vücudunda en çok nerede tahrik eder?",
            "Vibratörü birine karşı kullanırken en çok neresine odaklanırsın?",
            "Vibratörün sesi mi, titreşimi mi seni daha çok etkiler?",
            "Vibratörle en çok hangi fanteziyi gerçekleştirmek istersin?",
            "Vibratörü birine kullanırken en çok ne düşünürsün?",
        ],
        "ha": [
            "{AO}, {HO}'nun vücudunda 4 dakika vibratör gezdir.",
            "{AO}, {HO}'nun meme ucunda 3 dakika vibratör kullan.",
            "{AO}, {HO}'nun bacak arasında 4 dakika vibratör kullan.",
            "{AO}, {HO}'nun ağzına vibratör ver, 3 dakika ses çıkarsın.",
            "{AO}, {HO}'nun boynunda 4 dakika vibratör kullan.",
        ],
        "fr": [
            "Vibratör Oyunu: {AO}, {HO}'yu 5 dakika vibratörle oynar.",
            "Vibratör İtaat: {HO}, 5 dakika {AO}'nun vibratörüne itaat eder.",
            "Vibratör Şehvet: {AO}, {HO}'yu 5 dakika vibratörle tahrik eder.",
            "Vibratör Keşfi: {AO}, {HO}'nun vücudunu 5 dakika vibratörle keşfeder.",
            "Vibratör Sorgu: {AO}, {HO}'yu 5 dakika vibratörle sorgular.",
        ],
    },
    {
        "slug": "dildo",
        "prop_id": "hot_22",
        "title": "Dildo",
        "prop_category": "hotStimulating",
        "nhi": [
            "Ben hiç dildoyu birinin ağzına verip emmesini sağlamadım. (Yaptıysan: {HO}'nun ağzına dildo ver, 3 dakika em.)",
            "Ben hiç dildoyu birinin bacak arasında kullanmadım. (Yaptıysan: {HO}'nun bacak arasında 3 dakika dildo kullan.)",
            "Ben hiç dildoyu birinin kalçasında kullanmadım. (Yaptıysan: {HO}'nun kalçasında 3 dakika dildo kullan.)",
            "Ben hiç dildoyu birinin ağzına tıkayıp susturmadım. (Yaptıysan: {HO}'nun ağzına dildo tık, 3 dakika sustur.)",
            "Ben hiç dildoyu birinin vücudunda gezdirip tahrik etmedim. (Yaptıysan: {HO}'nun vücudunda 3 dakika dildo gezdir.)",
        ],
        "ht": [
            "Dildo vücudunda en çok nerede tahrik eder?",
            "Dildoyu birine karşı kullanırken en çok neresine odaklanırsın?",
            "Dildonun şekli mi, boyutu mu seni daha çok etkiler?",
            "Dildoyla en çok hangi fanteziyi gerçekleştirmek istersin?",
            "Dildoyu birine kullanırken en çok ne düşünürsün?",
        ],
        "ha": [
            "{AO}, {HO}'nun ağzına dildo ver, 4 dakika em.",
            "{AO}, {HO}'nun bacak arasında 3 dakika dildo kullan.",
            "{AO}, {HO}'nun kalçasında 4 dakika dildo kullan.",
            "{AO}, {HO}'nun ağzına dildo tık, 3 dakika sustur.",
            "{AO}, {HO}'nun vücudunda 4 dakika dildo gezdir.",
        ],
        "fr": [
            "Dildo Oyunu: {AO}, {HO}'yu 5 dakika dildoyla oynar.",
            "Dildo İtaat: {HO}, 5 dakika {AO}'nun dildosuna itaat eder.",
            "Dildo Şehvet: {AO}, {HO}'yu 5 dakika dildoyla tahrik eder.",
            "Dildo Keşfi: {AO}, {HO}'nun vücudunu 5 dakika dildoyla keşfeder.",
            "Dildo Sorgu: {AO}, {HO}'yu 5 dakika dildoyla sorgular.",
        ],
    },
    {
        "slug": "strap_on",
        "prop_id": "hot_23",
        "title": "Strap-on",
        "prop_category": "hotStimulating",
        "nhi": [
            "Ben hiç strap-on'ı birine takıp kullanmadım. (Yaptıysan: {HO}'ya strap-on tak, 3 dakika kullan.)",
            "Ben hiç strap-on takılı birini emzirip kontrol etmedim. (Yaptıysan: {HO}'ya strap-on tak, 3 dakika em.)",
            "Ben hiç strap-on'ı birine takıp arkadan zorlamadım. (Yaptıysan: {HO}'ya strap-on tak, 3 dakika arkadan zorla.)",
            "Ben hiç strap-on takılı birini yalayıp tahrik etmedim. (Yaptıysan: {HO}'ya strap-on tak, 3 dakika yala.)",
            "Ben hiç strap-on'ı birine takıp üstüne çıkmadım. (Yaptıysan: {HO}'ya strap-on tak, 3 dakika üstüne çık.)",
        ],
        "ht": [
            "Strap-on takıldığında en çok hangi his ağır basar?",
            "Strap-on takılıyken en çok ne yapılmasını istersin?",
            "Strap-on'ı birine takarken en çok ne hissedersin?",
            "Strap-on takılıyken penetre etmek mi, edilmek mi?",
            "Strap-on'la en çok hangi fanteziyi gerçekleştirmek istersin?",
        ],
        "ha": [
            "{AO}, {HO}'ya strap-on tak, 4 dakika kullan.",
            "{AO}, {HO}'ya strap-on tak, 3 dakika em.",
            "{AO}, {HO}'ya strap-on tak, 4 dakika arkadan zorla.",
            "{AO}, {HO}'ya strap-on tak, 3 dakika yala.",
            "{AO}, {HO}'ya strap-on tak, 4 dakika üstüne çık.",
        ],
        "fr": [
            "Strap-on Kölesi: {HO}'ya strap-on takılır, 5 dakika {AO}'nun kölesi olur.",
            "Strap-on İtaat: {HO}'ya strap-on takılır, 5 dakika {AO}'ya itaat eder.",
            "Strap-on Şehvet: {HO}'ya strap-on takılır, 5 dakika {AO} şehvetle okşar.",
            "Strap-on Oyunu: {HO}'ya strap-on takılır, 5 dakika {AO} oynar.",
            "Strap-on Sorgu: {HO}'ya strap-on takılır, 5 dakika {AO} sorgular.",
        ],
    },
    {
        "slug": "krem_santi",
        "prop_id": "ed_0",
        "title": "Krem şanti",
        "prop_category": "edibleReachable",
        "nhi": [
            "Ben hiç krem şantiyi birinin vücuduna sıkıp yalamadım. (Yaptıysan: {HO}'nun vücuduna krem şanti sık, 3 dakika yala.)",
            "Ben hiç krem şantiyi birinin meme ucuna sıkıp emmedim. (Yaptıysan: {HO}'nun meme ucuna krem şanti sık, 3 dakika em.)",
            "Ben hiç krem şantiyi birinin bacak arasına sıkıp yalamadım. (Yaptıysan: {HO}'nun bacak arasına krem şanti sık, 3 dakika yala.)",
            "Ben hiç krem şantiyi birinin ağzına sıkıp öpmedim. (Yaptıysan: {HO}'nun ağzına krem şanti sık, 3 dakika öp.)",
            "Ben hiç krem şantiyi birinin boynuna sıkıp yalayıp ürpertmedi. (Yaptıysan: {HO}'nun boynuna krem şanti sık, 3 dakika yala.)",
        ],
        "ht": [
            "Krem şanti vücudunda en çok nerede tahrik eder?",
            "Krem şantiyi birine karşı kullanırken en çok neresine odaklanırsın?",
            "Krem şantinin tadı mı, dokusu mu seni daha çok etkiler?",
            "Krem şantiyle en çok hangi fanteziyi gerçekleştirmek istersin?",
            "Krem şantiyi birine kullanırken en çok ne düşünürsün?",
        ],
        "ha": [
            "{AO}, {HO}'nun vücuduna krem şanti sık, 4 dakika yala.",
            "{AO}, {HO}'nun meme ucuna krem şanti sık, 3 dakika em.",
            "{AO}, {HO}'nun bacak arasına krem şanti sık, 4 dakika yala.",
            "{AO}, {HO}'nun ağzına krem şanti sık, 3 dakika öp.",
            "{AO}, {HO}'nun boynuna krem şanti sık, 4 dakika yala.",
        ],
        "fr": [
            "Krem Şanti Oyunu: {AO}, {HO}'nun vücuduna krem şanti sıkar, 5 dakika yalar.",
            "Krem Şanti İtaat: {HO}, 5 dakika {AO}'nun krem şantisine itaat eder.",
            "Krem Şanti Şehvet: {AO}, {HO}'yu 5 dakika krem şantiyle tahrik eder.",
            "Krem Şanti Keşfi: {AO}, {HO}'nun vücudunu 5 dakika krem şantiyle keşfeder.",
            "Krem Şanti Sorgu: {AO}, {HO}'yu 5 dakika krem şantiyle sorgular.",
        ],
    },
    {
        "slug": "cikolata_sosu",
        "prop_id": "ed_6",
        "title": "Çikolata sosu",
        "prop_category": "edibleReachable",
        "nhi": [
            "Ben hiç çikolata sosunu birinin vücuduna döküp yalamadım. (Yaptıysan: {HO}'nun vücuduna çikolata sosu dök, 3 dakika yala.)",
            "Ben hiç çikolata sosunu birinin meme ucuna döküp emmedim. (Yaptıysan: {HO}'nun meme ucuna çikolata sosu dök, 3 dakika em.)",
            "Ben hiç çikolata sosunu birinin bacak arasına döküp yalamadım. (Yaptıysan: {HO}'nun bacak arasına çikolata sosu dök, 3 dakika yala.)",
            "Ben hiç çikolata sosunu birinin ağzına döküp öpmedim. (Yaptıysan: {HO}'nun ağzına çikolata sosu dök, 3 dakika öp.)",
            "Ben hiç çikolata sosunu birinin boynuna döküp yalayıp ürpertmedi. (Yaptıysan: {HO}'nun boynuna çikolata sosu dök, 3 dakika yala.)",
        ],
        "ht": [
            "Çikolata sosu vücudunda en çok nerede tahrik eder?",
            "Çikolata sosunu birine karşı kullanırken en çok neresine odaklanırsın?",
            "Çikolata sosunun tadı mı, dokusu mu seni daha çok etkiler?",
            "Çikolata sosuyla en çok hangi fanteziyi gerçekleştirmek istersin?",
            "Çikolata sosunu birine kullanırken en çok ne düşünürsün?",
        ],
        "ha": [
            "{AO}, {HO}'nun vücuduna çikolata sosu dök, 4 dakika yala.",
            "{AO}, {HO}'nun meme ucuna çikolata sosu dök, 3 dakika em.",
            "{AO}, {HO}'nun bacak arasına çikolata sosu dök, 4 dakika yala.",
            "{AO}, {HO}'nun ağzına çikolata sosu dök, 3 dakika öp.",
            "{AO}, {HO}'nun boynuna çikolata sosu dök, 4 dakika yala.",
        ],
        "fr": [
            "Çikolata Oyunu: {AO}, {HO}'nun vücuduna çikolata sosu döker, 5 dakika yalar.",
            "Çikolata İtaat: {HO}, 5 dakika {AO}'nun çikolata sosuna itaat eder.",
            "Çikolata Şehvet: {AO}, {HO}'yu 5 dakika çikolata sosuyla tahrik eder.",
            "Çikolata Keşfi: {AO}, {HO}'nun vücudunu 5 dakika çikolata sosuyla keşfeder.",
            "Çikolata Sorgu: {AO}, {HO}'yu 5 dakika çikolata sosuyla sorgular.",
        ],
    },
    {
        "slug": "bal",
        "prop_id": "ed_1",
        "title": "Bal",
        "prop_category": "edibleReachable",
        "nhi": [
            "Ben hiç balı birinin vücuduna sürüp yalamadım. (Yaptıysan: {HO}'nun vücuduna bal sür, 3 dakika yala.)",
            "Ben hiç balı birinin meme ucuna sürüp emmedim. (Yaptıysan: {HO}'nun meme ucuna bal sür, 3 dakika em.)",
            "Ben hiç balı birinin bacak arasına sürüp yalamadım. (Yaptıysan: {HO}'nun bacak arasına bal sür, 3 dakika yala.)",
            "Ben hiç balı birinin ağzına sürüp öpmedim. (Yaptıysan: {HO}'nun ağzına bal sür, 3 dakika öp.)",
            "Ben hiç balı birinin boynuna sürüp yalayıp ürpertmedi. (Yaptıysan: {HO}'nun boynuna bal sür, 3 dakika yala.)",
        ],
        "ht": [
            "Bal vücudunda en çok nerede tahrik eder?",
            "Balı birine karşı kullanırken en çok neresine odaklanırsın?",
            "Balın tadı mı, kıvamı mı seni daha çok etkiler?",
            "Bal ile en çok hangi fanteziyi gerçekleştirmek istersin?",
            "Balı birine kullanırken en çok ne düşünürsün?",
        ],
        "ha": [
            "{AO}, {HO}'nun vücuduna bal sür, 4 dakika yala.",
            "{AO}, {HO}'nun meme ucuna bal sür, 3 dakika em.",
            "{AO}, {HO}'nun bacak arasına bal sür, 4 dakika yala.",
            "{AO}, {HO}'nun ağzına bal sür, 3 dakika öp.",
            "{AO}, {HO}'nun boynuna bal sür, 4 dakika yala.",
        ],
        "fr": [
            "Bal Oyunu: {AO}, {HO}'nun vücuduna bal sürer, 5 dakika yalar.",
            "Bal İtaat: {HO}, 5 dakika {AO}'nun balına itaat eder.",
            "Bal Şehvet: {AO}, {HO}'yu 5 dakika bal ile tahrik eder.",
            "Bal Keşfi: {AO}, {HO}'nun vücudunu 5 dakika bal ile keşfeder.",
            "Bal Sorgu: {AO}, {HO}'yu 5 dakika bal ile sorgular.",
        ],
    },
    {
        "slug": "buz",
        "prop_id": "ed_5",
        "title": "Buz",
        "prop_category": "edibleReachable",
        "nhi": [
            "Ben hiç buzu birinin vücudunda gezdirip ürpertmedi. (Yaptıysan: {HO}'nun vücudunda 3 dakika buz gezdir.)",
            "Ben hiç buzu birinin meme ucunda kullanıp dikleştirmedi. (Yaptıysan: {HO}'nun meme ucunda 3 dakika buz kullan.)",
            "Ben hiç buzu birinin bacak arasında kullanıp tahrik etmedim. (Yaptıysan: {HO}'nun bacak arasında 3 dakika buz kullan.)",
            "Ben hiç buzu birinin ağzına verip emmesini sağlamadım. (Yaptıysan: {HO}'nun ağzına buz ver, 3 dakika em.)",
            "Ben hiç buzu birinin boynunda kullanıp ürpertmedi. (Yaptıysan: {HO}'nun boynunda 3 dakika buz kullan.)",
        ],
        "ht": [
            "Buz vücudunda en çok nerede tahrik eder?",
            "Buzu birine karşı kullanırken en çok neresine odaklanırsın?",
            "Buzun soğuğu mu, erimesi mi seni daha çok etkiler?",
            "Buz ile en çok hangi fanteziyi gerçekleştirmek istersin?",
            "Buzu birine kullanırken en çok ne düşünürsün?",
        ],
        "ha": [
            "{AO}, {HO}'nun vücudunda 4 dakika buz gezdir.",
            "{AO}, {HO}'nun meme ucunda 3 dakika buz kullan.",
            "{AO}, {HO}'nun bacak arasında 4 dakika buz kullan.",
            "{AO}, {HO}'nun ağzına buz ver, 3 dakika em.",
            "{AO}, {HO}'nun boynunda 4 dakika buz kullan.",
        ],
        "fr": [
            "Buz Oyunu: {AO}, {HO}'yu 5 dakika buz ile oynar.",
            "Buz İtaat: {HO}, 5 dakika {AO}'nun buzuna itaat eder.",
            "Buz Şehvet: {AO}, {HO}'yu 5 dakika buz ile tahrik eder.",
            "Buz Keşfi: {AO}, {HO}'nun vücudunu 5 dakika buz ile keşfeder.",
            "Buz Sorgu: {AO}, {HO}'yu 5 dakika buz ile sorgular.",
        ],
    },
    {
        "slug": "kayganlastirici",
        "prop_id": "hot_15",
        "title": "Kayganlaştırıcı",
        "prop_category": "hotStimulating",
        "nhi": [
            "Ben hiç kayganlaştırıcıyı birinin vücuduna sürüp kaydırmadım. (Yaptıysan: {HO}'nun vücuduna kayganlaştırıcı sür, 3 dakika kaydır.)",
            "Ben hiç kayganlaştırıcıyı birinin bacak arasında kullanıp kolaylaştırmadım. (Yaptıysan: {HO}'nun bacak arasına kayganlaştırıcı sür, 3 dakika kullan.)",
            "Ben hiç kayganlaştırıcıyı birinin parmaklarında kullanıp içine sokmadım. (Yaptıysan: {HO}'nun parmaklarına kayganlaştırıcı sür, 3 dakika sok.)",
            "Ben hiç kayganlaştırıcıyı birinin göğsünde kullanıp kaydırmadım. (Yaptıysan: {HO}'nun göğsüne kayganlaştırıcı sür, 3 dakika kaydır.)",
            "Ben hiç kayganlaştırıcıyı birinin ağzına sürüp emmesini sağlamadım. (Yaptıysan: {HO}'nun ağzına kayganlaştırıcı sür, 3 dakika em.)",
        ],
        "ht": [
            "Kayganlaştırıcı vücudunda en çok nerede tahrik eder?",
            "Kayganlaştırıcıyı birine karşı kullanırken en çok neresine odaklanırsın?",
            "Kayganlaştırıcının kayganlığı mı, ısısı mı seni daha çok etkiler?",
            "Kayganlaştırıcıyla en çok hangi fanteziyi gerçekleştirmek istersin?",
            "Kayganlaştırıcıyı birine kullanırken en çok ne düşünürsün?",
        ],
        "ha": [
            "{AO}, {HO}'nun vücuduna kayganlaştırıcı sür, 4 dakika kaydır.",
            "{AO}, {HO}'nun bacak arasına kayganlaştırıcı sür, 3 dakika kullan.",
            "{AO}, {HO}'nun parmaklarına kayganlaştırıcı sür, 4 dakika sok.",
            "{AO}, {HO}'nun göğsüne kayganlaştırıcı sür, 3 dakika kaydır.",
            "{AO}, {HO}'nun ağzına kayganlaştırıcı sür, 4 dakika em.",
        ],
        "fr": [
            "Kayganlaştırıcı Oyunu: {AO}, {HO}'yu 5 dakika kayganlaştırıcı ile oynar.",
            "Kayganlaştırıcı İtaat: {HO}, 5 dakika {AO}'nun kayganlaştırıcısına itaat eder.",
            "Kayganlaştırıcı Şehvet: {AO}, {HO}'yu 5 dakika kayganlaştırıcı ile tahrik eder.",
            "Kayganlaştırıcı Keşfi: {AO}, {HO}'nun vücudunu 5 dakika kayganlaştırıcı ile keşfeder.",
            "Kayganlaştırıcı Sorgu: {AO}, {HO}'yu 5 dakika kayganlaştırıcı ile sorgular.",
        ],
    },
]

GENERAL_HT_QUESTIONS = [
    "En sevdiğin oyuncağı kiminle kullanmak istersin?",
    "Hangi oyuncakla en çılgın fantezini gerçekleştirmek istersin?",
    "Birine oyuncak kullanırken en çok ne düşünürsün?",
    "Oyuncak kullanılırken en çok hangi duygu ağır basar?",
    "Hangi oyuncak seni en çok tahrik eder?",
    "Birine oyuncakla en çok neresinde kullanmak istersin?",
    "Oyuncak sesi duyduğunda vücudunda ne hissediyorsun?",
    "Hangi oyuncakla en çok kontrol hissi yaşarsın?",
    "Birine oyuncak kullanırken en çok hangi tepkiyi almak istersin?",
    "Oyuncakla en çok hangi pozisyonda kullanmak istersin?",
    "Hangi oyuncak seni en çok zorlar?",
    "Birine oyuncak kullanırken en çok hangi sınırı zorlamak istersin?",
    "Oyuncakla en çok hangi fanteziyi gerçekleştirmek istersin?",
    "Hangi oyuncak seni en çok utandırır?",
    "Birine oyuncak kullanırken en çok hangi kelimeyi duymak istersin?",
    "Oyuncakla en çok hangi bölgeyi keşfetmek istersin?",
    "Hangi oyuncak seni en çok rahatlatır?",
    "Birine oyuncak kullanırken en çok hangi ritmi seversin?",
    "Oyuncakla en çok hangi rolü oynamak istersin?",
    "Hangi oyuncakla en çok bağlanmak istersin?",
]


def _extract_yes_task(text: str) -> Tuple[str, Optional[str]]:
    match = re.search(r"\(Yaptıysan:\s*(.*?)\)\s*$", text, flags=re.IGNORECASE)
    if not match:
        return text.strip(), None
    return text[: match.start()].strip(), match.group(1).strip()


def _build_card(
    *,
    card_id: str,
    deck_type: str,
    phase: str,
    card_type: str,
    text: str,
    duration_seconds: int,
    on_yes_task: Optional[str] = None,
    required_prop_ids: Optional[List[str]] = None,
    prop_category: Optional[str] = None,
    title: Optional[str] = None,
    content_tier: str = CONTENT_TIER,
    intensity: int = INTENSITY,
    min_players: int = MIN_PLAYERS,
    max_players: int = MAX_PLAYERS,
) -> Dict:
    strip_ao = card_type in ("task", "roleDuo")
    clean_text = normalize_field_text(text, strip_leading_actor=strip_ao)
    clean_yes = (
        normalize_field_text(on_yes_task, strip_leading_actor=False) if on_yes_task else None
    )

    payload: Dict = {
        "id": card_id,
        "deckType": deck_type,
        "contentTier": content_tier,
        "minPlayers": min_players,
        "maxPlayers": max_players,
        "phase": phase,
        "type": card_type,
        "text": clean_text,
        "durationSeconds": duration_seconds,
        "intensity": intensity,
    }
    if clean_yes:
        payload["onYesTask"] = clean_yes
    if required_prop_ids:
        payload["requiredPropIds"] = required_prop_ids
    if prop_category:
        payload["propCategory"] = prop_category
    if title:
        payload["title"] = title
    return payload


def _duration_for_section(section_key: str, raw_text: str, on_yes_task: Optional[str] = None) -> int:
    if section_key == "ht":
        return HT_DEFAULT_DURATION
    if section_key == "nhi":
        return duration_from_text(on_yes_task or "") or HT_DEFAULT_DURATION
    return duration_from_text(raw_text) or TASK_DEFAULT_DURATION


def _is_role_task(text: str) -> bool:
    lowered = text.strip().lower()
    return lowered.startswith("rol değişimi:") or lowered.startswith("tam ")


def _deck_for_task(text: str) -> Tuple[str, str, str]:
    if _is_role_task(text):
        return "fantasyRole", "roleDuo", "fr"
    return "hardAction", "timedTask", "ha"


STIM_SECTION_MAP = {
    "nhi_2": ("nhi", 2, 2),
    "nhi_3": ("nhi", 3, 3),
    "ht_2": ("ht", 2, 2),
    "ha_2": ("ha", 2, 2),
    "ha_3": ("ha", 3, 3),
    "fr_2": ("fr", 2, 2),
}


def build_stim_prop_cards() -> List[Dict]:
    if not STIM_CONTENT_PATH.exists():
        return []

    stim_data = json.loads(STIM_CONTENT_PATH.read_text(encoding="utf-8"))
    cards: List[Dict] = []

    for prop_id, section in stim_data.items():
        slug = section["slug"]
        title = section["title"]
        prop_category = section["prop_category"]

        for field_key, (deck_key, min_players, max_players) in STIM_SECTION_MAP.items():
            config = DECK_CONFIG[deck_key]
            for index, raw_text in enumerate(section[field_key], start=1):
                on_yes_task = None
                text = raw_text
                if deck_key == "nhi":
                    text, on_yes_task = _extract_yes_task(raw_text)

                duration = _duration_for_section(deck_key, raw_text, on_yes_task)
                player_tag = f"p{min_players}"
                card_id = f"{config['id_prefix']}_{slug}_{player_tag}_{index:03d}"

                cards.append(
                    _build_card(
                        card_id=card_id,
                        deck_type=config["deckType"],
                        phase=config["phase"],
                        card_type=config["type"],
                        text=text,
                        duration_seconds=duration,
                        on_yes_task=on_yes_task,
                        required_prop_ids=[prop_id],
                        prop_category=prop_category,
                        title=title,
                        content_tier="hot",
                        intensity=5,
                        min_players=min_players,
                        max_players=max_players,
                    )
                )

    return cards


def _load_tier_data() -> Dict:
    tier_data: Dict = {}
    for path in (TIER_CONTENT_PATH, TIER_CONTENT_BATCH2_PATH):
        if path.exists():
            tier_data.update(json.loads(path.read_text(encoding="utf-8")))
    return tier_data


def build_tier_prop_cards() -> List[Dict]:
    tier_data = _load_tier_data()
    if not tier_data:
        return []

    cards: List[Dict] = []

    for prop_id, section in tier_data.items():
        slug = section["slug"]
        title = section["title"]
        prop_category = section["prop_category"]

        for tier_name in ("beginning", "medium", "hot"):
            for index, raw_text in enumerate(section[tier_name], start=1):
                deck_type, phase, deck_key = _deck_for_task(raw_text)
                card_id = f"prop_{deck_key}_{slug}_{tier_name[:3]}_{index:03d}"
                duration = duration_from_text(raw_text) or {
                    "beginning": 60,
                    "medium": 120,
                    "hot": 300,
                }[tier_name]

                cards.append(
                    _build_card(
                        card_id=card_id,
                        deck_type=deck_type,
                        phase=phase,
                        card_type="roleDuo" if deck_key == "fr" else "task",
                        text=raw_text.strip(),
                        duration_seconds=duration,
                        required_prop_ids=[prop_id],
                        prop_category=prop_category,
                        title=title,
                        content_tier=tier_name,
                        intensity=TIER_INTENSITY[tier_name],
                        min_players=2,
                        max_players=2,
                    )
                )

    return cards


def build_prop_cards() -> List[Dict]:
    cards: List[Dict] = []
    cards.extend(build_tier_prop_cards())
    cards.extend(build_stim_prop_cards())

    tier_prop_ids = set(_load_tier_data().keys())

    for section in PROP_SECTIONS:
        if section["prop_id"] in tier_prop_ids:
            continue
        slug = section["slug"]
        prop_id = section["prop_id"]
        title = section["title"]
        prop_category = section["prop_category"]

        for section_key in ("nhi", "ht", "ha", "fr"):
            config = DECK_CONFIG[section_key]
            for index, raw_text in enumerate(section[section_key], start=1):
                card_id = f"{config['id_prefix']}_{slug}_{index:03d}"
                on_yes_task = None
                text = raw_text

                if section_key == "nhi":
                    text, on_yes_task = _extract_yes_task(raw_text)

                duration = _duration_for_section(section_key, raw_text, on_yes_task)
                cards.append(
                    _build_card(
                        card_id=card_id,
                        deck_type=config["deckType"],
                        phase=config["phase"],
                        card_type=config["type"],
                        text=text,
                        duration_seconds=duration,
                        on_yes_task=on_yes_task,
                        required_prop_ids=[prop_id],
                        prop_category=prop_category,
                        title=title,
                    )
                )

    for index, question in enumerate(GENERAL_HT_QUESTIONS, start=1):
        cards.append(
            _build_card(
                card_id=f"prop_gen_ht_{index:03d}",
                deck_type="hardTruth",
                phase="boldQuestion",
                card_type="question",
                text=question,
                duration_seconds=HT_DEFAULT_DURATION,
                title="Genel Eşya",
            )
        )

    return cards


def strip_legacy_prop_tasks() -> Tuple[int, int]:
    if not DECK_PACKS_PATH.exists():
        return 0, 0

    cards = json.loads(DECK_PACKS_PATH.read_text(encoding="utf-8"))
    before = len(cards)
    filtered = [
        card
        for card in cards
        if not (
            card.get("id", "").startswith("prop_hot_")
            or card.get("id", "").startswith("prop_ed_")
        )
    ]
    removed = before - len(filtered)
    if removed:
        DECK_PACKS_PATH.write_text(
            json.dumps(filtered, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
    return before, removed


def print_counts(cards: List[Dict]) -> None:
    by_deck: Dict[str, int] = {}
    by_prop: Dict[str, int] = {}
    general = 0

    for card in cards:
        deck = card["deckType"]
        by_deck[deck] = by_deck.get(deck, 0) + 1
        if card["id"].startswith("prop_gen_"):
            general += 1
        else:
            title = card.get("title", "unknown")
            by_prop[title] = by_prop.get(title, 0) + 1

    print(f"Total cards: {len(cards)}")
    print("By deckType:")
    for deck, count in sorted(by_deck.items()):
        print(f"  {deck}: {count}")
    print("By prop title:")
    for title, count in sorted(by_prop.items()):
        print(f"  {title}: {count}")
    print(f"General questions: {general}")


def main() -> None:
    cards = build_prop_cards()
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(json.dumps(cards, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {len(cards)} cards to {OUTPUT_PATH}")

    before, removed = strip_legacy_prop_tasks()
    if removed:
        print(f"Removed {removed} legacy prop task cards from deck_packs.json ({before} -> {before - removed})")
    else:
        print("No legacy prop_hot_/prop_ed_ cards found in deck_packs.json")

    print_counts(cards)


if __name__ == "__main__":
    main()
