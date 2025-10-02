FROM poldracklab/fmriprep:latest

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      nodejs npm python3-pip && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g bids-validator \
    && pip install --no-cache-dir boxsdk

# Leave a mount point for your scripts
VOLUME ["/usr/local/bin"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
