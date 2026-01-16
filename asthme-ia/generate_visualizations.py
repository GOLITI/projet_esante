"""
Script pour générer des visualisations des résultats du modèle
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import confusion_matrix, classification_report, roc_curve, auc
from sklearn.preprocessing import label_binarize
from model import AsthmaPredictor
import os

# Configuration style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 8)
plt.rcParams['font.size'] = 10

def create_output_dir():
    """Créer le dossier pour les visualisations"""
    os.makedirs('visualizations', exist_ok=True)

def plot_confusion_matrix(y_test, y_pred, classes, save_path):
    """Génère la matrice de confusion"""
    cm = confusion_matrix(y_test, y_pred)
    
    plt.figure(figsize=(10, 8))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=classes, yticklabels=classes,
                cbar_kws={'label': 'Nombre de prédictions'})
    plt.title('Matrice de Confusion - Modèle Random Forest', fontsize=16, fontweight='bold')
    plt.ylabel('Classe Réelle', fontsize=12)
    plt.xlabel('Classe Prédite', fontsize=12)
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"✓ Matrice de confusion sauvegardée: {save_path}")

def plot_feature_importance(predictor, save_path):
    """Génère le graphique d'importance des features"""
    importance_df = predictor.get_feature_importance()
    
    # Top 15 features
    top_features = importance_df.head(15)
    
    plt.figure(figsize=(12, 8))
    colors = ['#2ecc71' if 'Temperature' in f or 'Humidity' in f or 'PM25' in f or 'AQI' in f or 'Heart_Rate' in f 
              else '#3498db' if 'Difficulty' in f or 'Cough' in f or 'Congestion' in f or 'Throat' in f or 'Tiredness' in f
              else '#e74c3c' 
              for f in top_features['feature']]
    
    bars = plt.barh(range(len(top_features)), top_features['importance'], color=colors, edgecolor='black', linewidth=0.5)
    plt.yticks(range(len(top_features)), top_features['feature'])
    plt.xlabel('Importance', fontsize=12, fontweight='bold')
    plt.ylabel('Feature', fontsize=12, fontweight='bold')
    plt.title('Top 15 Features - Importance dans le Modèle', fontsize=16, fontweight='bold')
    plt.gca().invert_yaxis()
    
    # Ajouter les valeurs sur les barres
    for i, (idx, row) in enumerate(top_features.iterrows()):
        plt.text(row['importance'], i, f"  {row['importance']:.3f}", 
                va='center', fontsize=9, fontweight='bold')
    
    # Légende
    from matplotlib.patches import Patch
    legend_elements = [
        Patch(facecolor='#2ecc71', label='Capteurs', edgecolor='black'),
        Patch(facecolor='#3498db', label='Symptômes', edgecolor='black'),
        Patch(facecolor='#e74c3c', label='Démographie', edgecolor='black')
    ]
    plt.legend(handles=legend_elements, loc='lower right', fontsize=10)
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"✓ Importance des features sauvegardée: {save_path}")

def plot_category_contribution(predictor, save_path):
    """Génère le graphique de contribution par catégorie"""
    importance_df = predictor.get_feature_importance()
    
    # Catégoriser les features
    categories = {
        'Capteurs\nEnvironnementaux': ['PM25', 'AQI', 'Humidity'],
        'Capteurs\nPhysiologiques': ['Temperature', 'Heart_Rate'],
        'Symptômes': ['Tiredness', 'Dry-Cough', 'Difficulty-in-Breathing', 'Sore-Throat', 
                     'Pains', 'Nasal-Congestion', 'Runny-Nose'],
        'Démographie': ['Age_0-9', 'Age_10-19', 'Age_20-24', 'Age_25-59', 'Age_60+', 
                       'Gender_Female', 'Gender_Male']
    }
    
    contributions = {}
    for category, features in categories.items():
        total = importance_df[importance_df['feature'].isin(features)]['importance'].sum()
        contributions[category] = total * 100
    
    # Créer le graphique
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
    
    # Graphique en barres
    colors = ['#2ecc71', '#27ae60', '#3498db', '#e74c3c']
    bars = ax1.bar(contributions.keys(), contributions.values(), color=colors, edgecolor='black', linewidth=1.5)
    ax1.set_ylabel('Contribution (%)', fontsize=12, fontweight='bold')
    ax1.set_title('Contribution par Catégorie de Features', fontsize=14, fontweight='bold')
    ax1.set_ylim(0, 60)
    
    # Ajouter les valeurs sur les barres
    for bar in bars:
        height = bar.get_height()
        ax1.text(bar.get_x() + bar.get_width()/2., height,
                f'{height:.1f}%', ha='center', va='bottom', fontsize=11, fontweight='bold')
    
    ax1.tick_params(axis='x', rotation=15)
    ax1.grid(axis='y', alpha=0.3)
    
    # Graphique circulaire
    wedges, texts, autotexts = ax2.pie(contributions.values(), labels=contributions.keys(), 
                                         autopct='%1.1f%%', startangle=90, colors=colors,
                                         wedgeprops={'edgecolor': 'black', 'linewidth': 1.5})
    ax2.set_title('Distribution de l\'Importance', fontsize=14, fontweight='bold')
    
    # Améliorer le style du pie chart
    for autotext in autotexts:
        autotext.set_color('white')
        autotext.set_fontsize(11)
        autotext.set_fontweight('bold')
    
    for text in texts:
        text.set_fontsize(10)
        text.set_fontweight('bold')
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"✓ Contribution par catégorie sauvegardée: {save_path}")

def plot_performance_metrics(y_test, y_pred, classes, save_path):
    """Génère le graphique des métriques de performance par classe"""
    from sklearn.metrics import precision_score, recall_score, f1_score
    
    # Calculer les métriques pour chaque classe
    precision = precision_score(y_test, y_pred, average=None)
    recall = recall_score(y_test, y_pred, average=None)
    f1 = f1_score(y_test, y_pred, average=None)
    
    x = np.arange(len(classes))
    width = 0.25
    
    fig, ax = plt.subplots(figsize=(12, 7))
    bars1 = ax.bar(x - width, precision, width, label='Precision', color='#3498db', edgecolor='black', linewidth=1)
    bars2 = ax.bar(x, recall, width, label='Recall', color='#2ecc71', edgecolor='black', linewidth=1)
    bars3 = ax.bar(x + width, f1, width, label='F1-Score', color='#e74c3c', edgecolor='black', linewidth=1)
    
    ax.set_xlabel('Niveau de Risque', fontsize=12, fontweight='bold')
    ax.set_ylabel('Score', fontsize=12, fontweight='bold')
    ax.set_title('Métriques de Performance par Classe', fontsize=16, fontweight='bold')
    ax.set_xticks(x)
    ax.set_xticklabels(classes)
    ax.legend(fontsize=11)
    ax.set_ylim(0, 1.1)
    ax.grid(axis='y', alpha=0.3)
    
    # Ajouter les valeurs sur les barres
    for bars in [bars1, bars2, bars3]:
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{height:.2f}', ha='center', va='bottom', fontsize=9, fontweight='bold')
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"✓ Métriques de performance sauvegardées: {save_path}")

def plot_roc_curves(X_test, y_test, predictor, classes, save_path):
    """Génère les courbes ROC pour chaque classe"""
    # Binariser les labels pour ROC multiclasse
    y_test_bin = label_binarize(y_test, classes=predictor.model.classes_)
    n_classes = len(predictor.model.classes_)
    
    # Obtenir les probabilités
    y_score = predictor.model.predict_proba(X_test)
    
    # Calculer ROC curve et AUC pour chaque classe
    fpr = dict()
    tpr = dict()
    roc_auc = dict()
    
    for i in range(n_classes):
        fpr[i], tpr[i], _ = roc_curve(y_test_bin[:, i], y_score[:, i])
        roc_auc[i] = auc(fpr[i], tpr[i])
    
    # Tracer les courbes
    plt.figure(figsize=(10, 8))
    colors = ['#3498db', '#2ecc71', '#e74c3c']
    
    for i, color, label in zip(range(n_classes), colors, classes):
        plt.plot(fpr[i], tpr[i], color=color, lw=2.5,
                label=f'{label} (AUC = {roc_auc[i]:.3f})')
    
    plt.plot([0, 1], [0, 1], 'k--', lw=2, label='Aléatoire (AUC = 0.5)')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('Taux de Faux Positifs', fontsize=12, fontweight='bold')
    plt.ylabel('Taux de Vrais Positifs', fontsize=12, fontweight='bold')
    plt.title('Courbes ROC - Classification Multi-Classe', fontsize=16, fontweight='bold')
    plt.legend(loc="lower right", fontsize=11)
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"✓ Courbes ROC sauvegardées: {save_path}")

def plot_class_distribution(y_train, y_test, classes, save_path):
    """Génère le graphique de distribution des classes"""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
    
    # Distribution train
    train_counts = pd.Series(y_train).value_counts().sort_index()
    colors = ['#3498db', '#2ecc71', '#e74c3c']
    bars1 = ax1.bar(range(len(train_counts)), train_counts.values, color=colors, edgecolor='black', linewidth=1.5)
    ax1.set_xticks(range(len(train_counts)))
    ax1.set_xticklabels([classes[i-1] for i in train_counts.index])
    ax1.set_ylabel('Nombre d\'échantillons', fontsize=12, fontweight='bold')
    ax1.set_title('Distribution - Ensemble d\'Entraînement', fontsize=14, fontweight='bold')
    ax1.grid(axis='y', alpha=0.3)
    
    for bar in bars1:
        height = bar.get_height()
        ax1.text(bar.get_x() + bar.get_width()/2., height,
                f'{int(height)}', ha='center', va='bottom', fontsize=11, fontweight='bold')
    
    # Distribution test
    test_counts = pd.Series(y_test).value_counts().sort_index()
    bars2 = ax2.bar(range(len(test_counts)), test_counts.values, color=colors, edgecolor='black', linewidth=1.5)
    ax2.set_xticks(range(len(test_counts)))
    ax2.set_xticklabels([classes[i-1] for i in test_counts.index])
    ax2.set_ylabel('Nombre d\'échantillons', fontsize=12, fontweight='bold')
    ax2.set_title('Distribution - Ensemble de Test', fontsize=14, fontweight='bold')
    ax2.grid(axis='y', alpha=0.3)
    
    for bar in bars2:
        height = bar.get_height()
        ax2.text(bar.get_x() + bar.get_width()/2., height,
                f'{int(height)}', ha='center', va='bottom', fontsize=11, fontweight='bold')
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"✓ Distribution des classes sauvegardée: {save_path}")

def main():
    """Fonction principale"""
    print("="*60)
    print("GÉNÉRATION DES VISUALISATIONS DES RÉSULTATS")
    print("="*60)
    
    # Créer le dossier de sortie
    create_output_dir()
    
    # Charger le modèle
    print("\nChargement du modèle...")
    predictor = AsthmaPredictor(model_path='models/asthma_model.pkl')
    predictor.load_model()
    
    # Charger les données
    print("Chargement des données...")
    from sklearn.model_selection import train_test_split
    X, y = predictor.load_data('data/asthma_detection_with_sensors.csv')
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
    
    # Faire les prédictions
    print("Génération des prédictions...")
    y_pred = predictor.model.predict(X_test)
    
    classes = ['Faible', 'Modéré', 'Élevé']
    
    print("\n" + "="*60)
    print("GÉNÉRATION DES GRAPHIQUES")
    print("="*60 + "\n")
    
    # 1. Matrice de confusion
    plot_confusion_matrix(y_test, y_pred, classes, 'visualizations/1_confusion_matrix.png')
    
    # 2. Importance des features
    plot_feature_importance(predictor, 'visualizations/2_feature_importance.png')
    
    # 3. Contribution par catégorie
    plot_category_contribution(predictor, 'visualizations/3_category_contribution.png')
    
    # 4. Métriques de performance
    plot_performance_metrics(y_test, y_pred, classes, 'visualizations/4_performance_metrics.png')
    
    # 5. Courbes ROC
    plot_roc_curves(X_test, y_test, predictor, classes, 'visualizations/5_roc_curves.png')
    
    # 6. Distribution des classes
    plot_class_distribution(y_train, y_test, classes, 'visualizations/6_class_distribution.png')
    
    print("\n" + "="*60)
    print("✅ TOUTES LES VISUALISATIONS ONT ÉTÉ GÉNÉRÉES!")
    print("="*60)
    print("\nFichiers créés dans le dossier 'visualizations/':")
    print("  1. 1_confusion_matrix.png - Matrice de confusion")
    print("  2. 2_feature_importance.png - Top 15 features importantes")
    print("  3. 3_category_contribution.png - Contribution par catégorie")
    print("  4. 4_performance_metrics.png - Precision, Recall, F1-Score")
    print("  5. 5_roc_curves.png - Courbes ROC multi-classe")
    print("  6. 6_class_distribution.png - Distribution train/test")
    print("\n" + "="*60)

if __name__ == '__main__':
    main()
