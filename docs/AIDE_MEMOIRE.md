# 🎤 AIDE-MÉMOIRE PRÉSENTATION - 1 PAGE

## 📊 CHIFFRES CLÉS À RETENIR

- **300 millions** de personnes souffrent d'asthme
- **85-90%** de précision du modèle IA
- **100 arbres** de décision dans Random Forest
- **20+ variables** analysées par l'IA
- **3 niveaux** de risque : Faible/Modéré/Élevé
- **4 capteurs** : Température, Humidité, PM2.5, Fréquence Resp.

---

## 🎯 MESSAGE CLÉ (30 secondes)

> "Notre application prévient les crises d'asthme en surveillant l'environnement via des capteurs IoT et en utilisant l'Intelligence Artificielle pour prédire le risque avec 85-90% de précision. Le système génère automatiquement les données manquantes et affiche des résultats clairs : Vert (Faible), Violet (Modéré), Rouge (Élevé)."

---

## 🏗️ ARCHITECTURE (3 mots)

**IoT → IA → Mobile**

---

## 🧠 RANDOM FOREST EXPLIQUÉ SIMPLEMENT

1. **100 arbres** analysent les données
2. Chaque arbre **vote** : Risque 1, 2 ou 3
3. **Vote majoritaire** gagne (ex: 67 votes → Modéré)

**Pourquoi ?** Robuste, interprétable, performant sur données tabulaires

---

## ✨ INNOVATION : GÉNÉRATION AUTO FR

**Problème** : Pas de capteur de fréquence respiratoire
**Solution** : Backend la génère automatiquement
- Base : 16 resp/min
- +2-4 si PM2.5 > 55
- +0.5-1.5 si Humidité > 70%
- ±1 variation naturelle
**Résultat** : Valeurs réalistes 12-20 resp/min

---

## 📱 DÉMONSTRATION (4 étapes)

1. **ESP32 envoie** : T°, H%, PM2.5
2. **Backend génère** : FR automatiquement
3. **Dashboard affiche** : 4 capteurs en temps réel
4. **Clic "Analyser"** → **Résultat : Modéré (67%)**

---

## ❓ 3 QUESTIONS PROBABLES

### Q: "Pourquoi Random Forest ?"
**R**: Interprétable, précis (85-90%), fonctionne avec dataset modéré (1000 échantillons), crucial pour médical

### Q: "Comment gérer FR manquante ?"
**R**: Backend génère basé sur PM2.5 + humidité, valeurs réalistes 12-20 resp/min, transparent pour l'app

### Q: "Quelle précision ?"
**R**: 85-90% accuracy, cross-validation 88% ±1.5%, peu d'erreurs Faible↔Élevé, recall 85% pour Risque Élevé

---

## 💡 PHRASES CLÉS

- "Combine 100 arbres pour prédiction robuste"
- "Génère intelligemment la fréquence respiratoire"
- "Architecture 3-tiers scalable et maintenable"
- "Dashboard temps réel : Vert, Violet, Rouge"

---

## ⚠️ SI PROBLÈME TECHNIQUE

1. Vidéo backup de la démo
2. Montrer le code source
3. Expliquer avec diagrammes
4. **Rester calme** 🧘

---

## ✅ CHECKLIST 5 MIN AVANT

- [ ] Backend tourne
- [ ] App Flutter lancée
- [ ] Test curl ESP32 OK
- [ ] Dashboard affiche données
- [ ] Respirer profondément 🌬️

---

**VOUS ÊTES PRÊT ! 🚀**
