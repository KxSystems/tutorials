FROM nvidia/cuda:13.1.0-runtime-ubuntu24.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        groff \
        build-essential \
        python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Make venv the default Python in this image
ENV PATH="/venv/bin:$PATH"
    
RUN python3 -m venv /venv \
    && pip install --upgrade pip \
    && pip install jupyter matplotlib \
    && pip install --upgrade --pre pykx

ENV PATH="/app/.kx/bin:$PATH"
ENV QLIC="/app/.kx"
ENV QPATH="/app/.kx/mod"

ENTRYPOINT ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--allow-root", "--no-browser", "--ServerApp.token=''"]
CMD ["."]

WORKDIR /app/example
