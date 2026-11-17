
# ==========================================
# STAGE 1 : BUILD
# ==========================================
FROM python:3.12-slim-trixie AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Mise à jour du système et outils de compilation
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
       gcc \
       libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Environnement Python isolé
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

# Mise à jour des outils Python
RUN pip install --upgrade pip setuptools wheel \
    && pip install -r requirements.txt


# ==========================================
# STAGE 2 : PRODUCTION
# ==========================================
FROM python:3.12-slim-trixie AS production

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# Mise à jour du système et installation
# des seules dépendances nécessaires
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
       libpq5 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Récupération de l'environnement Python
COPY --from=builder /opt/venv /opt/venv

# Utilisateur non privilégié
RUN groupadd --system appgroup \
    && useradd --system --gid appgroup --no-create-home appuser

COPY --chown=appuser:appgroup . /app

USER appuser

EXPOSE 4000

CMD ["python", "main.py"]
