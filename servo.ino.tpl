#include <stdio.h>
#include <ESP8266WebServer.h>
#include <ArduinoJson.h>
#include <Servo.h>

Servo servo;

#define HTTP_REST_PORT 80
#define WIFI_RETRY_DELAY 500
#define MAX_WIFI_INIT_RETRY 50
#define LED 16
#define DATA_PIN 2 // D4

#define NEUTRAL 0
#define PUSHED 60
#define PUSH_DELAY 500

const char* wifi_ssid = "YOUR SSID";
const char* wifi_passwd = "YOUR WIFI PASSWORD";

ESP8266WebServer http_rest_server(HTTP_REST_PORT);

int init_wifi() {
  int retries = 0;

  Serial.println("Connecting to WiFi AP..........");

  WiFi.mode(WIFI_STA);
  WiFi.begin(wifi_ssid, wifi_passwd);
  // check the status of WiFi connection to be WL_CONNECTED
  while ((WiFi.status() != WL_CONNECTED) && (retries < MAX_WIFI_INIT_RETRY)) {
    retries++;
    delay(WIFI_RETRY_DELAY);
    Serial.print("#");
  }
  return WiFi.status(); // return the WiFi connection status
}

void get_servo() {
  StaticJsonBuffer<200> jsonBuffer;
  JsonObject& jsonObj = jsonBuffer.createObject();
  char JSONmessageBuffer[200];
  
  //http_rest_server.send(204);
  jsonObj["angle"] = servo.read();
  jsonObj["attached"] = servo.attached();
  jsonObj.prettyPrintTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
  http_rest_server.send(200, "application/json", JSONmessageBuffer);
}

void post_servo() {
  StaticJsonBuffer<500> jsonBuffer;
  String post_body = http_rest_server.arg("plain");
  Serial.println(post_body);

  JsonObject& jsonBody = jsonBuffer.parseObject(http_rest_server.arg("plain"));

  Serial.print("HTTP Method: ");
  Serial.println(http_rest_server.method());

  if (!jsonBody.success()) {
    Serial.println("error in parsin json body");
    http_rest_server.send(400);
  }
  else {
      http_rest_server.sendHeader("Location", "/servo/" + String(1));
      http_rest_server.send(201);
      servo.write(jsonBody["angle"]);
      delay(jsonBody["duration"]);
      servo.write(NEUTRAL);
 }
}

void config_rest_server_routing() {
  http_rest_server.on("/", HTTP_GET, []() {
    http_rest_server.send(200, "text/html",
                          "Welcome to the ESP8266 REST Web Server");
  });
  http_rest_server.on("/servo", HTTP_GET, get_servo);
  http_rest_server.on("/servo", HTTP_POST, post_servo);
}

void setup(void) {
  servo.write(NEUTRAL);
  servo.attach(DATA_PIN);
  delay(2000);

  Serial.begin(115200);

  if (init_wifi() == WL_CONNECTED) {
    Serial.print("Connected to ");
    Serial.print(wifi_ssid);
    Serial.print("--- IP: ");
    Serial.println(WiFi.localIP());
  }
  else {
    Serial.print("Error connecting to: ");
    Serial.println(wifi_ssid);
  }

  config_rest_server_routing();
  http_rest_server.begin();
  Serial.println("HTTP REST Server Started");
}

void loop(void) {
  http_rest_server.handleClient();
}
