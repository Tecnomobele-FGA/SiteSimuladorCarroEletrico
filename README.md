# SiteSimuladorCarroEletrico
O site https://tecnomobele-unb.web.app/#/ foi criado em flutter/dart.


## Calculando com o GPS do dispositivo

Para colhermos os dados do GPS do dispositivo, foi utilizada a biblioteca [geolocator](https://pub.dev/packages/geolocator).
Como podemos ver, a cada segundo a localização é adicionada em seu respectivo array.

  ```
  Future<int> Gps() async{
    while(comecou == true){
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      latitude.add(position.latitude);
      altitude.add(position.altitude);
      longitude.add(position.longitude);
      velocidade.add(position.speed);
      setState(() {
        posicoesColhidas += 1;
        longitudeAgora = position.longitude;
        latitudeAgora = position.latitude;
        altitudeAgora = position.altitude;
        velocidadeAgora = position.speed * 3.6;
      });
      await 1.seconds.delay;
    }
    return 0;
  }
  ```
Os valores:
- Crr1; Crrv2; Rho; Cd; Af

foram todos retirados do código feito pelo professor Rudi, [você pode conferir clicando aqui](https://github.com/Tecnomobele-FGA/SimuladorCarroEletrico).
Depois, é usado um laço de repetição com o tamanho do array da velocidade - 1 (correspondendo ao tamanho do array dV) para calcular a potencia.

O calculo da potência foi extraído do código feito pelo professor Rudi, já linkado acima. Nesse cálculo, é conferido se a potência tem valor menor que zero, se tiver, a pontência naquele ponto será zero.
Logo após, se a potência naquele ponto for maior que a variável potMax, então potMax recebe o valor da potência (A variável potMax é inicializada com valor igual a 0). A energia também é inicializada com o valor igual a 0 e é calculada somando a energia até o momento mais a potência no ponto.
  ```
  List<double> diff(List lista){
    List<double> resultado = [];
    for(int i = 0; i < lista.length - 1; i ++){
      resultado.add(lista[i + 1] - lista[i]);
    }
    return resultado;
  }
  Future<int> calcula() async{
    double Crr1=0.127;
    double Crrv2=0.000116;
    double Rho=1.1241;
    double Cd=0.5;
    List<double> dV=[];
    double Af=2.5;
    dV = diff(velocidade);
    Pot=dV;
    for(int i = 0; i < velocidade.length - 1; i++){
      Pot[i]= 0.5*Cd*Rho*Af*velocidade[i]*velocidade[i]*velocidade[i] + (Crr1*velocidade[i] + Crrv2*velocidade[i]*velocidade[i])*M + M*velocidade[i]*dV[i];
      Pot[i] > potMax ? potMax = Pot[i] : potMax = potMax;
      energia = energia + Pot[i];
    }
    return 0;
  }
  ```


## Calculando com o arquivo GPX

Do arquivo GPX, é extraido os valores da altitude, latitude, longitude e a data (horário). Para calcular a distância foi utilizada a biblioteca [latlong](https://pub.dev/packages/latlong).

Sabendo a distância e o tempo, fica fácil de calcular a velocidade. Os valores:
- Crr1; Crrv2; Rho; Cd; Af

foram novamente tabelados.

```
List<double> diff(List lista){
    List<double> resultado = [];
    for(int i = 0; i < lista.length - 1; i ++){
      resultado.add(lista[i + 1] - lista[i]);
    }
    return resultado;
  }
  Future<int> calcula() async{
    List distancia = [];
    final Distance distance = new Distance();
    for(int i = 0; i < latitude.length - 1; i++){
      distancia.add(distance(
          new LatLng(latitude[i],longitude[i]),
          new LatLng(latitude[i+1],longitude[i+1])
      ));
    }
    for(int i = 0; i < distancia.length; i++){
      velocidade.add((3.6 * distancia[i]) / (tempo[i+1] - tempo[i]));
    }
    double M=600;
    double Crr1=0.127;
    double Crrv2=0.000116;
    double Rho=1.1241;
    double Cd=0.5;
    List<double> dV=[];
    double Af=2.5;
    dV = diff(velocidade);
    Pot=dV;
    for(int i = 0; i < velocidade.length - 1; i++){
      (0.5*Cd*Rho*Af*velocidade[i]*velocidade[i]*velocidade[i] + (Crr1*velocidade[i] + Crrv2*velocidade[i]*velocidade[i])*M + M*velocidade[i]*dV[i]) < 0 ? Pot[i] = 0 : Pot[i] = 0.5*Cd*Rho*Af*velocidade[i]*velocidade[i]*velocidade[i] + (Crr1*velocidade[i] + Crrv2*velocidade[i]*velocidade[i])*M + M*velocidade[i]*dV[i] ;
      Pot[i] > potMax ? potMax = Pot[i] : potMax = potMax;
      energia = energia + Pot[i];
    }
    return 0;
  }
```


Para uma análise mais detalhada, favor checar o código completo.
