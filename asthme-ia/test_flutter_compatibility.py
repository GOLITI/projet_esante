"""
Test de compatibilité entre l'API Flask et Flutter
Simule une requête Flutter pour vérifier la compatibilité des formats
"""
import requests
import json

def test_prediction_api():
    """Test l'endpoint /api/predict avec le format Flutter"""
    
    url = "http://127.0.0.1:5000/api/predict"
    
    # Format de requête Flutter (après modification de api_client.dart)
    data = {
        "symptoms": {
            "Tiredness": 1,
            "Dry-Cough": 1,
            "Difficulty-in-Breathing": 1,
            "Sore-Throat": 0,
            "Pains": 0,
            "Nasal-Congestion": 1,
            "Runny-Nose": 0
        },
        "demographics": {
            "age": "20-24",
            "gender": "Male"
        },
        "sensors": {
            "Humidity": 75.0,
            "Temperature": 24.5,
            "PM25": 45.0,
            "RespiratoryRate": 22.0
        }
    }
    
    print("="*60)
    print("TEST DE COMPATIBILITÉ FLUTTER ↔ API")
    print("="*60)
    print(f"\n📤 Requête envoyée à {url}")
    print(f"Format: {json.dumps(data, indent=2)}\n")
    
    try:
        response = requests.post(url, json=data, timeout=5)
        
        print(f"📊 Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            
            print("\n✅ RÉPONSE REÇUE:")
            print(json.dumps(result, indent=2, ensure_ascii=False))
            
            # Vérifier la structure attendue par Flutter
            print("\n🔍 VALIDATION FLUTTER:")
            print("="*60)
            
            required_fields = {
                'success': bool,
                'risk_level': int,
                'risk_label': str,
                'risk_score': float,
                'probabilities': dict,
                'recommendations': list
            }
            
            all_valid = True
            for field, expected_type in required_fields.items():
                if field in result:
                    actual_type = type(result[field])
                    if isinstance(result[field], expected_type):
                        print(f"✅ {field}: {actual_type.__name__} = {result[field] if field != 'probabilities' else '...'}")
                    else:
                        print(f"❌ {field}: attendu {expected_type.__name__}, reçu {actual_type.__name__}")
                        all_valid = False
                else:
                    print(f"❌ {field}: MANQUANT")
                    all_valid = False
            
            print("\n" + "="*60)
            if all_valid:
                print("✅ COMPATIBILITÉ: 100% OK!")
                print("\nFlutter peut utiliser:")
                print(f"  - risk_label: '{result['risk_label']}' → Affichage UI")
                print(f"  - risk_score: {result['risk_score']:.2%} → Jauge de risque")
                print(f"  - risk_level: {result['risk_level']} → Couleur (1=Vert, 2=Orange, 3=Rouge)")
                print(f"  - recommendations: {len(result['recommendations'])} conseils → Liste UI")
            else:
                print("❌ PROBLÈMES DE COMPATIBILITÉ DÉTECTÉS")
            
            return all_valid
        else:
            print(f"❌ Erreur HTTP {response.status_code}")
            print(response.text)
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erreur de connexion: {e}")
        print("\n💡 Assurez-vous que le serveur Flask est démarré:")
        print("   cd asthme-ia && python main.py")
        return False

def test_health_endpoint():
    """Test l'endpoint /health"""
    try:
        response = requests.get("http://127.0.0.1:5000/health", timeout=2)
        if response.status_code == 200:
            print("✅ Serveur Flask opérationnel\n")
            return True
        return False
    except:
        print("❌ Serveur Flask non accessible\n")
        return False

if __name__ == "__main__":
    print("\n🚀 Démarrage des tests de compatibilité...\n")
    
    if test_health_endpoint():
        success = test_prediction_api()
        
        print("\n" + "="*60)
        if success:
            print("🎉 TOUS LES TESTS RÉUSSIS!")
            print("="*60)
            print("\n✅ Le modèle est prêt à être utilisé avec Flutter")
            print("✅ Le format de réponse est 100% compatible")
            print("✅ Prochaine étape: Implémenter l'appel dans Flutter")
        else:
            print("⚠️ ÉCHEC DES TESTS")
            print("="*60)
    else:
        print("⚠️ Impossible de tester - Serveur non démarré")
