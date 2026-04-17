// temperature_server.dart
import 'dart:io';
import 'dart:convert';
import 'dart:async';

class TemperatureServer {
  static const int port = 8080;
  late ServerSocket serverSocket;
  final List<String> temperatureHistory = [];

  Future<void> startServer() async {
    try {
      print('🌡️ Iniciando Servidor de Temperatura na porta $port...');
      serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      print('✅ Servidor escutando em ${serverSocket.address.address}:$port');
      
      serverSocket.listen(handleClient);
      
    } catch (e) {
      print('❌ Erro ao iniciar servidor: $e');
    }
  }

  void handleClient(Socket client) {
    print('👤 Novo cliente conectado: ${client.remoteAddress.address}:${client.remotePort}');
    
    client.listen(
      (List<int> data) async {
        try {
          await processData(client, data);
        } catch (e) {
          print('❌ Erro ao processar dados: $e');
        }
      },
      onError: (error) {
        print('❌ Erro na conexão: $error');
        client.destroy();
      },
      onDone: () {
        print('👋 Cliente desconectado: ${client.remoteAddress.address}:${client.remotePort}');
        client.destroy();
      },
    );
  }

  Future<void> processData(Socket client, List<int> data) async {
    Completer<void> completer = Completer<void>();
    
    // Recebe o tamanho da mensagem primeiro (1 byte)
    int expectedLength = data[0];
    
    // Buffer para acumular dados
    List<int> buffer = [];
    
    // Função para processar mensagem completa
    void processMessage() {
      if (buffer.length >= expectedLength) {
        String message = String.fromCharCodes(buffer.sublist(0, expectedLength));
        
        // Remove a mensagem processada do buffer
        buffer = buffer.sublist(expectedLength);
        
        // Processa a mensagem JSON
        processTemperatureData(message);
        
        // Se ainda há dados no buffer, processa novamente
        if (buffer.isNotEmpty) {
          processMessage();
        } else {
          completer.complete();
        }
      }
    }
    
    // Adiciona dados recebidos ao buffer
    buffer.addAll(data.sublist(1)); // Ignora o primeiro byte (tamanho)
    processMessage();
    
    await completer.future;
  }

  void processTemperatureData(String message) {
    try {
      // Faz parse do JSON
      final data = json.decode(message);
      
      // Exibe no terminal com formatação bonita
      print('\n' + '='*60);
      print('📊 NOVA LEITURA DE TEMPERATURA');
      print('⏰ ${data['timestamp']}');
      print('🆔 Dispositivo: ${data['device_id']}');
      print('🌡️ Temperatura: ${data['temperature']} ${data['unit']}');
      print('='*60 + '\n');
      
      // Adiciona ao histórico
      temperatureHistory.add(message);
      
      // Mantém apenas últimas 10 leituras
      if (temperatureHistory.length > 10) {
        temperatureHistory.removeAt(0);
      }
      
    } catch (e) {
      print('❌ Erro ao fazer parse da mensagem: $message');
    }
  }

  void showStats() {
    print('\n📈 ESTATÍSTICAS (últimas ${temperatureHistory.length} leituras):');
    for (int i = 0; i < temperatureHistory.length; i++) {
      final data = json.decode(temperatureHistory[i]);
      print('  ${i+1}. ${data['temperature']}°C (${data['timestamp']})');
    }
    print('');
  }
}

void main() async {
  final server = TemperatureServer();
  
  // Trata Ctrl+C para fechamento gracioso
  ProcessSignal.sigint.watch().listen((_) {
    print('\n🛑 Encerrando servidor...');
    server.serverSocket.close();
    exit(0);
  });
  
  await server.startServer();
  
  // Mostra estatísticas a cada 30 segundos
  Timer.periodic(Duration(seconds: 30), (timer) {
    server.showStats();
  });
}