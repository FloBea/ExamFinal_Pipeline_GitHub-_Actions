# 1. Image de base imposée (Version légère et stable)
FROM python:3.11-slim-bookworm

# 2. Variables d'environnement pour Python
# Empêche la création de fichiers .pyc (gain de place)
# Force l'affichage immédiat des logs (crucial pour le débug Docker)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 3. Répertoire de travail
WORKDIR /app

# 4. Installation des dépendances système (si nécessaire pour gunicorn/redis)
# On nettoie le cache apt juste après pour réduire la taille de l'image
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 5. Optimisation des couches (Layers)
# On copie et installe les requirements AVANT le reste du code. 
# Si tu modifies ton code, Docker ne réinstallera pas tout (gain de temps au build).
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 6. Copie du code source
COPY . .

# 7. Sécurité : Principe du moindre privilège (DevSecOps)
# On crée un utilisateur système pour ne pas lancer l'app en ROOT
RUN useradd -m taskuser && \
    chown -R taskuser:taskuser /app
USER taskuser

# 8. Exposition du port
EXPOSE 5000

# 9. Lancement de l'application
# On utilise gunicorn (présent dans requirements.txt) plutôt que le serveur de dev Flask
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
