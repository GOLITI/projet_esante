"""
Analyse ROC pour déterminer le seuil optimal de détection critique
"""
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import roc_curve, auc, confusion_matrix, classification_report
from model import AsthmaPredictor
import pandas as pd

def find_optimal_threshold():
    """
    Trouve le seuil optimal en utilisant la courbe ROC
    
    Méthode:
    1. Entraîner le modèle
    2. Calculer sensibilité/spécificité pour différents seuils
    3. Tracer la courbe ROC
    4. Choisir le seuil optimal (maximise sensibilité, faux positifs acceptables)
    """
    
    print("="*70)
    print("ANALYSE ROC - DÉTERMINATION DU SEUIL OPTIMAL")
    print("="*70)
    
    # 1. Charger le modèle entraîné
    print("\n1️⃣ Chargement du modèle...")
    predictor = AsthmaPredictor(model_path='models/asthma_model.pkl')
    
    # Charger les données
    X, y = predictor.load_data('data/asthma_detection_final.csv')
    
    # Split train/test (même que l'entraînement)
    from sklearn.model_selection import train_test_split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    # Charger le modèle
    predictor.load_model()
    print(f"   ✅ Modèle chargé: {predictor.model_path}")
    
    # 2. Obtenir les probabilités pour la classe 3 (Élevé)
    print("\n2️⃣ Calcul des probabilités...")
    y_proba = predictor.model.predict_proba(X_test)
    
    # Probabilités pour chaque classe
    proba_classe_1 = y_proba[:, 0]  # Faible
    proba_classe_2 = y_proba[:, 1]  # Modéré
    proba_classe_3 = y_proba[:, 2]  # Élevé
    
    print(f"   ✅ Probabilités calculées pour {len(X_test)} patients")
    
    # 3. Analyse ROC pour la classe 3 (Élevé) - One-vs-Rest
    print("\n3️⃣ Analyse ROC pour la classe ÉLEVÉ (critique)...")
    
    # Transformer y_test en binaire: 1 si classe 3, 0 sinon
    y_test_binary = (y_test == 3).astype(int)
    
    # Calculer la courbe ROC
    fpr, tpr, thresholds = roc_curve(y_test_binary, proba_classe_3)
    roc_auc = auc(fpr, tpr)
    
    print(f"   ✅ AUC (Area Under Curve): {roc_auc:.4f}")
    
    # 4. Trouver le seuil optimal
    print("\n4️⃣ Recherche du seuil optimal...")
    
    # Méthode 1: Indice de Youden (maximise sensibilité + spécificité)
    youden_index = tpr - fpr
    optimal_idx_youden = np.argmax(youden_index)
    optimal_threshold_youden = thresholds[optimal_idx_youden]
    
    print(f"\n   📊 Méthode 1 - Indice de Youden (équilibre sensibilité/spécificité):")
    print(f"      Seuil optimal: {optimal_threshold_youden:.4f}")
    print(f"      Sensibilité (Recall): {tpr[optimal_idx_youden]:.4f}")
    print(f"      Spécificité: {1 - fpr[optimal_idx_youden]:.4f}")
    print(f"      Indice de Youden: {youden_index[optimal_idx_youden]:.4f}")
    
    # Méthode 2: Maximiser sensibilité avec faux positifs < 15%
    print(f"\n   📊 Méthode 2 - Priorité MÉDICALE (sensibilité max, FPR < 15%):")
    
    # Trouver les seuils où FPR < 0.15 (moins de 15% de faux positifs)
    medical_constraint = fpr < 0.15
    if np.any(medical_constraint):
        # Parmi ces seuils, choisir celui qui maximise la sensibilité
        valid_indices = np.where(medical_constraint)[0]
        optimal_idx_medical = valid_indices[np.argmax(tpr[medical_constraint])]
        optimal_threshold_medical = thresholds[optimal_idx_medical]
        
        print(f"      Seuil optimal: {optimal_threshold_medical:.4f}")
        print(f"      Sensibilité (Recall): {tpr[optimal_idx_medical]:.4f}")
        print(f"      Spécificité: {1 - fpr[optimal_idx_medical]:.4f}")
        print(f"      Taux de faux positifs: {fpr[optimal_idx_medical]:.4f}")
    else:
        print(f"      ⚠️ Aucun seuil ne satisfait FPR < 15%")
        optimal_threshold_medical = optimal_threshold_youden
    
    # Méthode 3: Maximiser sensibilité avec faux positifs < 20%
    print(f"\n   📊 Méthode 3 - Compromis (sensibilité max, FPR < 20%):")
    
    medical_constraint_20 = fpr < 0.20
    if np.any(medical_constraint_20):
        valid_indices = np.where(medical_constraint_20)[0]
        optimal_idx_compromise = valid_indices[np.argmax(tpr[medical_constraint_20])]
        optimal_threshold_compromise = thresholds[optimal_idx_compromise]
        
        print(f"      Seuil optimal: {optimal_threshold_compromise:.4f}")
        print(f"      Sensibilité (Recall): {tpr[optimal_idx_compromise]:.4f}")
        print(f"      Spécificité: {1 - fpr[optimal_idx_compromise]:.4f}")
        print(f"      Taux de faux positifs: {fpr[optimal_idx_compromise]:.4f}")
    else:
        optimal_threshold_compromise = optimal_threshold_youden
    
    # 5. Tester différents seuils
    print("\n5️⃣ Comparaison de différents seuils:")
    print(f"\n{'Seuil':<10} {'Sensibilité':<15} {'Spécificité':<15} {'FPR':<10} {'VP':<8} {'FP':<8} {'FN':<8}")
    print("-" * 90)
    
    test_thresholds = [0.50, 0.55, 0.60, 0.65, 0.70, 
                       optimal_threshold_youden, 
                       optimal_threshold_medical if optimal_threshold_medical != optimal_threshold_youden else None,
                       optimal_threshold_compromise if optimal_threshold_compromise != optimal_threshold_youden else None]
    
    test_thresholds = [t for t in test_thresholds if t is not None]
    test_thresholds = sorted(list(set(test_thresholds)))  # Enlever doublons et trier
    
    results = []
    for threshold in test_thresholds:
        # Appliquer le seuil
        y_pred_threshold = (proba_classe_3 >= threshold).astype(int)
        
        # Calculer les métriques
        tn, fp, fn, tp = confusion_matrix(y_test_binary, y_pred_threshold).ravel()
        sensitivity = tp / (tp + fn) if (tp + fn) > 0 else 0
        specificity = tn / (tn + fp) if (tn + fp) > 0 else 0
        fpr_rate = fp / (fp + tn) if (fp + tn) > 0 else 0
        
        results.append({
            'threshold': threshold,
            'sensitivity': sensitivity,
            'specificity': specificity,
            'fpr': fpr_rate,
            'tp': tp,
            'fp': fp,
            'fn': fn
        })
        
        marker = ""
        if abs(threshold - optimal_threshold_youden) < 0.01:
            marker = "← Youden"
        elif abs(threshold - optimal_threshold_medical) < 0.01:
            marker = "← Médical"
        elif abs(threshold - optimal_threshold_compromise) < 0.01:
            marker = "← Compromis"
        elif abs(threshold - 0.65) < 0.01:
            marker = "← ACTUEL"
        
        print(f"{threshold:.4f}    {sensitivity:.4f} ({sensitivity*100:5.1f}%)  {specificity:.4f} ({specificity*100:5.1f}%)  {fpr_rate:.4f}   {tp:4d}    {fp:4d}    {fn:4d}  {marker}")
    
    # 6. Visualisation
    print("\n6️⃣ Génération de la courbe ROC...")
    
    plt.figure(figsize=(12, 5))
    
    # Subplot 1: Courbe ROC
    plt.subplot(1, 2, 1)
    plt.plot(fpr, tpr, color='darkorange', lw=2, label=f'ROC curve (AUC = {roc_auc:.4f})')
    plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--', label='Chance (AUC = 0.50)')
    
    # Marquer les seuils intéressants
    plt.plot(fpr[optimal_idx_youden], tpr[optimal_idx_youden], 'ro', markersize=10, label=f'Youden ({optimal_threshold_youden:.3f})')
    if optimal_threshold_medical != optimal_threshold_youden:
        plt.plot(fpr[optimal_idx_medical], tpr[optimal_idx_medical], 'go', markersize=10, label=f'Médical ({optimal_threshold_medical:.3f})')
    if optimal_threshold_compromise != optimal_threshold_youden:
        plt.plot(fpr[optimal_idx_compromise], tpr[optimal_idx_compromise], 'bo', markersize=10, label=f'Compromis ({optimal_threshold_compromise:.3f})')
    
    # Marquer le seuil actuel (0.65)
    idx_065 = np.argmin(np.abs(thresholds - 0.65))
    plt.plot(fpr[idx_065], tpr[idx_065], 'ms', markersize=10, label=f'Actuel 0.65')
    
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('Taux de Faux Positifs (1 - Spécificité)', fontsize=12)
    plt.ylabel('Taux de Vrais Positifs (Sensibilité)', fontsize=12)
    plt.title('Courbe ROC - Classe ÉLEVÉ', fontsize=14, fontweight='bold')
    plt.legend(loc="lower right")
    plt.grid(True, alpha=0.3)
    
    # Subplot 2: Sensibilité vs Seuil
    plt.subplot(1, 2, 2)
    plt.plot(thresholds, tpr, label='Sensibilité (Recall)', color='green', lw=2)
    plt.plot(thresholds, 1 - fpr, label='Spécificité', color='blue', lw=2)
    
    plt.axvline(x=optimal_threshold_youden, color='red', linestyle='--', label=f'Youden: {optimal_threshold_youden:.3f}')
    if optimal_threshold_medical != optimal_threshold_youden:
        plt.axvline(x=optimal_threshold_medical, color='green', linestyle='--', label=f'Médical: {optimal_threshold_medical:.3f}')
    plt.axvline(x=0.65, color='magenta', linestyle='--', label='Actuel: 0.65')
    
    plt.xlabel('Seuil de Probabilité', fontsize=12)
    plt.ylabel('Score', fontsize=12)
    plt.title('Sensibilité et Spécificité vs Seuil', fontsize=14, fontweight='bold')
    plt.legend(loc="best")
    plt.grid(True, alpha=0.3)
    plt.xlim([0.3, 1.0])
    
    plt.tight_layout()
    plt.savefig('visualizations/roc_analysis_threshold.png', dpi=300, bbox_inches='tight')
    print(f"   ✅ Graphique sauvegardé: visualizations/roc_analysis_threshold.png")
    
    # 7. Recommandation finale
    print("\n" + "="*70)
    print("📊 RECOMMANDATION FINALE")
    print("="*70)
    
    print(f"\n🎯 Seuil optimal selon Youden: {optimal_threshold_youden:.4f}")
    print(f"   - Équilibre mathématique parfait sensibilité/spécificité")
    print(f"   - Sensibilité: {tpr[optimal_idx_youden]:.4f} ({tpr[optimal_idx_youden]*100:.1f}%)")
    print(f"   - Spécificité: {1-fpr[optimal_idx_youden]:.4f} ({(1-fpr[optimal_idx_youden])*100:.1f}%)")
    
    if optimal_threshold_medical != optimal_threshold_youden:
        print(f"\n🏥 Seuil optimal MÉDICAL: {optimal_threshold_medical:.4f}")
        print(f"   - Maximise sensibilité avec FPR < 15%")
        print(f"   - Sensibilité: {tpr[optimal_idx_medical]:.4f} ({tpr[optimal_idx_medical]*100:.1f}%)")
        print(f"   - Taux faux positifs: {fpr[optimal_idx_medical]:.4f} ({fpr[optimal_idx_medical]*100:.1f}%)")
        print(f"   - ✅ RECOMMANDÉ pour application médicale")
    
    print(f"\n⚖️ Seuil actuel (0.65): ")
    idx_065 = np.argmin(np.abs(thresholds - 0.65))
    print(f"   - Sensibilité: {tpr[idx_065]:.4f} ({tpr[idx_065]*100:.1f}%)")
    print(f"   - Spécificité: {1-fpr[idx_065]:.4f} ({(1-fpr[idx_065])*100:.1f}%)")
    print(f"   - Taux faux positifs: {fpr[idx_065]:.4f} ({fpr[idx_065]*100:.1f}%)")
    
    # Conclusion
    print("\n" + "="*70)
    print("💡 CONCLUSION")
    print("="*70)
    
    # Choisir le meilleur seuil
    if optimal_threshold_medical != optimal_threshold_youden:
        recommended_threshold = optimal_threshold_medical
        print(f"\n✅ Seuil recommandé: {recommended_threshold:.4f}")
        print(f"   Raison: Maximise la sensibilité (détection cas graves)")
        print(f"           tout en maintenant un taux de faux positifs acceptable (<15%)")
    else:
        recommended_threshold = optimal_threshold_youden
        print(f"\n✅ Seuil recommandé: {recommended_threshold:.4f}")
        print(f"   Raison: Équilibre optimal entre sensibilité et spécificité")
    
    # Comparaison avec 0.65
    if abs(recommended_threshold - 0.65) < 0.05:
        print(f"\n✅ Le seuil actuel (0.65) est PROCHE du seuil optimal!")
        print(f"   Différence: {abs(recommended_threshold - 0.65):.4f}")
        print(f"   👍 Pas de changement nécessaire")
    else:
        print(f"\n⚠️ Le seuil actuel (0.65) pourrait être optimisé")
        print(f"   Différence avec optimal: {abs(recommended_threshold - 0.65):.4f}")
        print(f"   💡 Considérer l'utilisation de {recommended_threshold:.4f}")
    
    print("\n" + "="*70)
    
    return {
        'optimal_youden': optimal_threshold_youden,
        'optimal_medical': optimal_threshold_medical,
        'optimal_compromise': optimal_threshold_compromise,
        'recommended': recommended_threshold,
        'current': 0.65,
        'roc_auc': roc_auc,
        'results': results
    }

if __name__ == '__main__':
    import os
    os.makedirs('visualizations', exist_ok=True)
    analysis = find_optimal_threshold()
    
    print("\n✅ Analyse ROC terminée!")
    print(f"   Graphique disponible: visualizations/roc_analysis_threshold.png")
