#!/usr/bin/env python3
"""
prepare_faces.py - turn raw employer headshots into standardised NJM face stimuli

Implements the photo requirements of the protocol (p.19): same crop, scale and interpupillary
distance for every image, 0-degree frontal alignment, only the central facial features visible
(eyes, nose, mouth; hair, ears and neck removed), and equalised luminance and contrast.

Input   faces_raw/<ORIGIN>/*.png|jpg|jpeg      ORIGIN is one of SEA_SA, ARAB, AFRICAN, WESTERN
Output  faces/face_<origin>_<nn>.png           RGBA, transparent outside a soft oval
        faces/face_inventory.csv               one row per face (set, QC numbers, source file)
        faces/contact_sheet.png                all faces on the task background, for a visual check

Usage   python3 prepare_faces.py                         # process everything in faces_raw/
        python3 prepare_faces.py --lum-match across      # equalise lightness and contrast across ALL faces
        python3 prepare_faces.py --lum-match none        # leave lightness as generated
        python3 prepare_faces.py --behavioral-per-origin 25   # reserve faces for the behavioural task

Luminance   --lum-match within (default): every face is brought to the mean lightness and contrast of its own
            origin group. This removes exposure differences between photos but keeps natural skin tone.
            --lum-match across: every face is brought to the mean of the whole set. Luminance is then equal
            between origin groups (best for pupillometry) but skin tones are visibly changed.
            The lightness of every face before and after is written to face_inventory.csv either way.
Needs   numpy, pandas, opencv-python (or opencv-python-headless). The YuNet face detector (232 kB, MIT
        licence) is downloaded once into _source/models/ if it is not there.
"""
import argparse, glob, json, os, sys, urllib.request
import numpy as np
import pandas as pd
import cv2

HERE = os.path.dirname(os.path.abspath(__file__))
P = json.load(open(os.path.join(HERE, "njm_fmri_parameters.json")))
ORIGINS = P["attributes"]["employer_origin"]["levels"]
YUNET_URL = "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx"

# Geometry of the output image, in units of the interpupillary distance (IPD)
OVAL_HALF_WIDTH_IPD = 0.82      # inside the cheeks: no ears, no hair or head covering at the sides
OVAL_TAPER = 0.17               # egg shape: wider at eye level, narrower towards the jaw
OVAL_HALF_HEIGHT_IPD = 1.25     # from just above the eyebrows to just above the chin
OVAL_CENTER_BELOW_EYES_IPD = 0.50
OVAL_FILL = 0.94                # oval half-width as a fraction of half the image width
FEATHER_FRACTION = 0.06         # soft edge, as a fraction of the image width


def detector(model_path):
    if not os.path.exists(model_path):
        os.makedirs(os.path.dirname(model_path), exist_ok=True)
        print("Downloading face detector to", model_path)
        try:
            urllib.request.urlretrieve(YUNET_URL, model_path)
        except Exception as e:
            sys.exit("Could not download the YuNet model (%s).\nDownload it by hand from\n  %s\nand save it as\n  %s" % (e, YUNET_URL, model_path))
    return cv2.FaceDetectorYN.create(model_path, "", (320, 320), 0.6, 0.3, 50)


def find_eyes(det, img):
    """Return (right_eye_xy, left_eye_xy) in image coordinates (image-left eye first), or None."""
    h, w = img.shape[:2]; scale = 1.0
    if max(h, w) > 1200:                                   # the detector is trained on moderate sizes
        scale = 1200.0 / max(h, w)
    small = cv2.resize(img, (int(round(w * scale)), int(round(h * scale)))) if scale != 1.0 else img
    det.setInputSize((small.shape[1], small.shape[0]))
    _, faces = det.detect(small)
    if faces is None or len(faces) == 0:
        return None
    f = max(faces, key=lambda r: r[2] * r[3])              # largest face
    e1, e2 = np.array(f[4:6]) / scale, np.array(f[6:8]) / scale
    return (e1, e2) if e1[0] < e2[0] else (e2, e1)


def align(img, eyes, out_w, out_h):
    ipd_out = OVAL_FILL * (out_w / 2.0) / OVAL_HALF_WIDTH_IPD
    cy = out_h / 2.0; eye_y = cy - OVAL_CENTER_BELOW_EYES_IPD * ipd_out
    dst = np.float32([[out_w / 2.0 - ipd_out / 2.0, eye_y], [out_w / 2.0 + ipd_out / 2.0, eye_y]])
    src = np.float32(eyes)
    # similarity transform (rotation + uniform scale + shift) that maps the two eyes onto dst
    d_src, d_dst = src[1] - src[0], dst[1] - dst[0]
    s = np.hypot(*d_dst) / np.hypot(*d_src)
    ang = np.arctan2(d_dst[1], d_dst[0]) - np.arctan2(d_src[1], d_src[0])
    c, si = s * np.cos(ang), s * np.sin(ang)
    M = np.float32([[c, -si, 0], [si, c, 0]]); M[:, 2] = dst[0] - M[:, :2] @ src[0]
    warped = cv2.warpAffine(img, M, (out_w, out_h), flags=cv2.INTER_CUBIC if s > 1 else cv2.INTER_AREA,
                            borderMode=cv2.BORDER_REPLICATE)
    a = OVAL_FILL * out_w / 2.0; b = a * OVAL_HALF_HEIGHT_IPD / OVAL_HALF_WIDTH_IPD
    yy, xx = np.mgrid[0:out_h, 0:out_w]
    t = (yy - cy) / b                                       # -1 at the top of the oval, +1 at the bottom
    r = np.sqrt(((xx - out_w / 2.0) / (a * (1.0 - OVAL_TAPER * np.clip(t, -1, 1)))) ** 2 + t ** 2)
    feather = FEATHER_FRACTION * out_w / a
    alpha = np.clip((1.0 - r) / feather + 0.5, 0, 1)        # 1 inside, soft edge, 0 outside
    return warped, alpha, dict(ipd_src_px=float(np.hypot(*d_src)), roll_deg=float(-np.degrees(ang)), scale=float(s))


def lab_stats(bgr, alpha):
    L = cv2.cvtColor(bgr, cv2.COLOR_BGR2LAB)[:, :, 0].astype(float) * 100.0 / 255.0
    w = alpha / alpha.sum(); m = float((L * w).sum()); sd = float(np.sqrt((((L - m) ** 2) * w).sum()))
    return m, sd


def match_luminance(bgr, alpha, target_mean, target_sd, strength):
    """Shift/scale CIELAB lightness inside the oval towards the set average; colour (a*, b*) is untouched."""
    if strength <= 0: return bgr
    lab = cv2.cvtColor(bgr, cv2.COLOR_BGR2LAB).astype(float)
    m, sd = lab_stats(bgr, alpha); m255, sd255 = m * 2.55, sd * 2.55
    goal_m = (m + strength * (target_mean - m)) * 2.55; goal_sd = (sd + strength * (target_sd - sd)) * 2.55
    lab[:, :, 0] = np.clip((lab[:, :, 0] - m255) * (goal_sd / max(sd255, 1e-6)) + goal_m, 0, 255)
    return cv2.cvtColor(lab.astype(np.uint8), cv2.COLOR_LAB2BGR)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--raw", default=os.path.join(HERE, "faces_raw"))
    ap.add_argument("--out", default=os.path.join(HERE, P["faces"]["folder"]))
    ap.add_argument("--lum-match", choices=["within", "across", "none"], default="within", help="equalise lightness and contrast within each origin group (default), across all faces, or not at all")
    ap.add_argument("--strength", type=float, default=1.0, help="0..1, how far each face is moved towards the target (default 1)")
    ap.add_argument("--behavioral-per-origin", type=int, default=0, help="reserve this many faces per origin for the behavioural task (the rest go to the fMRI set)")
    ap.add_argument("--model", default=os.path.join(HERE, "_source", "models", "face_detection_yunet_2023mar.onnx"))
    a = ap.parse_args()
    out_w, out_h = P["faces"]["output_size_px"]; det = detector(a.model)
    os.makedirs(a.out, exist_ok=True)

    items, problems = [], []
    for origin in ORIGINS:
        files = sorted(f for ext in ("png", "jpg", "jpeg", "PNG", "JPG", "JPEG") for f in glob.glob(os.path.join(a.raw, origin, "*." + ext)))
        for f in files:
            img = cv2.imread(f, cv2.IMREAD_COLOR)
            if img is None: problems.append((f, "cannot read")); continue
            eyes = find_eyes(det, img)
            if eyes is None: problems.append((f, "no face found")); continue
            warped, alpha, q = align(img, eyes, out_w, out_h)
            items.append(dict(origin=origin, src=f, img=warped, alpha=alpha, **q))
    if not items: sys.exit("No usable images under %s/<ORIGIN>/ (ORIGIN = %s)" % (a.raw, ", ".join(ORIGINS)))

    stats = np.array([lab_stats(it["img"], it["alpha"]) for it in items])
    groups = np.array([it["origin"] for it in items])
    def target(origin):
        sel = np.ones(len(items), bool) if a.lum_match == "across" else groups == origin
        return stats[sel, 0].mean(), stats[sel, 1].mean()
    strength = 0.0 if a.lum_match == "none" else a.strength
    for old in glob.glob(os.path.join(a.out, "face_*.png")): os.remove(old)

    rows, counters = [], {o: 0 for o in ORIGINS}
    for it, (m0, sd0) in zip(items, stats):
        o = it["origin"]; counters[o] += 1; k = counters[o]
        img = match_luminance(it["img"], it["alpha"], *target(o), strength)
        m1, sd1 = lab_stats(img, it["alpha"])
        rgba = np.dstack([img, np.round(it["alpha"] * 255).astype(np.uint8)])
        name = "face_%s_%02d.png" % (o.lower(), k); cv2.imwrite(os.path.join(a.out, name), rgba)
        it["final"] = img
        rows.append(dict(face_id="%s_%02d" % (o, k), employer_origin=o, file=name,
                         set="behavioral" if k <= a.behavioral_per_origin else "fmri", sex=P["faces"]["sex"],
                         source_file=os.path.relpath(it["src"], HERE).replace(os.sep, "/"),
                         ipd_source_px=round(it["ipd_src_px"], 1), upscale_factor=round(it["scale"], 2), roll_corrected_deg=round(it["roll_deg"], 2),
                         lightness_before=round(m0, 1), contrast_before=round(sd0, 1), lightness_after=round(m1, 1), contrast_after=round(sd1, 1),
                         luminance_matching=a.lum_match, low_resolution=int(it["scale"] > 1.5), pretest_status="NOT PRE-TESTED"))
    inv = pd.DataFrame(rows); inv.to_csv(os.path.join(a.out, "face_inventory.csv"), index=False)

    # contact sheet on the task's card colour
    bg = np.array(P["display"]["card_rgb"][::-1], float); per_row = max(counters.values()); pad = 14
    sheet = np.full((len(ORIGINS) * (out_h + pad) + pad, per_row * (out_w + pad) + pad, 3), P["display"]["background_rgb"][0], np.uint8)
    pos = {o: 0 for o in ORIGINS}
    for it in items:
        r = ORIGINS.index(it["origin"]); c = pos[it["origin"]]; pos[it["origin"]] += 1
        y, x = pad + r * (out_h + pad), pad + c * (out_w + pad); al = it["alpha"][:, :, None]
        sheet[y:y + out_h, x:x + out_w] = np.round(it["final"] * al + bg * (1 - al)).astype(np.uint8)
    cv2.imwrite(os.path.join(a.out, "contact_sheet.png"), sheet)

    print("Wrote %d faces to %s" % (len(inv), a.out))
    print(inv.groupby(["employer_origin", "set"]).size().unstack(fill_value=0).reindex(ORIGINS).to_string())
    print("lightness (CIELAB L*, 0-100) before: %.1f-%.1f   after: %.1f-%.1f   | contrast before %.1f-%.1f  after %.1f-%.1f" % (
        inv.lightness_before.min(), inv.lightness_before.max(), inv.lightness_after.min(), inv.lightness_after.max(),
        inv.contrast_before.min(), inv.contrast_before.max(), inv.contrast_after.min(), inv.contrast_after.max()))
    if inv.low_resolution.any(): print("WARNING: %d image(s) had to be enlarged more than 1.5x (low-resolution source)." % inv.low_resolution.sum())
    need = P["faces"]["min_per_origin_for_task"]; fm = inv[inv.set == "fmri"].employer_origin.value_counts()
    for o in ORIGINS:
        if fm.get(o, 0) < need: print("WARNING: origin %s has %d fMRI-set face(s); the task needs at least %d." % (o, fm.get(o, 0), need))
    for f, why in problems: print("SKIPPED %s: %s" % (f, why))


if __name__ == "__main__":
    main()
