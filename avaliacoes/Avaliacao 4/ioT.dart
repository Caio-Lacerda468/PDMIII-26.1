// iot_device.dart
import 'dart:io';
import 'dart:math';
import 'dart:async';

class IoTDevice {
  static const String serverHost = 'localhost';
  static const int serverPort = 8080;
  static const Duration sendInterval = Duration(seconds: 10);
  
  late Socket socket;
  late Timer timer;
  final Random random = Random();

  Future<void> connectAndStart() async {
    try {
      print('🔥 IoT Device iniciando conexão com servidor $serverHost:$serverPort...');
      
      // Conecta ao servidor
      socket = await Socket.connect(serverHost, serverPort);
      print('✅ Conectado ao servidor com sucesso!');
      
      // Inicia envio periódico de temperaturas
      await sendTemperatureLoop();
      
    } catch (e) {
      print('❌ Erro ao conectar: $e');
      await Future.delayed(Duration(seconds: 5));
      await connectAndStart(); // Reconecta em caso de falha
    }
  }

  Future<void> sendTemperatureLoop() async {
    while (true) {
      try {
        // Gera temperatura aleatória entre 15°C e 35°C
        double temperature = 25.0 + (random.nextDouble() - 0.5) * 20;
        temperature = double.parse(temperature.toStringAsFixed(2));
        
        // Cria mensagem JSON
        Map<String, dynamic> data = {
          'timestamp': DateTime.now().toIso8601String(),
          'device_id': 'sensor_temp_001',
          'temperature': temperature,
          'unit': '°C'
        };
        
        String message = '${data.toString()}\n';
        List<int> messageBytes = message.codeUnits;
        
        // Envia tamanho do mensagem + mensagem
        socket.add([messageBytes.length]);
        socket.add(messageBytes);
        
        print('📤 Enviado: $data');
        
        // Aguarda 10 segundos
        await Future.delayed(sendInterval);
        
      } catch (e) {
        print('❌ Erro ao enviar dados: $e');
        break;
      }
    }
  }

  void close() {
    timer.cancel();
    socket.destroy();
    print('🔌 IoT Device desconectado');
  }
}

void main() async {
  final iotDevice = IoTDevice();
  
  // Trata Ctrl+C para fechamento gracioso
  ProcessSignal.sigint.watch().listen((_) {
    print('\n🛑 Encerrando IoT Device...');
    iotDevice.close();
    exit(0);
  });
  
  await iotDevice.connectAndStart();
}