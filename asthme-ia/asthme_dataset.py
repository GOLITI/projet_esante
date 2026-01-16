"""
Génération d'un dataset d'asthme avec les 4 VRAIS capteurs physiques
Capteurs: Humidité, Température ambiante, PM2.5, Fréquence respiratoire
"""
import pandas as pd
import numpy as np

# Charger le dataset original
df = pd.read_csv('data/asthma_detection_with_sensors.csv')

print(f"📊 Dataset original: {df.shape}")
print(f"Colonnes: {list(df.columns)}")

# Supprimer les anciennes colonnes de capteurs
df_new = df.drop(['AQI', 'Heart_Rate'], axis=1)

# Ajouter la nouvelle colonne: Fréquence Respiratoire
# Valeurs normales: 12-20 respirations/min
# Tachypnée (asthme): 20-30+ respirations/min
np.random.seed(42)

respiratory_rate = []
for asthma in df['Asthma']:
    if asthma == 1:  # Patient asthmatique
        # Fréquence plus élevée (18-28 respirations/min)
        rate = np.random.normal(22, 3)
    else:  # Patient sain
        # Fréquence normale (12-18 respirations/min)
        rate = np.random.normal(15, 2)
    
    # Limiter entre 8 et 35
    rate = np.clip(rate, 8, 35)
    respiratory_rate.append(round(rate, 1))

df_new['RespiratoryRate'] = respiratory_rate

# Réorganiser les colonnes
columns_order = [
    # Symptômes (7)
    'Tiredness', 'Dry-Cough', 'Difficulty-in-Breathing', 'Sore-Throat',
    'Pains', 'Nasal-Congestion', 'Runny-Nose',
    # Âge (5 catégories)
    'Age_0-9', 'Age_10-19', 'Age_20-24', 'Age_25-59', 'Age_60+',
    # Genre (2)
    'Gender_Female', 'Gender_Male',
    # Capteurs physiques (4)
    'Humidity', 'Temperature', 'PM25', 'RespiratoryRate',
    # Cible
    'Asthma'
]

df_final = df_new[columns_order]

# Sauvegarder
output_file = 'data/asthma_detection_final.csv'
df_final.to_csv(output_file, index=False)

print(f"\n✅ Nouveau dataset créé: {output_file}")
print(f"📊 Shape: {df_final.shape}")
print(f"\n📋 Colonnes finales:")
print(df_final.columns.tolist())

print(f"\n📈 Statistiques Fréquence Respiratoire:")
print(df_final.groupby('Asthma')['RespiratoryRate'].describe())

print(f"\n🎯 Distribution:")
print(df_final['Asthma'].value_counts())

print("\n✅ Dataset prêt pour l'entraînement !")
