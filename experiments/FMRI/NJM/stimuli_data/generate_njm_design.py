#!/usr/bin/env python3
"""
generate_njm_design.py - build the NJM fMRI stimulus/design files from njm_fmri_parameters.json

Everything here is SIMULATED where the protocol gives no values (see parameter_sources.csv).
Re-run after editing the JSON:   python3 generate_njm_design.py
Needs: numpy, pandas, pillow.  Seeded, so output is reproducible.

Writes (relative to this folder):
  attributes_levels.csv, response_mapping.csv, physio_trigger_codes.csv, job_profiles.csv,
  eyetracking_aoi.csv, faces/, icons/, design/design_vXX.csv, design/design_summary.txt,
  design/design_efficiency.txt, simulated/participants.tsv(.json), simulated/sub-9999/ses-01/*_events.tsv(.json)
"""
import itertools, json, math, os
import numpy as np
import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
P = json.load(open(os.path.join(HERE, "njm_fmri_parameters.json")))
A = P["attributes"]; T = P["timing"]; S = P["session"]; R = P["response"]
ORIG = A["employer_origin"]["levels"]
SAL, REST, WORK = A["salary_aed"]["levels"], A["rest_days_per_week"]["levels"], A["workload"]["levels"]
SEED = 20261105


def out(*parts):
    path = os.path.join(HERE, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path


# --------------------------------------------------------------------------- lookup tables
def write_tables():
    rows = []
    for key, a in A.items():
        for i, lev in enumerate(a["levels"]):
            rows.append(dict(attribute=key, level_index=i + 1, level=lev, label=a["labels"][i],
                             display_text=a["display"][i], icon=a["icon"]))
    pd.DataFrame(rows).to_csv(out("attributes_levels.csv"), index=False)

    pd.DataFrame(dict(button=R["buttons"], finger=R["fingers"], label=R["labels"], choice=R["choice"],
                      confidence=R["confidence"], hand=R["response_hand"], vpixx_box=R["vpixx_box"],
                      vpixx_color_PLACEHOLDER=R["vpixx_colors_PLACEHOLDER"],
                      keyboard_key=R["keyboard_keys"])).to_csv(out("response_mapping.csv"), index=False)

    codes = [(1, "RUN_START", "first scanner trigger received"), (2, "RUN_END", "end of lead-out fixation"),
             (11, "PHASE1_ONSET", "employer photos + origin shown"), (12, "ISI1_ONSET", "fixation between phase 1 and 2"),
             (21, "PHASE2_ONSET", "full offers shown"), (22, "ISI2_ONSET", "fixation between phase 2 and 3"),
             (31, "PHASE3_ONSET", "decision screen shown"),
             (41, "RESPONSE_B1", "Definitely Accept Offer A"), (42, "RESPONSE_B2", "Probably Accept Offer A"),
             (43, "RESPONSE_B3", "Probably Accept Offer B"), (44, "RESPONSE_B4", "Definitely Accept Offer B"),
             (49, "RESPONSE_TIMEOUT", "no response within phase 3 window"), (51, "ITI_ONSET", "inter-trial fixation")]
    pd.DataFrame(codes, columns=["code", "event", "description"]).assign(
        status="SIMULATED - verify DOUT bit mapping with experiments/EEG-FMRI/general/bit_test.m",
        eyelink_message=lambda d: d.event).to_csv(out("physio_trigger_codes.csv"), index=False)

    prof = [dict(profile_id=i + 1, salary_aed=s, rest_days_per_week=r, workload=w)
            for i, (s, r, w) in enumerate(itertools.product(SAL, REST, WORK))]
    full = [dict(profile_id=i + 1, employer_origin=o, salary_aed=s, rest_days_per_week=r, workload=w)
            for i, (o, s, r, w) in enumerate(itertools.product(ORIG, SAL, REST, WORK))]
    pd.DataFrame(full).to_csv(out("job_profiles.csv"), index=False)
    return [(p["salary_aed"], p["rest_days_per_week"], p["workload"]) for p in prof]


def write_aois():
    L = P["display"]["layout_deg"]; xs = P["display"]["column_center_x_deg"]; rows = []
    for phase, elems in L.items():
        for el, g in elems.items():
            if el == "options":
                for k, x in enumerate(g["x"]):
                    rows.append((phase, R["choice"][k], f"option_{k+1}", x, g["y"], g["w"], g["h"]))
            elif el == "prompt":
                rows.append((phase, "-", el, 0.0, g["y"], g["w"], g["h"]))
            else:
                for side, x in zip("AB", xs):
                    rows.append((phase, side, el, x, g["y"], g["w"], g["h"]))
    d = pd.DataFrame(rows, columns=["phase", "side", "element", "x_center_deg", "y_center_deg", "width_deg", "height_deg"])
    d["left_deg"] = d.x_center_deg - d.width_deg / 2; d["right_deg"] = d.x_center_deg + d.width_deg / 2
    d["top_deg"] = d.y_center_deg - d.height_deg / 2; d["bottom_deg"] = d.y_center_deg + d.height_deg / 2
    d["note"] = "SIMULATED layout; +y is down (screen coordinates); convert with VP.pixelsPerDegree"
    d.to_csv(out("eyetracking_aoi.csv"), index=False)


# --------------------------------------------------------------------------- placeholder images
def write_images():
    from PIL import Image, ImageDraw, ImageFont
    def font(sz):
        try: return ImageFont.load_default(size=sz)
        except TypeError: return ImageFont.load_default()
    W, H = P["faces"]["image_size_px"]; n = P["faces"]["identities_per_origin"]; inv = []
    for o in ORIG:
        for k in range(1, n + 1):
            im = Image.new("RGB", (W, H), (150, 150, 150)); d = ImageDraw.Draw(im)
            d.ellipse([W*.3, H*.14, W*.7, H*.52], fill=(110, 110, 110))
            d.rounded_rectangle([W*.15, H*.56, W*.85, H*1.05], radius=int(W*.2), fill=(110, 110, 110))
            d.text((W/2, H*.07), "PLACEHOLDER", fill=(235, 235, 235), anchor="mm", font=font(28))
            d.text((W/2, H*.78), f"{o} {k:02d}", fill=(235, 235, 235), anchor="mm", font=font(34))
            fn = f"face_{o.lower()}_{k:02d}.png"; im.save(out("faces", fn))
            inv.append(dict(face_id=f"{o}_{k:02d}", employer_origin=o, file=fn, sex=P["faces"]["sex"],
                            source="PLACEHOLDER - replace with standardized headshot",
                            mean_luminance_target="match across all faces (pupil measure)"))
    pd.DataFrame(inv).to_csv(out("faces", "face_inventory.csv"), index=False)

    S_ = 128; wht = (255, 255, 255, 255); lw = 7
    def canvas():
        im = Image.new("RGBA", (S_, S_), (0, 0, 0, 0)); return im, ImageDraw.Draw(im)
    im, d = canvas(); d.ellipse([40, 12, 88, 60], outline=wht, width=lw); d.arc([18, 66, 110, 160], 180, 360, fill=wht, width=lw)
    im.save(out("icons", "icon_employer.png"))
    im, d = canvas(); d.ellipse([12, 12, 116, 116], outline=wht, width=lw); d.ellipse([42, 12, 86, 116], outline=wht, width=5)
    d.line([12, 64, 116, 64], fill=wht, width=5); d.line([22, 38, 106, 38], fill=wht, width=4); d.line([22, 90, 106, 90], fill=wht, width=4)
    im.save(out("icons", "icon_background.png"))
    im, d = canvas(); d.ellipse([10, 10, 118, 118], outline=wht, width=lw); d.text((64, 64), "AED", fill=wht, anchor="mm", font=font(34))
    im.save(out("icons", "icon_salary.png"))
    im, d = canvas(); d.rectangle([14, 24, 114, 116], outline=wht, width=lw); d.rectangle([14, 24, 114, 48], fill=wht)
    d.line([40, 10, 40, 34], fill=wht, width=lw); d.line([88, 10, 88, 34], fill=wht, width=lw); d.text((64, 84), "17", fill=wht, anchor="mm", font=font(36))
    im.save(out("icons", "icon_rest_days.png"))
    im, d = canvas(); d.line([96, 10, 58, 74], fill=wht, width=lw); d.polygon([(36, 70), (80, 70), (100, 118), (14, 118)], outline=wht, width=lw)
    for x in (34, 50, 66, 82): d.line([x + 4, 78, x - 2, 114], fill=wht, width=3)
    im.save(out("icons", "icon_workload.png"))


# --------------------------------------------------------------------------- design
def better(a, b):  # True if profile a weakly dominates b (higher salary, more rest, lighter workload)
    return a[0] >= b[0] and a[1] >= b[1] and a[2] <= b[2] and a != b

def effects(level, levels):
    v = np.zeros(len(levels) - 1); i = levels.index(level)
    if i < len(levels) - 1: v[i] = 1
    else: v[:] = -1
    return v

def row_x(oa, ob, ta, tb):
    xa = np.concatenate([effects(oa, ORIG), effects(ta[0], SAL), effects(ta[1], REST), effects(ta[2], WORK)])
    xb = np.concatenate([effects(ob, ORIG), effects(tb[0], SAL), effects(tb[1], REST), effects(tb[2], WORK)])
    return xa - xb

def d_error(X):
    M = X.T @ X / len(X); det = np.linalg.det(M)
    return np.inf if det <= 1e-12 else det ** (-1 / X.shape[1])

def balance_pen(tp):
    pen = 0.0
    for j, levs in enumerate((SAL, REST, WORK)):
        for side in (0, 1):
            c = np.array([sum(t[side][j] == l for t in tp) for l in levs]); pen += ((c - len(tp) / 3) ** 2).sum()
    return pen

def origin_pairs(rng):
    n = S["n_runs"] * (S["trials_per_run"] - S["catch_trials_per_run"])          # 44
    up = list(itertools.combinations(range(4), 2))
    base, extra = divmod(n, len(up))                                              # 7, 2
    disjoint = [(0, 5), (1, 4), (2, 3)]                                           # index pairs of disjoint pairs in `up`
    big = disjoint[rng.integers(3)] if extra == 2 else ()
    for _ in range(5000):
        pairs = []
        for i, (g1, g2) in enumerate(up):
            k = base + (1 if i in big else 0)
            if rng.random() < 0.5: g1, g2 = g2, g1                                # random side gets the odd trial
            left = rng.permutation([g1] * ((k + 1) // 2) + [g2] * (k // 2))
            pairs += [(ORIG[a], ORIG[g2 if a == g1 else g1]) for a in left]
        if all(sum(p[0] == o for p in pairs) == n // 4 for o in ORIG):
            return pairs
    raise RuntimeError("could not balance sides")

def build_version(v, profiles):
    rng = np.random.default_rng(SEED + v)
    nr, tpr = S["n_runs"], S["trials_per_run"]
    pairs = origin_pairs(rng); n = len(pairs)
    n_ident = S["identical_terms_trials_per_run"] * nr
    # identical-terms trials: distinct unordered origin pairs, distinct profiles
    seen, ident_idx = set(), []
    for i in rng.permutation(n):
        key = frozenset(pairs[i])
        if key not in seen: seen.add(key); ident_idx.append(i)
        if len(ident_idx) == n_ident: break
    ident_prof = [profiles[i] for i in rng.choice(len(profiles), n_ident, replace=False)]
    cand = [(a, b) for a in profiles for b in profiles if a != b and not better(a, b) and not better(b, a)]
    trade_idx = [i for i in range(n) if i not in ident_idx]
    terms = [None] * n
    for i, p in zip(ident_idx, ident_prof): terms[i] = (p, p)
    for i in trade_idx: terms[i] = cand[rng.integers(len(cand))]
    def score(tm):
        X = np.array([row_x(pairs[i][0], pairs[i][1], tm[i][0], tm[i][1]) for i in range(n)])
        return d_error(X) + 0.004 * balance_pen([tm[i] for i in trade_idx])
    cur = score(terms)
    for it in range(12000):                                                       # hill climbing
        new = list(terms)
        if rng.random() < 0.5:
            new[trade_idx[rng.integers(len(trade_idx))]] = cand[rng.integers(len(cand))]
        else:
            i, j = rng.choice(trade_idx, 2, replace=False); new[i], new[j] = new[j], new[i]
        s = score(new)
        if s < cur: terms, cur = new, s
    trials = [dict(kind="identical_terms" if i in ident_idx else "tradeoff", A_origin=pairs[i][0], B_origin=pairs[i][1],
                   A=terms[i][0], B=terms[i][1], dominant="") for i in range(n)]
    # catch trials: one per origin, dominant side 2xA 2xB
    sides = rng.permutation(["A"] * P["catch_trials"]["dominant_side_counts"]["A"] + ["B"] * P["catch_trials"]["dominant_side_counts"]["B"])
    catch = []
    for o, sd in zip(rng.permutation(ORIG), sides):
        while True:
            hi, lo = profiles[rng.integers(27)], profiles[rng.integers(27)]
            if hi[0] > lo[0] and hi[1] > lo[1] and hi[2] < lo[2]: break
        catch.append(dict(kind="catch", A_origin=o, B_origin=o, A=hi if sd == "A" else lo, B=lo if sd == "A" else hi, dominant=sd))
    # split into runs: one identical-terms trial per run, balanced origins/levels per run
    best, best_pen = None, np.inf
    tr = [t for t in trials if t["kind"] == "tradeoff"]; idt = [t for t in trials if t["kind"] == "identical_terms"]
    per = len(tr) // nr
    for _ in range(4000):
        perm = rng.permutation(len(tr)); runs = [[tr[k] for k in perm[r*per:(r+1)*per]] + [idt[r]] for r in range(nr)]
        pen = 0.0
        for run in runs:
            pen += sum((sum((t["A_origin"] == o) + (t["B_origin"] == o) for t in run) - 2 * len(run) / 4) ** 2 for o in ORIG)
            for j, levs in enumerate((SAL, REST, WORK)):
                pen += sum((sum((t["A"][j] == l) + (t["B"][j] == l) for t in run) - 2 * len(run) / 3) ** 2 for l in levs) * 0.5
        if pen < best_pen: best, best_pen = runs, pen
    # order within run + catch position, avoid same origin pair on consecutive trials
    rows = []; face_pool = {o: [] for o in ORIG}
    def next_face(o, avoid=None):
        if not face_pool[o]: face_pool[o] = list(rng.permutation(P["faces"]["identities_per_origin"]) + 1)
        for k, f in enumerate(face_pool[o]):
            if f != avoid: return face_pool[o].pop(k)
        face_pool[o] = list(rng.permutation(P["faces"]["identities_per_origin"]) + 1); return next_face(o, avoid)
    for r in range(nr):
        excl = P["catch_trials"]["excluded_positions"]
        for _ in range(2000):
            order = [best[r][k] for k in rng.permutation(len(best[r]))]
            pos = int(rng.choice([p for p in range(1, tpr + 1) if p not in excl]))
            order.insert(pos - 1, catch[r])
            if all({order[k]["A_origin"], order[k]["B_origin"]} != {order[k+1]["A_origin"], order[k+1]["B_origin"]} for k in range(tpr - 1)):
                break
        isi1 = rng.permutation(np.repeat(T["isi1_values_s"], T["isi1_counts_per_run"]))
        isi2 = rng.permutation(np.repeat(T["isi2_values_s"], T["isi2_counts_per_run"]))
        iti = rng.permutation(np.repeat(T["iti_values_s"], T["iti_counts_per_run"]))
        t = S["lead_in_fixation_s"]
        for k, tri in enumerate(order):
            fa = next_face(tri["A_origin"]); fb = next_face(tri["B_origin"], avoid=fa if tri["A_origin"] == tri["B_origin"] else None)
            p1 = t; p2 = p1 + T["phase1_employer_s"] + isi1[k]; p3 = p2 + T["phase2_offer_s"] + isi2[k]
            it = p3 + T["phase3_decision_max_s"]; t = it + iti[k]
            rows.append(dict(version=v, run=r + 1, trial_in_run=k + 1, trial_global=r * tpr + k + 1, trial_kind=tri["kind"],
                             catch=int(tri["kind"] == "catch"), dominant_side=tri["dominant"],
                             A_origin=tri["A_origin"], A_face=f"face_{tri['A_origin'].lower()}_{fa:02d}.png",
                             A_salary_aed=tri["A"][0], A_rest_days=tri["A"][1], A_workload=tri["A"][2],
                             B_origin=tri["B_origin"], B_face=f"face_{tri['B_origin'].lower()}_{fb:02d}.png",
                             B_salary_aed=tri["B"][0], B_rest_days=tri["B"][1], B_workload=tri["B"][2],
                             diff_salary_aed=tri["A"][0] - tri["B"][0], diff_rest_days=tri["A"][1] - tri["B"][1],
                             diff_workload=tri["A"][2] - tri["B"][2],
                             onset_phase1=p1, dur_phase1=T["phase1_employer_s"], isi1=isi1[k],
                             onset_phase2=p2, dur_phase2=T["phase2_offer_s"], isi2=isi2[k],
                             onset_phase3=p3, max_dur_phase3=T["phase3_decision_max_s"], onset_iti=it, iti=iti[k]))
        for row in rows[-tpr:]:
            row["run_duration_s"] = t + S["lead_out_fixation_s"]
    df = pd.DataFrame(rows)
    X = np.array([row_x(a, b, (s1, r1, w1), (s2, r2, w2)) for a, b, s1, r1, w1, s2, r2, w2 in
                  df.loc[df.catch == 0, ["A_origin", "B_origin", "A_salary_aed", "A_rest_days", "A_workload",
                                          "B_salary_aed", "B_rest_days", "B_workload"]].itertuples(index=False)])
    return df, d_error(X)


# --------------------------------------------------------------------------- design efficiency (phase regressors)
def hrf(dt=0.1, length=32.0):
    t = np.arange(0, length, dt)
    h = t ** 5 * np.exp(-t) / math.gamma(6) - t ** 15 * np.exp(-t) / math.gamma(16) / 6
    return h / h.sum()

def phase_vifs(schedule, tr, dt=0.1):
    n = int(np.ceil(schedule["dur"] / dt)); regs = []
    for ph in ("p1", "p2", "p3"):
        x = np.zeros(n)
        for on, du in schedule[ph]: x[int(on / dt):int((on + du) / dt)] = 1
        regs.append(np.convolve(x, hrf(dt))[:n][:: int(round(tr / dt))])
    X = np.column_stack(regs); X = X - X.mean(0)
    C = np.corrcoef(X.T); vif = np.diag(np.linalg.inv(C))
    return C, vif

def schedule(p1, p2, p3, isi, iti, rng, ntr=12, lead_in=10, lead_out=12):
    s = dict(p1=[], p2=[], p3=[]); t = lead_in
    for k in range(ntr):
        s["p1"].append((t, p1)); t += p1 + isi(rng)
        s["p2"].append((t, p2)); t += p2 + isi(rng)
        rt = min(p3, max(0.6, rng.normal(1.6, 0.5))); s["p3"].append((t, rt)); t += p3 + iti(rng)
    s["dur"] = t + lead_out; return s

def fir_check(scheds, tr, nbins=8):
    # FIR (finite impulse response) model: one column per phase x post-onset TR bin, runs stacked
    blocks = []
    for s in scheds:
        nv = int(np.ceil(s["dur"] / tr)); X = np.zeros((nv, 3 * nbins + 1)); X[:, -1] = 1
        for p_i, ph in enumerate(("p1", "p2", "p3")):
            for on, _ in s[ph]:
                b0 = int(np.floor(on / tr + 1e-9))
                for j in range(nbins):
                    if b0 + j < nv: X[b0 + j, p_i * nbins + j] = 1
        blocks.append(X)
    X = np.vstack(blocks); rank = np.linalg.matrix_rank(X)
    if rank < X.shape[1]: return rank, X.shape[1], np.inf
    XtX_inv = np.linalg.inv(X.T @ X); Xc = X[:, :-1] - X[:, :-1].mean(0)
    vif = np.diag(XtX_inv)[:-1] * (Xc ** 2).sum(0)
    return rank, X.shape[1], float(vif.max())

def efficiency_report(tr):
    rng = np.random.default_rng(SEED)
    itiv, itip = np.array(T["iti_values_s"]), np.array(T["iti_probabilities"]) / sum(T["iti_probabilities"])
    pick = lambda vals, pr: (lambda g: float(g.choice(vals, p=pr)))
    opts = [
        ("A  DEFAULT (this folder): P1 3.0 / ISI 1-3 / P2 4.0 / ISI 1-3 / P3 3.0 / ITI 3-7",
         3.0, 4.0, 3.0, pick(np.array(T["isi1_values_s"]), np.array(T["isi1_counts_per_run"]) / 12), pick(itiv, itip)),
        ("B  p.13 table, no inter-phase gap: P1 3.0 / P2 4.0 / P3 3.0 / ITI 2-6",
         3.0, 4.0, 3.0, lambda g: 0.0, pick(np.array([2., 3., 4., 5., 6.]), itip)),
        ("C  p.12 text: P1 4.0 / jitter 3-7 / P2 5.0 / jitter 3-7 / P3 3.0 / ITI 3-7",
         4.0, 5.0, 3.0, pick(itiv, itip), pick(itiv, itip)),
    ]
    lines = ["Phase-regressor collinearity (12 trials per run, TR = %.2f s, 200 simulated runs per option)" % tr,
             "r and VIF: canonical (double-gamma) HRF regressors per run. FIR: phase-specific deconvolution, the",
             "'independent HRF deconvolution across each processing stage' promised on protocol p.5 and p.12.",
             "VIF > 5 is usually taken as problematic.", ""]
    for name, a, b, c, isi, iti in opts:
        R_, V, D, S4 = [], [], [], []
        for k in range(200):
            s = schedule(a, b, c, isi, iti, rng); C, vif = phase_vifs(s, tr); R_.append(C); V.append(vif); D.append(s["dur"])
            if k < 4: S4.append(s)
        C, V = np.mean(R_, 0), np.mean(V, 0); rank, ncol, fvif = fir_check(S4, tr)
        lines += [name,
                  "   run length %.0f s (%.2f min) -> 4 runs = %.1f min" % (np.mean(D), np.mean(D) / 60, 4 * np.mean(D) / 60),
                  "   r(P1,P2) = %.2f   r(P2,P3) = %.2f   r(P1,P3) = %.2f" % (C[0, 1], C[1, 2], C[0, 2]),
                  "   canonical-HRF GLM: VIF  P1 = %.1f   P2 = %.1f   P3 = %.1f" % tuple(V),
                  "   FIR deconvolution (8 bins x 3 phases, 4 runs): rank %d of %d, max VIF = %s" % (
                      rank, ncol, "inf (NOT estimable)" if not np.isfinite(fvif) else "%.1f" % fvif), ""]
    open(out("design", "design_efficiency.txt"), "w").write("\n".join(lines))
    return "\n".join(lines)


# --------------------------------------------------------------------------- simulated participants + example output
def simulate_people():
    rng = np.random.default_rng(SEED + 99); lang = dict(Philippines="Tagalog", Indonesia="Indonesian", Kenya="Swahili",
        Uganda="Luganda", Ethiopia="Amharic", Nepal="Nepali", India="Hindi", Bangladesh="Bengali", **{"Sri Lanka": "Sinhala"})
    rows = []; n_each = 11
    for c_i, coh in enumerate(P["sample"]["cohorts"]):
        for k in range(n_each):
            idx = c_i * n_each + k; country = rng.choice(P["sample"]["cohort_countries"][coh])
            rows.append(dict(participant_id=f"sub-S{idx+1:03d}", cohort=coh, country=country, first_language=lang[country],
                             design_version=idx % S["n_design_versions"] + 1, age=int(rng.integers(22, 50)), handedness="R",
                             years_in_uae=round(float(rng.uniform(0.5, 12)), 1),
                             economic_vulnerability_1to7=int(rng.integers(1, 8)), perceived_legal_protection_1to7=int(rng.integers(1, 8))))
    pd.DataFrame(rows).to_csv(out("simulated", "participants.tsv"), sep="\t", index=False)
    json.dump({"_note": "ALL VALUES SIMULATED for pipeline testing; not real participants",
               "cohort": {"Description": "Worker geographic cohort (protocol p.1)"},
               "design_version": {"Description": "Which design/design_vXX.csv the participant runs (SIMULATED assignment: index mod 4)"},
               "economic_vulnerability_1to7": {"Description": "Baseline economic vulnerability (RQ4); scale SIMULATED"},
               "perceived_legal_protection_1to7": {"Description": "Perceived legal protections (RQ4); scale SIMULATED"}},
              open(out("simulated", "participants.json"), "w"), indent=2)

def simulate_events(design):
    rng = np.random.default_rng(SEED + 7)
    # arbitrary generative model for pipeline testing ONLY; origin effects set to zero on purpose
    u_sal = lambda s: (s - 2500) / 700 * 0.9; u_rest = {0.0: -2.0, 0.5: -0.4, 1.0: 0.0}; u_work = {1: 0.0, 2: -0.6, 3: -1.4}
    U = lambda s, r, w: u_sal(s) + u_rest[r] + u_work[w]
    d = design[design.version == 1]
    for run, g in d.groupby("run"):
        ev = []
        for t in g.itertuples():
            du = U(t.A_salary_aed, t.A_rest_days, t.A_workload) - U(t.B_salary_aed, t.B_rest_days, t.B_workload)
            rt = 0.7 + 1.3 * math.exp(-abs(du)) + rng.lognormal(-1.2, 0.5)
            timeout = rt > T["phase3_decision_max_s"]
            chooseA = rng.random() < 1 / (1 + math.exp(-1.5 * du))
            sure = abs(du) + rng.normal(0, 0.5) > 1.0
            btn = None if timeout else (1 if chooseA and sure else 2 if chooseA else 4 if sure else 3)
            base = dict(run=run, trial=t.trial_in_run, trial_kind=t.trial_kind, catch=t.catch,
                        A_origin=t.A_origin, B_origin=t.B_origin, A_face=t.A_face, B_face=t.B_face,
                        A_salary_aed=t.A_salary_aed, B_salary_aed=t.B_salary_aed, A_rest_days=t.A_rest_days,
                        B_rest_days=t.B_rest_days, A_workload=t.A_workload, B_workload=t.B_workload)
            resp = dict(response_button="n/a" if timeout else btn, response_label="n/a" if timeout else R["labels"][btn - 1],
                        choice="n/a" if timeout else R["choice"][btn - 1], confidence="n/a" if timeout else R["confidence"][btn - 1],
                        response_time="n/a" if timeout else round(rt, 3), timeout=int(timeout),
                        catch_pass="n/a" if not t.catch else int((not timeout) and R["choice"][btn - 1] == t.dominant_side))
            ev.append(dict(onset=t.onset_phase1, duration=t.dur_phase1, trial_type="phase1_employer", **base, **resp))
            ev.append(dict(onset=t.onset_phase2, duration=t.dur_phase2, trial_type="phase2_offer", **base, **resp))
            ev.append(dict(onset=t.onset_phase3, duration=T["phase3_decision_max_s"] if timeout else round(rt, 3),
                           trial_type="phase3_decision", **base, **resp))
            if not timeout:
                ev.append(dict(onset=round(t.onset_phase3 + rt, 3), duration=0, trial_type="response", **base, **resp))
        fn = f"sub-9999_ses-01_task-{P['study']['bids_task_name']}_run-{run:02d}_events.tsv"
        pd.DataFrame(ev).to_csv(out("simulated", "sub-9999", "ses-01", fn), sep="\t", index=False, na_rep="n/a")
    json.dump({"_note": "SIMULATED responses from an arbitrary utility model (origin effects = 0). Format example only.",
               "onset": {"Description": "Seconds from first scanner trigger", "Units": "s"},
               "duration": {"Description": "Phase duration; phase3 = RT (or 3.0 s on timeout)", "Units": "s"},
               "trial_type": {"Levels": {"phase1_employer": "Employer photos + origin", "phase2_offer": "Full offers",
                                         "phase3_decision": "Decision screen until response", "response": "Button press"}},
               "trial_kind": {"Levels": {"tradeoff": "Job terms differ, no dominance", "identical_terms": "Same terms, different origin",
                                         "catch": "Same origin, one option dominant"}},
               "response_button": {"Description": "1-4 = index/middle/ring/pinky (see response_mapping.csv)"},
               "confidence": {"Levels": {"definitely": "Buttons 1/4", "probably": "Buttons 2/3 (decision friction)"}},
               "catch_pass": {"Description": "Catch trials only: chose the dominant side"}},
              open(out("simulated", "sub-9999", "ses-01", f"task-{P['study']['bids_task_name']}_events.json"), "w"), indent=2)


# --------------------------------------------------------------------------- main
if __name__ == "__main__":
    profiles = write_tables(); write_aois(); write_images()
    versions, summ = [], []
    for v in range(1, S["n_design_versions"] + 1):
        df, de = build_version(v, profiles); df.to_csv(out("design", f"design_v{v:02d}.csv"), index=False); versions.append(df)
        ex = df[df.catch == 0]
        summ += [f"=== design_v{v:02d}.csv ===",
                 f"trials {len(df)} (tradeoff {sum(df.trial_kind=='tradeoff')}, identical_terms {sum(df.trial_kind=='identical_terms')}, catch {df.catch.sum()})",
                 f"D-error (effects-coded A-B differences, zero priors, non-catch trials) = {de:.3f}",
                 "origin appearances (A/B) non-catch: " + ", ".join(f"{o} {sum(ex.A_origin==o)}/{sum(ex.B_origin==o)}" for o in ORIG),
                 "salary levels (A+B slots): " + str({s: int((ex.A_salary_aed == s).sum() + (ex.B_salary_aed == s).sum()) for s in SAL}),
                 "rest levels   (A+B slots): " + str({r: int((ex.A_rest_days == r).sum() + (ex.B_rest_days == r).sum()) for r in REST}),
                 "workload lvls (A+B slots): " + str({w: int((ex.A_workload == w).sum() + (ex.B_workload == w).sum()) for w in WORK}),
                 "corr(diffs) salary-rest %.2f  salary-workload %.2f  rest-workload %.2f" % (
                     ex.diff_salary_aed.corr(ex.diff_rest_days), ex.diff_salary_aed.corr(ex.diff_workload), ex.diff_rest_days.corr(ex.diff_workload)),
                 "trials with a 0-rest-day option: %d" % int(((ex.A_rest_days == 0) | (ex.B_rest_days == 0)).sum()),
                 "catch positions: " + str(df[df.catch == 1].trial_in_run.tolist()) + "  dominant sides: " + str([str(x) for x in df[df.catch == 1].dominant_side]),
                 "run durations (s): " + str(sorted(set(df.run_duration_s.round(2)))),
                 ""]
    dur = versions[0].run_duration_s.iloc[0]; nvol = math.ceil(dur / T["tr_s"]) + T["extra_volumes_after_design"]
    summ.insert(0, f"Run length {dur:.1f} s ({dur/60:.2f} min); TR {T['tr_s']} s -> program {nvol} volumes per run "
                   f"(incl. {T['extra_volumes_after_design']} spare). 4 runs = {4*dur/60:.1f} min of task scanning.\n")
    open(out("design", "design_summary.txt"), "w").write("\n".join(summ))
    print("\n".join(summ)); print(efficiency_report(T["tr_s"]))
    simulate_people(); simulate_events(versions[0])
    print("done")
