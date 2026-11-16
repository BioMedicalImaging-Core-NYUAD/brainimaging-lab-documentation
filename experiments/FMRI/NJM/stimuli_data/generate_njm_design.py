#!/usr/bin/env python3
"""
generate_njm_design.py - build the NJM fMRI trial set and lookup tables from njm_fmri_parameters.json

What it writes (relative to this folder):
  attributes_levels.csv, job_profiles.csv, response_mapping.csv, physio_trigger_codes.csv,
  eyetracking_aoi.csv, design/njm_fmri_trials.csv, design/njm_practice_trials.csv,
  design/design_summary.txt, design/design_efficiency.txt

The trial set follows the protocol (11-12-26 draft): 48 paired choices built from 96 DISTINCT job
profiles out of the 108-profile universe (88.9 % coverage), chosen by a D-efficiency search with
level balance. Per-participant randomisation (run assignment, order, left/right swap, faces,
jitter) is NOT done here: MATLAB does it at run time (utils/setup/make_subject_design.m).

Re-run after editing the JSON:   python3 generate_njm_design.py     (needs numpy, pandas; seeded)
"""
import itertools, json, math, os
import numpy as np
import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
P = json.load(open(os.path.join(HERE, "njm_fmri_parameters.json")))
A = P["attributes"]; T = P["timing"]; S = P["session"]; R = P["response"]
ORIG = A["employer_origin"]["levels"]
SAL, REST, WORK = A["salary_aed"]["levels"], A["rest_days_per_week"]["levels"], A["workload"]["levels"]
SEED = 20261116
TERMS = list(itertools.product(range(3), range(3), range(3)))          # (salary idx, rest idx, workload idx)
BEST, WORST = (2, 2, 0), (0, 0, 2)                                     # AED 3,200 + 1 day + light  /  AED 1,800 + 0 days + heavy


def out(*parts):
    path = os.path.join(HERE, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path


# --------------------------------------------------------------------------- dominance helpers
def weak_dom(a, b):   # a at least as good as b on everything (more pay, more rest, lighter work), not identical
    return a != b and a[0] >= b[0] and a[1] >= b[1] and a[2] <= b[2]

def strict_dom(a, b):  # a better than b on all three terms
    return a[0] > b[0] and a[1] > b[1] and a[2] < b[2]

def invalid_tradeoff(a, b):
    return a == b or weak_dom(a, b) or weak_dom(b, a)


# --------------------------------------------------------------------------- D-error
def effects(i, n):
    v = np.zeros(n - 1)
    if i < n - 1: v[i] = 1
    else: v[:] = -1
    return v

ROWCACHE = {}
def row_x(o1, t1, o2, t2):
    key = (o1, t1, o2, t2)
    if key not in ROWCACHE:
        x1 = np.concatenate([effects(o1, 4), effects(t1[0], 3), effects(t1[1], 3), effects(t1[2], 3)])
        x2 = np.concatenate([effects(o2, 4), effects(t2[0], 3), effects(t2[1], 3), effects(t2[2], 3)])
        ROWCACHE[key] = x1 - x2
    return ROWCACHE[key]

def d_error(trials):
    X = np.array([row_x(*t) for t in trials]); M = X.T @ X / len(X); det = np.linalg.det(M)
    return np.inf if det <= 1e-12 else det ** (-1 / X.shape[1])


# --------------------------------------------------------------------------- the 48-trial set
def build_set(seed):
    rng = np.random.default_rng(seed)
    n_noncatch = S["n_trials_total"] - S["n_runs"] * S["catch_trials_per_run"]            # 44
    n_ident = S["n_runs"] * S["identical_terms_trials_per_run"]                            # 4

    # 1) drop 3 profiles per origin (a transversal: each level of each term once) -> 24 per origin, 96 total,
    #    every level of every term appears exactly 8 times within each origin
    while True:
        dropped = []
        for o in range(4):
            pr, pw = rng.permutation(3), rng.permutation(3)
            dropped.append({(s, int(pr[s]), int(pw[s])) for s in range(3)})
        union = set().union(*dropped)
        if len(union) == 12 and BEST not in union and WORST not in union: break             # 12 different term combos
    avail = [set(TERMS) - dropped[o] for o in range(4)]

    # 2) catch trial per origin: same origin, best profile (high pay, weekly rest day, light work) against the
    #    worst one. These two profiles dominate / are dominated by every other profile, so they cannot be part
    #    of a genuine trade-off trial anyway.
    catch = []
    for o in range(4):
        catch.append((o, BEST, WORST)); avail[o] -= {BEST, WORST}

    # 3) origin pairs for the 44 other trials: 6 unordered pairs x 7, +1 for two disjoint pairs
    up = list(itertools.combinations(range(4), 2))
    big = [(0, 5), (1, 4), (2, 3)][rng.integers(3)]
    n_pair = {p: n_noncatch // 6 + (1 if i in big else 0) for i, p in enumerate(up)}

    # 4) identical-terms trials on a 4-cycle of origins (each origin in exactly two of them)
    cyc = list(rng.permutation(4)); ident_pairs = [tuple(sorted((cyc[k], cyc[(k + 1) % 4]))) for k in range(4)]
    ident = []
    for (i, j) in ident_pairs[:n_ident]:
        common = sorted(avail[i] & avail[j]); t = common[rng.integers(len(common))]
        ident.append((i, t, j, t)); avail[i].discard(t); avail[j].discard(t); n_pair[(i, j)] -= 1

    # 5) trade-off trials: random start, then hill-climb (swap two profiles of the same origin between trials)
    pools = [list(rng.permutation(sorted(avail[o]))) for o in range(4)]
    pools = [[tuple(int(x) for x in t) for t in pool] for pool in pools]
    trade = []
    for (i, j), n in n_pair.items():
        for _ in range(n):
            trade.append([i, pools[i].pop(), j, pools[j].pop()])
    assert all(len(p) == 0 for p in pools), "profile bookkeeping error"
    by_origin = {o: [(k, 1 if tr[0] == o else 3) for k, tr in enumerate(trade) if o in (tr[0], tr[2])] for o in range(4)}

    def score(tr):
        bad = sum(invalid_tradeoff(t[1], t[3]) for t in tr)
        return bad * 100.0 + (d_error([tuple(t) for t in tr] + ident) if bad == 0 else 0.0), bad
    cur, bad = score(trade)
    for it in range(40000):
        o = int(rng.integers(4)); (k1, c1), (k2, c2) = [by_origin[o][x] for x in rng.choice(len(by_origin[o]), 2, replace=False)]
        trade[k1][c1], trade[k2][c2] = trade[k2][c2], trade[k1][c1]
        new, nbad = score(trade)
        if new <= cur: cur, bad = new, nbad
        else: trade[k1][c1], trade[k2][c2] = trade[k2][c2], trade[k1][c1]
    assert bad == 0, "could not remove dominated/identical trade-off trials"

    rows = []
    for t in trade: rows.append(("tradeoff", "", *t))
    for t in ident: rows.append(("identical_terms", "", *t))
    for o, hi, lo in catch:
        first_is_hi = rng.random() < 0.5
        rows.append(("catch", "P1" if first_is_hi else "P2", o, hi if first_is_hi else lo, o, lo if first_is_hi else hi))
    rows = [rows[k] for k in rng.permutation(len(rows))]
    recs = []
    for k, (kind, dom, o1, t1, o2, t2) in enumerate(rows):
        if kind != "catch" and rng.random() < 0.5: o1, t1, o2, t2 = o2, t2, o1, t1      # P1/P2 order carries no meaning
        recs.append(dict(trial_id=k + 1, trial_kind=kind, is_catch=int(kind == "catch"), dominant_profile=dom,
                         P1_origin=ORIG[o1], P1_salary_aed=SAL[t1[0]], P1_rest_days=REST[t1[1]], P1_workload=WORK[t1[2]],
                         P2_origin=ORIG[o2], P2_salary_aed=SAL[t2[0]], P2_rest_days=REST[t2[1]], P2_workload=WORK[t2[2]]))
    df = pd.DataFrame(recs)
    noncatch = [tuple(t) for t in trade] + ident
    return df, d_error(noncatch), d_error([tuple(t) for t in trade])


def check_set(df):
    prof = [(r.P1_origin, r.P1_salary_aed, r.P1_rest_days, r.P1_workload) for r in df.itertuples()] + \
           [(r.P2_origin, r.P2_salary_aed, r.P2_rest_days, r.P2_workload) for r in df.itertuples()]
    assert len(prof) == 96 and len(set(prof)) == 96, "profiles are not all distinct"
    idx = lambda r, p: (SAL.index(getattr(r, p + "_salary_aed")), REST.index(getattr(r, p + "_rest_days")), WORK.index(getattr(r, p + "_workload")))
    for r in df.itertuples():
        a, b = idx(r, "P1"), idx(r, "P2")
        if r.trial_kind == "tradeoff": assert r.P1_origin != r.P2_origin and not invalid_tradeoff(a, b), r
        if r.trial_kind == "identical_terms": assert r.P1_origin != r.P2_origin and a == b, r
        if r.trial_kind == "catch":
            hi, lo = (a, b) if r.dominant_profile == "P1" else (b, a)
            assert r.P1_origin == r.P2_origin and strict_dom(hi, lo), r
    return prof


def practice_set(df, rng):
    used = {frozenset([(r.P1_origin, r.P1_salary_aed, r.P1_rest_days, r.P1_workload), (r.P2_origin, r.P2_salary_aed, r.P2_rest_days, r.P2_workload)]) for r in df.itertuples()}
    n = S["practice_trials"]; recs = []
    while len(recs) < n:
        kind = "catch" if len(recs) == n // 2 else "tradeoff"
        o1 = int(rng.integers(4)); o2 = o1 if kind == "catch" else int(rng.choice([o for o in range(4) if o != o1]))
        t1, t2 = TERMS[rng.integers(27)], TERMS[rng.integers(27)]
        if kind == "catch" and not strict_dom(t1, t2): continue
        if kind == "tradeoff" and invalid_tradeoff(t1, t2): continue
        p1 = (ORIG[o1], SAL[t1[0]], REST[t1[1]], WORK[t1[2]]); p2 = (ORIG[o2], SAL[t2[0]], REST[t2[1]], WORK[t2[2]])
        if frozenset([p1, p2]) in used: continue
        used.add(frozenset([p1, p2]))
        recs.append(dict(trial_id=len(recs) + 1, trial_kind=kind, is_catch=int(kind == "catch"), dominant_profile="P1" if kind == "catch" else "",
                         P1_origin=p1[0], P1_salary_aed=p1[1], P1_rest_days=p1[2], P1_workload=p1[3],
                         P2_origin=p2[0], P2_salary_aed=p2[1], P2_rest_days=p2[2], P2_workload=p2[3]))
    return pd.DataFrame(recs)


# --------------------------------------------------------------------------- lookup tables
def write_tables(used_profiles):
    rows = []
    for key, a in A.items():
        for i, lev in enumerate(a["levels"]):
            rows.append(dict(attribute=key, level_index=i + 1, level=lev, label=a["labels"][i],
                             display_text=a["display"][i], detail_text=a["detail"][i], icon=a["icon"]))
    pd.DataFrame(rows).to_csv(out("attributes_levels.csv"), index=False)

    pd.DataFrame(dict(button=R["buttons"], finger=R["fingers"], label=R["labels"], choice=R["choice"],
                      confidence=R["confidence"], hand=R["response_hand"], vpixx_box=R["vpixx_box"],
                      vpixx_color_PLACEHOLDER=R["vpixx_colors_PLACEHOLDER"],
                      keyboard_key=R["keyboard_keys"])).to_csv(out("response_mapping.csv"), index=False)

    codes = [(1, "RUN_START", "first scanner trigger received"), (2, "RUN_END", "end of lead-out fixation"),
             (10, "PRETRIAL_FIXATION", "fixation cross before phase 1"),
             (11, "PHASE1_ONSET", "employer photos + origin shown"), (12, "GAP1_ONSET", "fixation between phase 1 and 2"),
             (21, "PHASE2_ONSET", "full offers shown"), (22, "GAP2_ONSET", "fixation between phase 2 and 3"),
             (31, "PHASE3_ONSET", "decision screen shown"),
             (41, "RESPONSE_B1", "Definitely Accept Offer A"), (42, "RESPONSE_B2", "Probably Accept Offer A"),
             (43, "RESPONSE_B3", "Probably Accept Offer B"), (44, "RESPONSE_B4", "Definitely Accept Offer B"),
             (49, "RESPONSE_TIMEOUT", "no response within phase 3 window"), (51, "ITI_ONSET", "inter-trial fixation")]
    pd.DataFrame(codes, columns=["code", "event", "description"]).assign(
        status="SIMULATED - verify DOUT bit mapping with experiments/EEG-FMRI/general/bit_test.m",
        eyelink_message=lambda d: d.event).to_csv(out("physio_trigger_codes.csv"), index=False)

    full = [dict(profile_id=i + 1, employer_origin=o, salary_aed=s, rest_days_per_week=r, workload=w,
                 used_in_fmri_set=int((o, s, r, w) in used_profiles))
            for i, (o, s, r, w) in enumerate(itertools.product(ORIG, SAL, REST, WORK))]
    pd.DataFrame(full).to_csv(out("job_profiles.csv"), index=False)


def write_aois():
    L = P["display"]["layout_deg"]; rows = []
    def add(phase, side, el, x, y, w, h): rows.append((phase, side, el, x, y, w, h))
    for side, cx in zip("AB", L["card_center_x"]):
        for phase, attrs in (("phase1", ["employer_origin"]), ("phase2", list(L["row_y"])), ("phase3", ["employer_origin"])):
            add(phase, side, "photo", cx, L["photo"]["y"], L["photo"]["w"], L["photo"]["h"])
            for a in attrs: add(phase, side, a, cx, L["row_y"][a], L["card_width"], L["row_height"])
    add("phase3", "-", "prompt", 0.0, L["prompt_y"], 16.0, 1.2)
    for k, x in enumerate(L["option_center_x"]):
        add("phase3", R["choice"][k], f"option_{k+1}", x, L["option_y"], L["option_w"], L["option_h"])
    d = pd.DataFrame(rows, columns=["phase", "side", "element", "x_center_deg", "y_center_deg", "width_deg", "height_deg"])
    d["left_deg"] = d.x_center_deg - d.width_deg / 2; d["right_deg"] = d.x_center_deg + d.width_deg / 2
    d["top_deg"] = d.y_center_deg - d.height_deg / 2; d["bottom_deg"] = d.y_center_deg + d.height_deg / 2
    d["note"] = "from display.layout_deg in the JSON; +y is down; the task converts with VP.pixelsPerDegree and writes the pixel AOIs into the EDF"
    d.sort_values(["phase", "side"]).to_csv(out("eyetracking_aoi.csv"), index=False)


# --------------------------------------------------------------------------- design efficiency (phase regressors)
def hrf(dt=0.1, length=32.0):
    t = np.arange(0, length, dt)
    h = t ** 5 * np.exp(-t) / math.gamma(6) - t ** 15 * np.exp(-t) / math.gamma(16) / 6
    return h / h.sum()

def schedule(o, rng, n=12):
    z = np.zeros(n); perm = lambda v: rng.permutation(v) if v is not None else z
    pre, g1, g2, iti = perm(o["pre"]), perm(o["gap"]), perm(o["gap"]), perm(o["iti"])
    s = dict(p1=[], p2=[], p3=[]); t = o["lead_in"]
    for k in range(n):
        t += pre[k]; s["p1"].append((t, o["p1"])); t += o["p1"] + g1[k]
        s["p2"].append((t, o["p2"])); t += o["p2"] + g2[k]
        rt = min(o["p3"], max(0.6, rng.normal(1.6, 0.5))); s["p3"].append((t, rt)); t += o["p3"] + iti[k]
    s["dur"] = t + o["lead_out"]; return s

def canonical(s, tr, dt=0.1):
    n = int(np.ceil(s["dur"] / dt)); regs = []
    for ph in ("p1", "p2", "p3"):
        x = np.zeros(n)
        for on, du in s[ph]: x[int(round(on / dt)):int(round((on + du) / dt))] = 1
        regs.append(np.convolve(x, hrf(dt))[:n][:: int(round(tr / dt))])
    X = np.column_stack(regs); X = X - X.mean(0); C = np.corrcoef(X.T)
    return C, np.diag(np.linalg.inv(C))

def fir(scheds, tr, nb=10):
    blocks = []
    for s in scheds:
        nv = int(np.ceil(s["dur"] / tr)); X = np.zeros((nv, 3 * nb))
        for pi, ph in enumerate(("p1", "p2", "p3")):
            for on, _ in s[ph]:
                b0 = int(np.floor(on / tr + 1e-9))
                for j in range(nb):
                    if b0 + j < nv: X[b0 + j, pi * nb + j] = 1
        blocks.append(X)
    X = np.vstack(blocks); I = np.zeros((len(X), len(blocks))); r = 0
    for i, b in enumerate(blocks): I[r:r + len(b), i] = 1; r += len(b)
    Xf = np.hstack([X, I]); rank = np.linalg.matrix_rank(Xf)
    if rank < Xf.shape[1]: return rank, Xf.shape[1], np.inf
    vif = np.diag(np.linalg.inv(Xf.T @ Xf))[:3 * nb] * ((X - X.mean(0)) ** 2).sum(0)
    return rank, Xf.shape[1], float(vif.max())

def efficiency_report():
    rng = np.random.default_rng(SEED); E = lambda v, c: np.repeat(v, c).astype(float)
    pre = E(T["pretrial_fixation_values_s"], T["pretrial_fixation_counts"]); iti = E(T["iti_values_s"], T["iti_counts"])
    gap = E(T["gap1_values_s"], T["gap1_counts"])
    base = dict(p1=T["phase1_employer_s"], p2=T["phase2_offer_s"], p3=T["phase3_decision_max_s"],
                lead_in=S["lead_in_fixation_s"], lead_out=S["lead_out_fixation_s"])
    opts = [("A  DEFAULT (JSON): protocol timing table + 1-3 s gaps between phases", dict(pre=pre, gap=gap, iti=iti)),
            ("B  protocol timing table exactly as printed (no gap between phases)", dict(pre=pre, gap=None, iti=iti)),
            ("C  no pre-trial fixation, 1-3 s gaps between phases, ITI 3-7 s", dict(pre=None, gap=gap, iti=iti)),
            ("D  protocol text read literally: 3-7 s between phases and between trials", dict(pre=None, gap=iti, iti=iti))]
    lines = ["Phase-regressor collinearity for the NJM run schedule (12 trials per run, 4 runs)",
             "Phase 1 %.1f s, Phase 2 %.1f s, Phase 3 window %.1f s (protocol 11-12-26, timing table)." % (base["p1"], base["p2"], base["p3"]),
             "canonical: correlation / VIF between the three HRF-convolved phase regressors (one run).",
             "FIR: phase-specific deconvolution (10 bins x 3 phases, 4 runs) - the 'independent HRF deconvolution",
             "across three distinct processing stages' the protocol asks for. inf = cannot be estimated.", ""]
    for tr in sorted({T["tr_s"], 1.0}, reverse=True):
        lines.append("---------------- TR = %.2f s%s" % (tr, "  (placeholder in the JSON)" if tr == T["tr_s"] else "  (for comparison)"))
        for name, o in opts:
            o = dict(base, **o); Cs, Vs, Ds, F = [], [], [], []
            for k in range(100):
                ss = [schedule(o, rng) for _ in range(4)]; C, v = canonical(ss[0], tr); Cs.append(C); Vs.append(v); Ds.append(ss[0]["dur"])
                if k < 20: F.append(fir(ss, tr))
            C, V, d = np.mean(Cs, 0), np.mean(Vs, 0), float(np.mean(Ds)); fv = [f[2] for f in F]
            lines += [name,
                      "   run %.0f s (%.2f min) = %d volumes; 4 runs = %.1f min" % (d, d / 60, math.ceil(d / tr) + T["extra_volumes_after_design"], 4 * d / 60),
                      "   canonical: r(P1,P2) %+.2f  r(P2,P3) %+.2f  r(P1,P3) %+.2f   VIF %.1f / %.1f / %.1f" % (C[0, 1], C[1, 2], C[0, 2], *V),
                      "   FIR: rank %d of %d, max VIF %s" % (F[0][0], F[0][1], "inf (NOT estimable)" if not np.isfinite(max(fv)) else "%.1f" % np.median(fv)), ""]
    open(out("design", "design_efficiency.txt"), "w").write("\n".join(lines))
    return "\n".join(lines)


# --------------------------------------------------------------------------- main
if __name__ == "__main__":
    best = None
    for k in range(6):                                                 # a few restarts, keep the most efficient set
        df, de_all, de_trade = build_set(SEED + k)
        if best is None or de_all < best[1]: best = (df, de_all, de_trade, SEED + k)
    df, de_all, de_trade, seed = best
    prof = check_set(df)
    df.to_csv(out("design", "njm_fmri_trials.csv"), index=False)
    practice_set(df, np.random.default_rng(SEED + 500)).to_csv(out("design", "njm_practice_trials.csv"), index=False)
    write_tables(set(prof)); write_aois()

    P1 = df[["P1_origin", "P1_salary_aed", "P1_rest_days", "P1_workload"]].set_axis(["o", "s", "r", "w"], axis=1)
    P2 = df[["P2_origin", "P2_salary_aed", "P2_rest_days", "P2_workload"]].set_axis(["o", "s", "r", "w"], axis=1)
    allp = pd.concat([P1, P2]); nc = df[df.is_catch == 0]
    dsal = nc.P1_salary_aed - nc.P2_salary_aed; drest = nc.P1_rest_days - nc.P2_rest_days; dwork = nc.P1_workload - nc.P2_workload
    pairs = nc.apply(lambda r: " / ".join(sorted([r.P1_origin, r.P2_origin])), axis=1).value_counts().sort_index()
    dur = S["lead_in_fixation_s"] + S["lead_out_fixation_s"] + 12 * (T["phase1_employer_s"] + T["phase2_offer_s"] + T["phase3_decision_max_s"]) + \
        sum(float(np.dot(T[k + "_values_s"], T[k + "_counts"])) for k in ("pretrial_fixation", "gap1", "gap2", "iti"))
    nvol = math.ceil(dur / T["tr_s"]) + T["extra_volumes_after_design"]
    summ = ["NJM fMRI trial set (design/njm_fmri_trials.csv) - search seed %d" % seed, "",
            "Run length %.1f s (%.2f min); TR %.2f s (placeholder) -> program %d volumes per run (incl. %d spare)." % (dur, dur / 60, T["tr_s"], nvol, T["extra_volumes_after_design"]),
            "4 runs = %.1f min of task scanning; with %d-%d s rests between runs: %.0f-%.0f min." % (
                4 * dur / 60, *S["rest_between_runs_s"], (4 * dur + 3 * S["rest_between_runs_s"][0]) / 60, (4 * dur + 3 * S["rest_between_runs_s"][1]) / 60), "",
            "trials: %d  (tradeoff %d, identical_terms %d, catch %d)" % (len(df), (df.trial_kind == "tradeoff").sum(), (df.trial_kind == "identical_terms").sum(), df.is_catch.sum()),
            "distinct job profiles: %d of %d (%.1f %% of the full factorial)" % (len(set(prof)), 108, 100 * len(set(prof)) / 108),
            "D-error, effects-coded differences, zero priors: %.3f (44 non-catch trials), %.3f (40 trade-off trials)" % (de_all, de_trade), "",
            "appearances per employer origin : " + str(allp.o.value_counts().reindex(ORIG).to_dict()),
            "appearances per salary level    : " + str(allp.s.value_counts().sort_index().to_dict()),
            "appearances per rest-day level  : " + str(allp.r.value_counts().sort_index().to_dict()),
            "appearances per workload level  : " + str(allp.w.value_counts().sort_index().to_dict()),
            "levels within each origin       : every salary / rest-day / workload level appears exactly 8 times per origin: %s" % (
                all((allp[allp.o == o][c].value_counts() == 8).all() for o in ORIG for c in "srw")), "",
            "origin pairs in the 44 non-catch trials:"] + ["   %-22s %d" % (k, v) for k, v in pairs.items()] + ["",
            "correlation of attribute differences (non-catch): salary-rest %+.2f, salary-workload %+.2f, rest-workload %+.2f" % (
                dsal.corr(drest), dsal.corr(dwork), drest.corr(dwork)),
            "non-catch trials with a 0-rest-day option: %d;  with 0 rest days on exactly one side: %d" % (
                ((nc.P1_rest_days == 0) | (nc.P2_rest_days == 0)).sum(), ((nc.P1_rest_days == 0) ^ (nc.P2_rest_days == 0)).sum()),
            "catch trials (origin, dominant profile): " + ", ".join("%s/%s" % (r.P1_origin, r.dominant_profile) for r in df[df.is_catch == 1].itertuples()), "",
            "Not in this file (done per participant by MATLAB, seeded by subject ID): split into 4 runs (1 catch +",
            "1 identical-terms + 10 trade-off each), trial order, left/right side (half the trials swapped), which",
            "face shows each origin, and the jitter order."]
    open(out("design", "design_summary.txt"), "w").write("\n".join(summ) + "\n")
    print("\n".join(summ)); print(); print(efficiency_report()); print("done")
