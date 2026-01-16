# Configuration Arduino/ESP32 pour Capteurs d'Asthme

## Matériel Nécessaire

### Microcontrôleur
- **ESP32** (recommandé) ou ESP8266
- Alimentation 5V/3.3V

### Capteurs
1. **DHT22** - Température et Humidité
   - Plage température: -40°C à +80°C
   - Plage humidité: 0% à 100%
   
2. **SDS011 ou PMS5003** - Particules PM2.5
   - Mesure PM2.5 et PM10
   - Interface UART
   
3. **Capteur Respiration** (Options):
   - Capteur de pression BMP280
   - Accéléromètre MPU6050
   - Capteur de flux d'air
   
4. **Fils de connexion** et breadboard

## Schéma de Connexion ESP32

```
ESP32          DHT22
-----          -----
3.3V    --->   VCC
GND     --->   GND
GPIO4   --->   DATA

ESP32          SDS011
-----          ------
5V      --->   VCC
GND     --->   GND
GPIO16  --->   TX
GPIO17  --->   RX

ESP32          BMP280 (optionnel pour respiration)
-----          ------
3.3V    --->   VCC
GND     --->   GND
GPIO21  --->   SDA
GPIO22  --->   SCL
```

## Code Arduino (Mode WiFi HTTP)

### Installation des bibliothèques

Ouvrez Arduino IDE et installez :
- **DHT sensor library** par Adafruit
- **Adafruit Unified Sensor**
- **Nova Fitness Sds dust sensors library** (pour SDS011)
- **WiFi** (intégré ESP32)
- **WebServer** (intégré ESP32)

### Code Complet

```cpp
#include <WiFi.h>
#include <WebServer.h>
#include <DHT.h>

// ===== CONFIGURATION WiFi =====
const char* ssid = "VotreNomWiFi";          // ⚠️ À MODIFIER
const char* password = "VotreMotDePasseWiFi"; // ⚠️ À MODIFIER

// ===== CONFIGURATION CAPTEURS =====
#define DHTPIN 4
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// Variables pour stocker les données
float humidity = 0.0;
float temperature = 0.0;
float pm25 = 0.0;
float respiratoryRate = 0.0;

WebServer server(80);

// ===== SETUP =====
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n╔═══════════════════════════════════════╗");
  Serial.println("║   Système Capteurs Asthme - ESP32   ║");
  Serial.println("╚═══════════════════════════════════════╝\n");
  
  // Initialiser capteur DHT22
  dht.begin();
  Serial.println("✅ DHT22 initialisé");
  
  // Connexion WiFi
  Serial.print("📡 Connexion WiFi...");
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi connecté!");
    Serial.print("📍 Adresse IP: ");
    Serial.println(WiFi.localIP());
    Serial.println("\n⚠️  NOTEZ CETTE ADRESSE POUR FLUTTER! ⚠️\n");
  } else {
    Serial.println("\n❌ Échec connexion WiFi");
    return;
  }
  
  // Configuration serveur HTTP
  server.on("/health", handleHealth);
  server.on("/sensors", handleSensors);
  server.enableCORS(true);
  
  server.begin();
  Serial.println("🌐 Serveur HTTP démarré sur port 80");
  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  Serial.println("Endpoints disponibles:");
  Serial.println("  GET /health   - Vérifier status");
  Serial.println("  GET /sensors  - Lire capteurs");
  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
}

// ===== LOOP =====
void loop() {
  server.handleClient();
  
  // Lire capteurs toutes les 2 secondes
  static unsigned long lastRead = 0;
  if (millis() - lastRead > 2000) {
    readAllSensors();
    lastRead = millis();
  }
}

// ===== LECTURE CAPTEURS =====
void readAllSensors() {
  // Lire DHT22
  float h = dht.readHumidity();
  float t = dht.readTemperature();
  
  if (!isnan(h) && !isnan(t)) {
    humidity = h;
    temperature = t;
  }
  
  // Lire PM2.5 (à implémenter selon votre capteur)
  pm25 = readPM25Sensor();
  
  // Lire fréquence respiratoire (à implémenter)
  respiratoryRate = readRespirationSensor();
  
  // Afficher dans Serial Monitor
  Serial.println("📊 Données capteurs:");
  Serial.printf("   Humidité: %.1f%%\n", humidity);
  Serial.printf("   Température: %.1f°C\n", temperature);
  Serial.printf("   PM2.5: %.1f µg/m³\n", pm25);
  Serial.printf("   Resp. Rate: %.1f/min\n\n", respiratoryRate);
}

float readPM25Sensor() {
  // TODO: Implémenter lecture SDS011 ou PMS5003
  // Pour l'instant, retourner valeur simulée
  return 35.0 + random(-10, 10);
}

float readRespirationSensor() {
  // TODO: Implémenter avec BMP280 ou accéléromètre
  // Pour l'instant, retourner valeur simulée
  return 16.0 + random(-2, 2);
}

// ===== ENDPOINTS HTTP =====
void handleHealth() {
  String json = "{\"status\":\"ok\",\"uptime\":" + String(millis()/1000) + "}";
  
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", json);
  
  Serial.println("✓ Health check");
}

void handleSensors() {
  // Créer réponse JSON
  String json = "{";
  json += "\"humidity\":" + String(humidity, 1) + ",";
  json += "\"temperature\":" + String(temperature, 1) + ",";
  json += "\"pm25\":" + String(pm25, 1) + ",";
  json += "\"respiratoryRate\":" + String(respiratoryRate, 1) + ",";
  json += "\"timestamp\":" + String(millis());
  json += "}";
  
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", json);
  
  Serial.println("✓ Données envoyées à Flutter");
}
```

## Étapes d'Installation

### 1. Préparer Arduino IDE
```bash
- Télécharger Arduino IDE: https://www.arduino.cc/en/software
- Installer support ESP32:
  * File → Preferences → Additional Boards Manager URLs
  * Ajouter: https://dl.espressif.com/dl/package_esp32_index.json
  * Tools → Board → Boards Manager → Installer "ESP32"
```

### 2. Configurer le Code
- Modifier `ssid` et `password` avec vos identifiants WiFi
- Vérifier les pins des capteurs
- Ajuster les seuils si nécessaire

### 3. Téléverser
- Connecter ESP32 via USB
- Sélectionner: Tools → Board → ESP32 Dev Module
- Sélectionner le bon port COM
- Cliquer Upload

### 4. Tester
- Ouvrir Serial Monitor (115200 baud)
- Noter l'adresse IP affichée
- Tester dans navigateur: `http://ADRESSE_IP/sensors`

### 5. Configurer Flutter
Dans `prediction_screen.dart`, ligne 218:
```dart
_arduinoService.setServerUrl('http://192.168.100.XX:80');
//                                    ↑ Remplacer par votre IP
```

## Dépannage

### Problème: WiFi ne se connecte pas
- Vérifier le SSID et mot de passe
- S'assurer que l'ESP32 est à portée
- Vérifier que le WiFi est en 2.4GHz (pas 5GHz)

### Problème: Capteurs retournent NaN
- Vérifier les connexions physiques
- Vérifier l'alimentation (3.3V pour DHT22)
- Ajouter résistance pull-up 10kΩ sur DATA

### Problème: Flutter ne reçoit pas les données
- Vérifier que le téléphone est sur le même réseau WiFi
- Tester l'URL dans un navigateur d'abord
- Vérifier le pare-feu

## Format JSON Attendu par Flutter

```json
{
  "humidity": 65.5,
  "temperature": 22.3,
  "pm25": 35.2,
  "respiratoryRate": 16.0,
  "timestamp": 123456789
}
```

## Ressources

- [Documentation ESP32](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/)
- [DHT22 Datasheet](https://www.sparkfun.com/datasheets/Sensors/Temperature/DHT22.pdf)
- [SDS011 Guide](https://nettigo.eu/attachments/415)
- [Circuit Diagrams](https://fritzing.org/)

## Support

Pour questions ou problèmes, vérifiez:
1. Serial Monitor pour les logs ESP32
2. Flutter logs: `flutter run` pour voir les erreurs réseau
3. Tester endpoint avec cURL: `curl http://192.168.100.XX/sensors`
