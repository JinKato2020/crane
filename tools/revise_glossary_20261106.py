"""Apply the reviewed glossary without changing textbook sections or stable term IDs."""
from pathlib import Path
import copy, json, re
from glossary_copy_20261106 import INTRO, POINTS, EXAMPLES

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT.parent / 'tmp/glossary_revision_20261106'
RESOURCE = ROOT / 'CraneExam/Resources/textbook.json'
CANONICAL = ROOT.parent / 'アプリ/教材/textbook.json'

# Each illustration belongs to only one card per chapter. A comparison can have
# more than one illustration, but related words do not repeat the same picture.
FIGURES = {
 1: {
 0:'1-1_supplement_f01_20261023', 1:'1-2_lifting_load.svg',
 2:'1-2_radius_overload.svg',4:'1-2_supplement_f02_20261023.svg',
 6:'1-2_camber_concept21',8:'1-2_runway_rail_readable21',9:'1-3.svg',
 11:'1-4_supplement_f04_20261023',12:'1-4_supplement_f05_20261023',
 13:'1-4_supplement_f07_20261023',14:'1-4_crane_types_readable21',
 18:'1-4_supplement_f08_20261023',19:'1-4_supplement_f10_20261023',
 20:'1-5_overhead_parts.svg',21:'1-5_supplement_f09_20261023',
 22:'1-5_girder_sections_readable21',23:'1-5_rigid_pin_legs_readable21',
 24:'1-5_trolley_types_readable21',25:'1-6_hoist_system_readable21',
 29:'1-6_travel_drive_readable21',30:'1-6_slewing.svg',
 32:'1-9_two_stage_gear.svg',33:'1-9_gears.svg',34:'1-9_bearings_readable21',
 35:'1-9_supplement_f19_20261023',36:'1-9_bolts_readable21',
 37:'1-9_washers_locking.svg',38:'1-9_supplement_f17_20261023',
 39:'1-9_couplings.svg',40:'1-9_key.svg',42:'1-6_drum_equalizer.svg',
 44:'1-7_wire_structure_readable21',45:'1-7_supplement_f14_20261023',
 46:'1-7_supplement_f13_20261023',47:'1-7_rope_diameter.svg',
 48:'1-7_end_fittings.svg',51:'1-8_hook_latch.svg',
 52:'1-8_hook_slings_readable21',56:'1-8_supplement_f16_20261023',
 57:'1-10_supplement_f23_20261023',59:'1-12_wheel_stop.svg',
 60:'1-10_supplement_f26_20261023',61:'1-10_supplement_f25_20261023',
 62:'1-10_supplement_f27_20261023',66:'1-11_supplement_f28_20261023',
 67:'1-11_supplement_f30_20261023',
 },
 2: {0:'2-1_procedure_concept21',7:'2-1_clearance_elevation.svg|2-1_clearance_plan.svg',
 11:'2-2_overwind_gap.svg',15:'2-2_no_entry_patterns.svg|2-2_inner_angle_20261106.svg',
 20:'inspection_concept21',22:'2-3_storm_concept21',
 30:'2-6_safety_concept21',31:'2-6_wire_reject.svg',32:'2-6_chain_reject.svg',
 37:'2-8_slingqual_concept21'},
 3: {0:'3-1_water_quantities_daily',1:'3-1_wire_shapes_daily',
 4:'3-1_dc_ac_devices_daily',5:'3-1_rectify_smooth_20261106.svg',
 8:'3-1_frequency_schematic',9:'3-1_three_phase_schematic',
 11:'3-2_series_formula_steps|3-2_parallel_formula_steps',12:'3-2_mixed_concept',
 13:'3-2_power_energy_heater_daily',14:'3-2_joule_heat_daily',15:'3-3_motor_jobs_daily',
 16:'3-3_arago_rotor_daily',17:'3-2_rotor_compare_panel21_1|3-2_rotor_compare_panel21_2',
 19:'3-5_rotating_contact_daily',20:'3-3_supplement_f36_20261023',
 22:'3-4_indirect_door_daily',23:'3-4_contactor_motion_daily',24:'3-4_supplement_f38_20261023',
 25:'3-4_coasting_20261106.svg',27:'3-4_zero_handles_daily',
 30:'3-5_supplement_f41_20261023',31:'3-5_supplement_f42_20261023',
 32:'3-4_panel21_3',33:'3-6_supplement_f43_20261023.svg',34:'3-6_soft_start_daily',
 35:'3-5_star_delta.svg',36:'3-6_inverter_concept',37:'3-3_sync_fan_daily',
 38:'3-6_supplement_f40_20261023.svg',39:'3-6_supplement_f44_20261023',
 41:'3-6_supplement_f45_20261023.svg',42:'3-6_megger_panel21_1',
 43:'3-7_supplement_f46_20261023',44:'3-6_grounding_concept21',
 47:'3-7_meters_concept',48:'3-7_faults_concept'},
 4: {1:'4-0_earth_moon_schematic',3:'4-1_force_elements_door',
 5:'4-1_force_vector_clear',6:'4-1_action_concept21',8:'4-1_spanner_schematic',
 9:'4-1_beam_moments_example4',11:'4-2_volume_shapes_clear|4-2_pipe_volume_clear|4-2_sphere_cone_volume_clear',
 12:'4-2_scale_clear',14:'4-3_lifting_centroid_schematic',15:'4-3_centroid_clear',
 16:'4-3_stability_concept21',17:'4-4_speed_velocity_acceleration_trolley',
 18:'4-4_velocity_pythagoras',19:'3-6_soft_start_daily',20:'4-4_carousel_inertia',
 21:'4-4_friction_daily|4-4_friction_transition',22:'4-5_load_types_clear',
 23:'4-5_loadtime_concept21',24:'4-5_stress_concept21',25:'4-5_strain_concept21',
 26:'4-5_stress_curve_clear',28:'4-6_sling_support_easy',
 29:'4-6_tension_coefficient_ratio|4-6_mode_factor_easy',
 30:'2-6_safety_concept21',32:'4-7_fixed_moving_clear|4-7_compound_clear|4-7_cascade_clear',
 33:'4-7_work_clear'},
}

CATEGORIES = {
 '1-0':'クレーンの基本','1-1':'クレーンの基本','1-2':'荷重・寸法・基本用語','1-3':'クレーンの動き',
 '1-4':'クレーンの種類','1-5':'骨組みとトロリ','1-6':'作動装置','1-9':'歯車・軸・接合部品',
 '1-13':'ドラム・シーブ','1-7':'ワイヤロープ','1-8':'つり具','1-10':'安全装置','1-11':'ブレーキ',
 '1-14':'安全運転','1-12':'給油・点検',
 '2-0':'法令の読み方','2-1':'製造・設置・検査証','2-2':'使用時のルール',
 '2-3':'検査・点検','2-4':'更新・変更・廃止','2-5':'玉掛用具の基準','2-6':'免許・資格',
 '3-0':'電気の基本','3-1':'電気の基本','3-2':'回路と電力の計算','3-3':'モーターのしくみ',
 '3-4':'制御器・保護機器','3-5':'動く機械への給電','3-6':'始動・速度制御','3-7':'保守・感電対策',
 '4-0':'質量と力の単位','4-1':'力とモーメント','4-2':'質量・体積・密度','4-3':'重心と安定',
 '4-4':'運動と摩擦','4-5':'荷重・応力・ひずみ','4-6':'張力と玉掛け','4-7':'滑車・仕事・動力',
}

# Searchable names, without changing the legacy favorite ID.
ALIASES = {(1,42):['捨巻き','捨て巻き','すてまき'],(1,46):['普通撚り','ラング撚り'],
 (2,33):['チェーンの安全係数','引張強さ','伸び'],
 (3,17):['誘導電動機のしくみ','かご型','かごがた','巻線型','まきせんがた','籠形','すべり','すべり率'],
 (3,29):['サイリスタ'],(3,31):['キャプタイヤ'],(3,36):['インバータ','可変電圧可変周波数'],
 (3,42):['漏洩電流','漏電','メガー','絶縁抵抗計'],(4,8):['腕の長さ','スパナ'],
 (4,18):['ピタゴラス','三平方'],(4,20):['回転ブランコ'],(4,21):['動摩擦','最大静止摩擦'],
 (4,32):['階段式滑車','段階式滑車','組合せ滑車','定滑車','動滑車']}

ADDITIONS = {
 1:[
 ('荷振れ','にぶれ','1-14','**動かすクレーンと荷の動きがずれて、荷が揺れること**。荷の慣性が関わります。',
  '**発進時：** 荷が元の位置に残ろうとする。\n**停止時：** 荷が進み続けようとする。\n急な操作を避け、荷の動きを見ながら操作する。操作の例は教材で確認する。','1-12_sway_concept21'),
 ('給油・給脂','きゅうゆ・きゅうし','1-12','**動く部品の間へ潤滑剤を届け、摩擦や摩耗を減らすこと**。油やグリースを使います。',
  '**油：** 流れやすく、循環やはね上げで届けられる。\n**グリース：** 半固体の潤滑剤。給脂口からグリースガンなどで送る。\n量や周期は、部位と指定の方法で確認する。','1-12_lubrication_readable21'),
 ('油浴潤滑','ゆよくじゅんかつ','1-12','**歯車の一部を油につけ、回転ではね上げて潤滑する方法**。油を多く入れればよい、というものではありません。',
  '減速機などで使われる。\n油はかみ合い部や軸受へ届き、摩擦・摩耗を減らす。\n指定の油面を保ち、油漏れや汚れを点検する。','1-12_oil_bath_20261106'),
 ],
 2:[
 ('以上・超える・以下・未満','いじょう・こえる・いか・みまん','2-0','**境目の数値を含むかどうか**が違います。法令の数字は、言葉と組にして覚えます。',
  '**以上・以下：** その数値ちょうどを含む。\n**超える・未満：** その数値ちょうどを含まない。\n断線10％以上は10％ちょうどで使用禁止。直径減少7％超は7％ちょうどを含まない。',''),
 ('つり具・玉掛用具','つりぐ・たまがけようぐ','2-0','**機械側で荷をつる部分と、荷を掛けるために使う用具**。どの用具にどの基準がかかるかを読み分けます。',
  '**つり具：** フック、グラブバケットなど、クレーンが荷をつり上げるための装置。\n**玉掛用具：** 玉掛け用ワイヤロープ、つりチェーン、フック、シャックルなど。\n同じ名前でも用途を確認する。玉掛けのワイヤロープは安全係数6以上。','2-5_supplement_f34_20261023'),
 ],
 3:[
 ('入力・出力・効率','にゅうりょく・しゅつりょく・こうりつ','3-3','**受け取る電力が入力、軸から取り出す動力が出力**。使える仕事になる割合が効率です。',
  '**効率＝出力÷入力。** ％で表すときは100を掛ける。\n**入力＝出力÷効率。** 効率75％なら0.75を使う。\n入力8kW・出力6kWなら、効率は6÷8＝75％。残り2kWは熱などの損失。','3-3_motor_efficiency_20261106.svg'),
 ],
 4:[
 ('偶力','ぐうりょく','4-1','**同じ大きさ・反対向きの2つの力で、物を回す組合せ**。2本の作用線は平行で、離れています。',
  'ハンドルを両手で逆向きに押すと、2つの力が同じ向きに回す働きをする。\n**偶力のモーメント＝片方の力×2本の作用線の間の垂直距離。**\n力の合計が0でも、回す働きは残る。','4-1_couple_20261106.svg'),
 ('集中荷重・分布荷重','しゅうちゅうかじゅう・ぶんぷかじゅう','4-5','**力がどの範囲にかかるか**による分類。狭い所へまとまるか、広い範囲に広がるかを見ます。',
  '**集中荷重：** 狭い範囲にかかり、1点の力として扱う。例はトロリの車輪がレールへ及ぼす力。\n**分布荷重：** 長さや面にわたって広くかかる。例はガーダ自重。\n静荷重・動荷重は「時間による変わり方」の分類で、これとは別。','4-5_distribution_concept21'),
 ('効率と必要動力','こうりつとひつようどうりょく','4-7','**荷を動かす仕事に使われる割合**が効率。摩擦などの損失があるため、入力には余分な動力が必要です。',
  '**必要な入力動力＝荷を動かす動力÷効率。**\n効率75％なら0.75で割る。荷を動かす動力が6kWなら、入力は6÷0.75＝8kW。\n滑車で力を小さくしても、その分長く引く。摩擦があれば入力の仕事は増える。','4-7_efficiency_20261106.svg'),
 ]}

def plain(text):
    return text.replace('**','')

def split_points(text):
    # Keep units, decimal numbers, brackets and formulas intact.
    parts = [s.strip() for s in re.split(r'\n+|(?<=。)', text) if s.strip()]
    # Numbers and their boundary words must stand out together (e.g. 10％以上).
    pattern = r'\d+(?:\.\d+)?(?:〜\d+(?:\.\d+)?)?(?:％|%|m/s|N・m|N/mm²|MPa|kN|mm|cm|kg|t|m|倍|年|か月|月|日|巻|本|歳)(?:以上|以下|未満|以内|超)?'
    return [re.sub(pattern, lambda m:'**'+m.group(0)+'**',s) for s in parts]

def block_text(block):
    return '\n'.join([block.get('text',''),block.get('caption','')] + block.get('items',[]) +
                     block.get('headers',[]) + [s for row in block.get('rows',[]) for s in row])

def best_reference(section, term):
    words = [w for w in re.split(r'[／・（）()、]',term['term']) if len(w)>1]
    candidates = []
    for i,b in enumerate(section['blocks']):
        if not b.get('id'): continue
        txt = plain(block_text(b))
        score = sum(len(w)*2 for w in words if w in txt)
        if b['type']=='sub': score *= 1.35
        if score: candidates.append((score,-i,b))
    chosen = max(candidates,key=lambda x:(x[0],x[1]))[2] if candidates else next(b for b in section['blocks'] if b.get('id'))
    label = chosen.get('text','') if chosen['type']=='sub' else term.get('displayTerm',term['term'])
    return {'section':section['id'],'blockID':chosen['id'],'label':plain(label)}

def main():
    baseline = json.loads((WORK/'textbook.json').read_text(encoding='utf-8'))
    book = json.loads(RESOURCE.read_text(encoding='utf-8'))
    sections = {s['id']:s for c in book['chapters'] for s in c['sections']}
    images = {}
    for c in book['chapters']:
        for s in c['sections']:
            for b in s['blocks']:
                if b['type'] in ('img','svg'):
                    name = b.get('asset') or b.get('file')
                    images.setdefault(name, {'file':name if name.endswith('.svg') else name+'.png', 'caption':b.get('caption','')})
    report = []
    images['3-5_star_delta.svg']['caption']='Yでは巻線の一端を共通点へ、Δでは3つの巻線を三角形につなぐ。電源電流と始動トルクの1/3は、Δで直接始動する場合との比較。'
    for c,old in zip(book['chapters'],baseline['chapters']):
        cid=c['id']; terms=copy.deepcopy(old['glossary'])
        intro = [row.split('|',3) for row in INTRO[cid].strip().splitlines()]
        assert len(terms)==len(intro)
        for index,section,reading,summary in intro:
            i=int(index); t=terms[i]
            points=POINTS.get((cid,i))
            t.update(summary=summary,reading=reading,category=CATEGORIES[section],
                     points=points.split('\n') if points else split_points(t['def']))
            if (cid,i) in EXAMPLES: t['example']=EXAMPLES[cid,i]
            if (cid,i) in ALIASES: t['aliases']=ALIASES[cid,i]
            if (cid,i)==(3,17): t['displayTerm']='誘導電動機のしくみ'
            t['references']=[best_reference(sections[section],t)]
            t.pop('img',None)
            assets=FIGURES[cid].get(i,'')
            if assets: t['figures']=[copy.deepcopy(images[x]) for x in assets.split('|')]
        for name,reading,section,summary,points,assets in ADDITIONS[cid]:
            t={'term':name,'summary':summary,'reading':reading,'category':CATEGORIES[section],'points':points.split('\n')}
            t['references']=[best_reference(sections[section],t)]
            if assets:t['figures']=[copy.deepcopy(images[x]) for x in assets.split('|')]
            terms.append(t)
        for i,t in enumerate(terms):
            if (cid,i)==(2,33):
                t['points']=[p for p in t['points'] if not p.startswith('引張強さ400')]
                t['comparison']={'title':'引張強さに対応する、伸びの条件',
                  'headers':['引張強さ\n〔N/mm²〕','伸び'],
                  'rows':[['400以上\n630未満','20％以上'],['630以上\n1,000未満','17％以上'],['1,000以上','15％以上']]}
            # Original terms and order stay unchanged. Legacy apps still receive a readable definition.
            sentences=[t['summary']]+t['points']+(['例：'+t['example']] if t.get('example') else [])
            if t.get('comparison'):
                comp=t['comparison']
                sentences += [comp['title']+'（引張強さの単位：N/mm²）']+[' → '.join(cell.replace('\n','・') for cell in row) for row in comp['rows']]
            t['def']='\n\n'.join(dict.fromkeys(plain(s) for s in sentences))
            png=next((f['file'] for f in t.get('figures',[]) if f['file'].endswith('.png')),None)
            if png:t['img']=png[:-4]
            ref=t['references'][0]; s=sections[ref['section']]
            b=next(b for b in s['blocks'] if b['id']==ref['blockID'])
            report.append({'chapter':cid,'index':i,'term':t['term'],'reference':ref,
                           'target':plain(block_text(b)),'figures':[f['file'] for f in t.get('figures',[])]})
        c['glossary']=terms
        assert c['sections']==old['sections']
        assert [x['term'] for x in terms[:len(old['glossary'])]]==[x['term'] for x in old['glossary']]
    # Curated anchor overrides are reviewed separately from content prose.
    overrides_path=ROOT/'tools/glossary_reference_overrides_20261106.json'
    if overrides_path.exists():
        overrides=json.loads(overrides_path.read_text(encoding='utf-8'))
        for c in book['chapters']:
            for i,t in enumerate(c['glossary']):
                key=f"{c['id']}:{i}"
                if key in overrides:
                    t['references']=overrides[key]
                    for row in report:
                        if row['chapter']==c['id'] and row['index']==i:
                            row['reference']=t['references']; row['target']=[plain(block_text(next(b for b in sections[r['section']]['blocks'] if b['id']==r['blockID']))) for r in t['references']]
    text=json.dumps(book,ensure_ascii=False,indent=2)+'\n'
    RESOURCE.write_text(text,encoding='utf-8',newline='\n')
    canonical=json.loads(CANONICAL.read_text(encoding='utf-8'))
    for c in canonical['chapters']:
        c['glossary']=next(x['glossary'] for x in book['chapters'] if x['id']==c['id'])
    CANONICAL.write_text(json.dumps(canonical,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    (WORK/'reference_review.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    for c in book['chapters']:
        print(c['id'],len(c['glossary']),'terms;',sum(len(t.get('figures',[])) for t in c['glossary']),'figures')

if __name__=='__main__': main()
