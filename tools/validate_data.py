# -*- coding: utf-8 -*-
"""Validates case data: references, reachability (no dead ends), assets. Exit code 1 on any error."""
import json, glob, os, sys

errors = []
def err(msg): errors.append(msg); print("ERROR:", msg)

files = sorted(glob.glob("data/cases/case_*.json"))
if len(files) < 8: err(f"need at least 8 cases, found {len(files)}")
ids = set()
for fp in files:
    c = json.load(open(fp, encoding="utf-8"))
    cid = c["id"]
    if cid in ids: err(f"{fp}: duplicate id")
    ids.add(cid)
    for k in ("title", "bg", "intro", "places", "people", "evidence", "links", "culprit", "hints", "win"):
        if k not in c: err(f"{cid}: missing {k}")
    if len(c["hints"]) != 3: err(f"{cid}: needs 3 hints")
    if not os.path.exists(f"assets/backgrounds/{c['bg']}.jpg"): err(f"{cid}: missing bg {c['bg']}")
    names = set(); obtainable = {}  # ev -> list of needs
    for pl in c["places"]:
        if not os.path.exists(f"assets/backgrounds/{pl['bg']}.jpg"): err(f"{cid}: missing place bg {pl['bg']}")
        for it in pl["items"]:
            if it["name"] in names: err(f"{cid}: duplicate item name {it['name']}")
            names.add(it["name"])
            if it["ev"]: obtainable.setdefault(it["ev"], []).append("")
    pids = [p["id"] for p in c["people"]]
    if len(set(pids)) != len(pids): err(f"{cid}: duplicate person ids")
    if c["culprit"] not in pids: err(f"{cid}: culprit not among people")
    for p in c["people"]:
        if p["id"] != c["culprit"] and len(p["defense"]) < 20: err(f"{cid}/{p['id']}: needs a defense text")
        for q in p["asks"]:
            if q["ev"]: obtainable.setdefault(q["ev"], []).append(q["need"])
    for eid in c["evidence"]:
        if eid not in obtainable: err(f"{cid}: evidence {eid} can never be collected")
    for eid in obtainable:
        if eid not in c["evidence"]: err(f"{cid}: item/question references unknown evidence {eid}")
    # reachability simulation: iterate until fixpoint, no dead ends
    have = set()
    changed = True
    for p in c["people"]:
        for q in p["asks"]:
            if q["need"] and q["need"] not in c["evidence"]: err(f"{cid}: unknown need {q['need']}")
    while changed:
        changed = False
        for pl in c["places"]:
            for it in pl["items"]:
                if it["ev"] and it["ev"] not in have: have.add(it["ev"]); changed = True
        for p in c["people"]:
            for q in p["asks"]:
                if q["ev"] and q["ev"] not in have and (not q["need"] or q["need"] in have): have.add(q["ev"]); changed = True
    for eid in c["evidence"]:
        if eid not in have: err(f"{cid}: evidence {eid} unreachable (locked by circular need)")
    if len(c["links"]) < 2: err(f"{cid}: needs at least 2 links")
    for l in c["links"]:
        for k in ("a", "b"):
            if l[k] not in c["evidence"]: err(f"{cid}: link references unknown {l[k]}")
    print(f"{cid}: {len(c['evidence'])} evidence, {len(c['links'])} links, {len(c['people'])} people, {sum(len(p['asks']) for p in c['people'])} questions OK")
sys.exit(1 if errors else 0)
