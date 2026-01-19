#!/usr/bin/env python3
"""
Script de test pour vérifier que le backend Flask fonctionne correctement
"""
import requests
import json

BACKEND_URL = "http://192.168.137.174:5000"

def test_health():
    """Test de l'endpoint /health"""
    print("\n🧪 Test 1: Endpoint /health")
    print("-" * 50)
    try:
        response = requests.get(f"{BACKEND_URL}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Backend accessible")
            print(f"   Réponse: {response.json()}")
            return True
        else:
            print(f"❌ Erreur: Status code {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Erreur: {e}")
        print("💡 Vérifiez que le backend est démarré: python main.py")
        return False

def test_sensors_latest():
    """Test de l'endpoint /api/sensors/latest"""
    print("\n🧪 Test 2: Endpoint /api/sensors/latest")
    print("-" * 50)
    try:
        response = requests.get(f"{BACKEND_URL}/api/sensors/latest", timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Données capteurs disponibles:")
            print(f"   Humidité: {data['data']['humidity']}%")
            print(f"   Température: {data['data']['temperature']}°C")
            print(f"   PM2.5: {data['data']['pm25']} µg/m³")
            print(f"   Fréquence respiratoire: {data['data']['respiratoryRate']}/min")
            print(f"   Timestamp: {data['data']['timestamp']}")
            return True
        elif response.status_code == 404:
            print("⚠️  Aucune donnée capteur disponible")
            print("💡 L'ESP32 n'a pas encore envoyé de données")
            print("💡 Vous pouvez envoyer des données de test avec le Test 3")
            return True
        else:
            print(f"❌ Erreur: Status code {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

def test_push_sensor_data():
    """Test d'envoi de données capteurs"""
    print("\n🧪 Test 3: Envoi de données capteurs de test")
    print("-" * 50)
    
    test_data = {
        "temperature": 22.5,
        "humidity": 65.0,
        "pm25": 35.0
    }
    
    print(f"📤 Envoi de données: {test_data}")
    
    try:
        response = requests.post(
            f"{BACKEND_URL}/api/sensors",
            json=test_data,
            timeout=5
        )
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Données envoyées avec succès")
            print(f"   Réponse: {data['message']}")
            return True
        else:
            print(f"❌ Erreur: Status code {response.status_code}")
            print(f"   Message: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

def test_prediction():
    """Test de prédiction ML"""
    print("\n🧪 Test 4: Prédiction ML")
    print("-" * 50)
    
    test_request = {
        "symptoms": {
            "Coughing": 0,
            "Difficulty_Breathing": 0,
            "Wheezing": 0,
            "Chest_Tightness": 0,
            "Shortness_of_Breath": 0,
            "Night_Symptoms": 0,
            "Exercise_Induced": 0
        },
        "demographics": {
            "Age": 30,
            "Gender": 1
        },
        "sensors": {
            "Humidity": 65.0,
            "Temperature": 22.5,
            "PM25": 35.0,
            "RespiratoryRate": 0.0
        }
    }
    
    print(f"📤 Envoi de requête de prédiction...")
    
    try:
        response = requests.post(
            f"{BACKEND_URL}/api/predict",
            json=test_request,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            if data['success']:
                print("✅ Prédiction effectuée avec succès")
                print(f"   Niveau de risque: {data['risk_level']}")
                print(f"   Label: {data['risk_label']}")
                print(f"   Score: {data['risk_score']:.2%}")
                return True
            else:
                print(f"❌ Erreur: {data.get('error', 'Erreur inconnue')}")
                return False
        else:
            print(f"❌ Erreur: Status code {response.status_code}")
            print(f"   Message: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

def main():
    """Exécuter tous les tests"""
    print("╔" + "═" * 60 + "╗")
    print("║" + " " * 15 + "TEST BACKEND FLASK" + " " * 27 + "║")
    print("╚" + "═" * 60 + "╝")
    
    results = []
    
    # Test 1: Health check
    results.append(("Health Check", test_health()))
    
    # Test 2: Sensors latest
    results.append(("Sensors Latest", test_sensors_latest()))
    
    # Test 3: Push sensor data
    results.append(("Push Sensor Data", test_push_sensor_data()))
    
    # Test 4: Après avoir envoyé des données, re-tester /api/sensors/latest
    print("\n🧪 Test 5: Vérification des données après push")
    print("-" * 50)
    results.append(("Verify After Push", test_sensors_latest()))
    
    # Test 5: Prediction
    results.append(("ML Prediction", test_prediction()))
    
    # Résumé
    print("\n" + "=" * 62)
    print("📊 RÉSUMÉ DES TESTS")
    print("=" * 62)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status:10} | {test_name}")
    
    print("=" * 62)
    print(f"Résultat: {passed}/{total} tests réussis")
    
    if passed == total:
        print("\n🎉 Tous les tests sont passés ! Le backend fonctionne correctement.")
        print("\n💡 Vous pouvez maintenant:")
        print("   1. Lancer l'application Flutter: flutter run")
        print("   2. La collecte automatique devrait fonctionner")
        print("   3. Les données s'afficheront dans le dashboard")
    else:
        print("\n⚠️  Certains tests ont échoué.")
        print("\n💡 Vérifications:")
        print("   1. Le backend Flask est-il démarré ? (python main.py)")
        print("   2. L'adresse IP est-elle correcte ? (192.168.137.174)")
        print("   3. Le pare-feu bloque-t-il le port 5000 ?")

if __name__ == "__main__":
    main()
