# docker/fmriprep-wrapper/Dockerfile
FROM nipreps/fmriprep:24.1.1          # includes FreeSurfer + TemplateFlow client

RUN apt-get update && \
    apt-get install -y --no-install-recommends git jq && \
    rm -rf /var/lib/apt/lists/*

# Optional: pre-fetch templates into the image (skip if you prefer a lean image)
ENV TEMPLATEFLOW_HOME=/opt/templateflow
RUN mkdir -p $TEMPLATEFLOW_HOME && \
    python - <<'PY'
import templateflow.api as tf
for t in ("OASIS30ANTs", "MNI152NLin2009cAsym", "fsaverage"):
    tf.get(template=t, resolution=1)
PY

# --- placeholder launcher so the image builds ---
RUN printf '#!/usr/bin/env python3\nprint("Bind-mount real launcher at run-time")\n' > /launcher.py
RUN chmod +x /launcher.py

WORKDIR /work
ENTRYPOINT ["python", "/launcher.py"]
