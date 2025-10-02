from mne_bids import BIDSPath, read_raw_bids
import mne
from pathlib import Path

bids_root = Path(r"C:\Users\hz3752\Box\EEG-FMRI\Data\fingertapping\rawdata")  # folder that contains sub-0665/
bpath = BIDSPath(root=bids_root,
                 subject="0665", session="01",
                 task="fingertapping",
                 run="1", datatype="eeg")

raw = read_raw_bids(bids_path=bpath, verbose=True)

# Events: prefer BIDS events.tsv when using mne-bids
events, event_id = mne.events_from_annotations(raw)
print(event_id)