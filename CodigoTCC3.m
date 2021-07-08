%Limpa a janela de comando
clc
clear

%Início da primeira parte do código
%Essa parte tem por objetivo calclar as necessidades de potência e energia
%do veículo em função do trajeto informado pelo usuário por meio de arquivo
%gpx com os dados da trajetória do veículo

%Entrada de dados
%Seleção do tipo de veículo e de coeficiente aerodinâmico
list = {'Bicicleta (0.9)','Motocicleta (0.7)','Carro Esportivo (0.3)','Carro Hatch (0.4)','Carro Conversível (0.7)' ... 
    'Carro Sedan (0.4)','SUV (0.5)','Utilitário (0.5)','Van (0.7)', 'Minibus (0.8)'};
[indx,tf] = listdlg('PromptString',{'Selecione o tipo de veículo (Cx):'},'SelectionMode',...
    'single', 'ListString', list);
veiculo = [indx, tf];
if veiculo(1) == 1
    Cd = 0.9;         %bicibleta
    elseif veiculo(1) == 2
    Cd = 0.7;         %motocicleta
    elseif veiculo(1) == 3
    Cd = 0.3;         %carro esportivo
    elseif veiculo(1) == 4
    Cd = 0.4;         %carro hatch
    elseif veiculo(1) == 5
    Cd = 0.7;         %conversível aberto
    elseif veiculo(1) == 6
    Cd = 0.4;         %carro sedan
    elseif veiculo(1) == 7
    Cd = 0.5;         %SUV
    elseif veiculo(1) == 8
    Cd = 0.5;         %utilitário
    elseif veiculo(1) == 9
    Cd = 0.7;         %VAN
    elseif veiculo(1) == 10
    Cd = 0.8;         %minibus
end
Cd = Cd;   % Coeficiente aerodinâmico final

%Entrada do nome do arquivo e dados do veículo
prompt = {'Digite o nome do arquivo gpx:','Digite a massa total do veículo (massa do veículo + massa da carga total) em kg (substitua "," por "."):',...
    'Digite a largura do veículo, em metros (substitua "," por "."):', ...
    'Digite a altura do veículo, em metros (substitua "," por "."):', ... 
    'Digite o coeficiente aerodinâmico do veículo (caso não saiba, digite 0):'};
dlgtitle = 'Input';
dims = [1 35];
definput = {'','','','',''};
answer = inputdlg(prompt,dlgtitle,dims,definput)
arquivo = (answer{1});         %Arquivo gpx
M = str2num(answer{2});        %Massa total do veículo
L = str2num(answer{3});        %Largura do veículo em metros
h = str2num(answer{4});        %Altura do veículo em metros
Cddigitado = str2num(answer{5}); %coeficiente aerodinâmico digitado pelo usuário

if Cddigitado ~= 0
    Ck = Cddigitado;
else
    Ck = Cd;
end
Cd = Ck;        % Coeficiente aerodinâmico final

%importando o arquivo gpx e estabelecendo limites de print da rota no mapa
route = gpxread(arquivo, 'FeatureType', 'track','Index', 1:2)
%Variáveis importadas gpx
lon = route.Longitude;
lat = route.Latitude;
ele = route.Elevation;
tempo = route.Time;

%Plotando o gráfico da rota percorrida
%estabelecendo limites longitudinais e latitudinais do gráfico
[latlim, lonlim] = geoquadline(route.Latitude, route.Longitude);
[latlim, lonlim] = bufgeoquad(latlim, lonlim, .05, .05);
%printa o gráfico da rota
%fig = figure;
%pos = fig.Position;
%fig.Position = [150 150 1.25*pos(3) 1.25*pos(4)];
%ax = usamap(latlim, lonlim);
%setm(ax, 'MLabelParallel', 43.5);
%geoshow(route.Latitude, route.Longitude)

%imprimindo a rota a partir de mapa do streetgoogle
webmap('openstreetmap')
wmline(route, 'Color', 'r')
%estabelece latitude e longitude da impressão da rota no mapa
[latlim, lonlim] = geoquadline(route(1).Latitude, route(1).Longitude);
wmlimits(latlim, lonlim)

%Converte o tempo de string para número
timeStr = strrep(tempo, 'T', ' ');
timeStr = strrep(timeStr, '.Z', '');
route.DateNumber = datenum(timeStr, 'yyyy-mm-dd HH:MM:SS');
dStr = datestr(route.DateNumber, 'yyyy-mm-dd HH:MM:SS', 'local');
day = fix(route.DateNumber(1));
route.TimeOfDay = route.DateNumber - day;
%Converte o tempo de horário para tempo decorrido ao longo do trajeto
route.ElapsedTime = route.TimeOfDay - route.TimeOfDay(1);  
tempodecorrido = route.ElapsedTime(2 : end);    %tempo em minutos, horas e segundos

%Imprime a elevação
figure
area(route.TimeOfDay, ele)
datetick('x', 13, 'keepticks', 'keeplimits')
ylim([min(ele) max(ele)])
ylabel('Elevação (metros)')
xlabel('tempo decorrido (horas:minutos:segundos)')
title({'Elevação da Área', datestr(day)})

%Plota a distância percorrida acumulada e não acumulada em metros
e = wgs84Ellipsoid;
d = distance(lat(1:end-1), lon(1:end-1), lat(2:end), lon(2:end), e);  %calcula a distância percorrida em metros
figure
[hAx,hLine1,hLine2] = plotyy(tempodecorrido, cumsum(d), tempodecorrido, d);
datetick('x', 13,  'keepticks', 'keeplimits')
ylabel(hAx(1), 'Distância Percorrida Acumulada (m)')
ylabel(hAx(2),'Distância Percorrida (m)')
xlabel('Tempo decorrido  (horas:minutos:segundos)')
title({'Distância Percorrida em Metros',...
    ['Distância Total (Km): ' num2str(sum(d)/1000)]});
%datestr(day)

%Calcula o ângulo de inclinação da pista
[gpsx,gpsy,gpsz] = geodetic2enu(lat, lon, ele, lat(1), lon(1), ele(1), e);    %coordenadas
slopegraus = atand(diff(gpsz)./sqrt(diff(gpsx).^2 + diff(gpsy).^2));  %Calculando o ângulo (graus) com a função tangente
slopeout = filloutliers(slopegraus, 'linear');    %Retira outliers de "slopegraus"
slope = movavg(slopeout, 4, 20, 1);   %Suavização do ângulo de inclinação com média móvel de 4 pontos
sloperad = deg2rad(slope);   %transforma a variável "slope" em radianos
slopemax = max(slope);       %Inclinação máxima atingida durante o trajeto

%Plota o gráfico do ângulo de inclinação calculado pela função tangente
figure
plot(tempodecorrido,slope)
datetick('x', 13,  'keepticks', 'keeplimits')
ylabel('ângulo de inclinação da pista (graus)')
xlabel('Tempo decorrido  (horas:minutos:segundos)')
title({'Ângulo de Inclinação da Pista (ATAN) em Graus', datestr(day),...
    ['Inclinação Máxima do Trajeto em Graus: ' num2str(slopemax)]});

%Ajusta o tempo
tacumulado = tempodecorrido.*(24*3600);
tdiff = diff(tacumulado);
tempocompleto = [tacumulado(1) tdiff];
t = tempocompleto;   %tempo, em segundos, decorrido entre cada ponto de captura de dados ao longo do trajeto 
somat = sum(t);
n = length(t);               %Dá o comprimento dos vetores usados nos cálculos

%Calcula a velocidade em Km/h
for i = 1:n
    Vkm(i) = d(i)/t(i);      %calcula a velocidade em km/h
end
Vkm = filloutliers(Vkm.*(3600/1000), 'linear');    %Substitui outliers por valor obtido por interpolação linear
Vkm(1) = [0];                %substitui o primeiro valor de velocidade do vetor por zero
Vkm = Vkm;
VMax = max(Vkm);                %Velocidade máxima no trecho em km/h
V = Vkm.*(1000/3600);         %Velocidade em metros por segundo 

%Plota a velocidade em função do tempo em km/h
figure
plot(tempodecorrido, Vkm)
datetick('x', 13,  'keepticks', 'keeplimits')
ylabel('velocidade (km/hora)')
xlabel('Tempo decorrido  (horas:minutos:segundos)')
title({'Velocidade em Km por Hora', datestr(day),...
    ['Velocidade Máxima Atingida no Trajeto em Km/h: ' num2str(VMax)]});

%Calcula a aceleração em m/s^2
dV = diff(V);                 %Diferencia a velocidade
VV = [V(1) dV];  %Acrescenta o primeiro valor perdido na diferenciação ao vetor velocidade diferenciada
for i = 1:n
     acel(i) = VV(i)/t(i);       %Divide a velocidade diferenciada pelo tempo gasto em cada trecho
end
acel = acel(:);
nacel = length(acel);       %comprimento do vetor aceleração

%Estabelece o limite de aceleração máxima do veículo
%Serve para corrigir erro de cálculo de aceleração a partir de dados do GPS
mediaacel = mean(acel);
desvio = std(acel);
for i = 1:n
    limitesup = mediaacel + 3*desvio;
    limiteinf = mediaacel - 3*desvio;
    
    if acel(i) > limitesup
        acel(i) = limitesup;
    elseif acel(i) < limiteinf
        acel(i) = limiteinf;
    else
        acel(i) = acel(i);
    end
end
acel = acel(:);
acel = movavg(acel, 4, 20, 1); %Suaviza a aceleração com média móvel de 4 pontos

%Plota a aceleração em m/s^2
figure
plot(tempodecorrido, acel)
datetick('x', 13,  'keepticks', 'keeplimits')
ylabel('aceleração (m/s^2)')
xlabel('Tempo decorrido  (horas:minutos:segundos)')
title({'Aceleração em Metros por Segundo Quadrado', datestr(day),...
    ['Distância Total (Km): ' num2str(sum(d)/1000)]});

%Parâmetros de entrada
p = 1.22557;            % Rho = densidade do ar (kg/m^3)
Vv = 3.6;               % Velocidade do vento m/s
g = 9.81066;            % Aceleração da gravidade  (m/s^2)
A = (h - 0.25) * L;    % Área do veículo calculada em m^2
Cd = Cd;                % Coeficiente aerodinâmico
angulo = sloperad;      % Ângulo de inclinação da pista em radianos
%n = nacel; 

%Calcula a Força de Resistência Aerodinâmica em Newtons
for i = 1:n
    Fa(i) = 0.5*p*A*Cd.*(V(i)+Vv).^2;                       % Força aerodinâmica (N)
end
Fa = Fa(:);
Famax = max(Fa);           %Valor máximo da Fa no trecho em Newtons
%Plota a Força de Resistência Aerodinâmica em Newtons
%figure
%plot(tempodecorrido, Fa)
%datetick('x', 13,  'keepticks', 'keeplimits')
%ylabel('Força de Resistência Aerodinâmica (N)')
%xlabel('Tempo decorrido  (horas:minutos:segundos)')
%title({'Força de Resistência Aerodinâmica em Newtons - Fa', datestr(day),...
 %   ['Valor máximo da Fa no trecho em Newtons: ' num2str(Famax)]});

%Calcula a Força de Resistência ao Rolamento em Newtons
for i = 1:n
    fr(i) = 0.01.*(1 + 0.01.*V(i));        %Coeficiente de resistência ao rolamento (N)
    Fr(i) = fr(i).*(M*g).*cos(angulo(i));     %Força de resistência ao rolamento (N)
 end
Fr = Fr(:);
Frmax = max(Fr);           %Valor máximo da Fr no trecho em Newtons
%Plota a Força de Resistência ao Rolamento em Newtons
%figure
%plot(tempodecorrido, Fr)
%datetick('x', 13,  'keepticks', 'keeplimits')
%ylabel('Força de Resistência ao Rolamento (N)')
%xlabel('Tempo decorrido  (horas:minutos:segundos)')
%title({'Força de Resistência ao Rolamento em Newtons - Fr', datestr(day),...
 %   ['Valor máximo da Fr no trecho em Newtons: ' num2str(Frmax)]});

%Calcula a Força de Resistência ao Plano Inclinado em Newtons
for i = 1:n
    Fhx(i) = M*g.*sin(angulo(i));         % Força de resistência do plano inclinado (N)
 end
Fhx = Fhx(:);
Fhxmax = max(Fhx);           %Valor máximo da Fhx no trecho em Newtons
%Plota a Força de Resistência ao Plano Inclinado em Newtons
%figure
%plot(tempodecorrido, Fhx)
%datetick('x', 13,  'keepticks', 'keeplimits')
%ylabel('Força de Resistência ao Plano Inclinado (N)')
%xlabel('Tempo decorrido  (horas:minutos:segundos)')
%title({'Força de Resistência ao Plano Inclinado em Newtons - Fhx', datestr(day),...
   % ['Valor máximo da Fhx no trecho em Newtons: ' num2str(Fhxmax)]});

%Calcula a Força de Resistência à Aceleração em Newtons
for i = 1:n
    Fca(i) = 1.05*M.*acel(i);                               % Força de resistência à aceleração (N)
 end
Fca = Fca(:);
Fcamax = max(Fca);           %Valor máximo da Fca no trecho em Newtons
%Plota a Força de Resistência à Aceleração em Newtons
%figure
%plot(tempodecorrido, Fca)
%datetick('x', 13,  'keepticks', 'keeplimits')
%ylabel('Força de Resistência à Aceleração (N)')
%xlabel('Tempo decorrido  (horas:minutos:segundos)')
%title({'Força de Resistência à Aceleração em Newtons - Fca', datestr(day),...
 %   ['Valor máximo da Fca no trecho em Newtons: ' num2str(Fcamax)]});

%Calcula a Força Total em Newtons
for i = 1:n
    Ft(i) = Fa(i) + Fr(i) + Fhx(i) + Fca(i);                % Força total (N) 
 end
Ft = Ft(:);
Ftmax = max(Ft);           %Valor máximo da Ft no trecho em Newtons
%Plota a Força Total em Newtons
%figure
%plot(tempodecorrido, Ft)
%datetick('x', 13,  'keepticks', 'keeplimits')
%ylabel('Força Total (N)')
%xlabel('Tempo decorrido  (horas:minutos:segundos)')
%title({'Força Total em Newtons - Ft', datestr(day),...
    %['Valor máximo da Ft no trecho em Newtons: ' num2str(Ftmax)]});

%Calcula a Potência em Watts
for i = 1:n
      Pt(i) = Ft(i).*V(i);           % Potência (W)
   if Pt(i) > 0
        Pt(i) = Pt(i);                                                                
   else
        Pt(i) = 0; 
   end  
end
Pt = Pt(:); 

%Estabelece limite de 3 desvios padrões para controle de outliers
mediaPt = mean(Pt);
desvioPt = std(Pt);
for i = 1:n
    limsup = mediaPt + 4 * desvioPt;
    
if Pt(i) > limsup
        Pt(i) = limsup;
    else
        Pt(i) = Pt(i);
    end
end
Pt = Pt(:);   % Potência (W)
PtMaxima = max(Pt);          %Valor máximo de potência em Watts
PtMedia = mean(Pt);          %Valor médio de potência em Watts
PtMaximaKW = PtMaxima/1000;        %Valor máximo de potência em kW
PtMediaKW = PtMedia/1000;          %Valor médio de potência em kW
PmMediakW = PtMediaKW/0.95;    %Valor de potência média para escolha do motor considerando eficiência
PmMaximakW = PtMaximaKW/0.95;  %Valor de potência máxima para escolha do motor considerando eficiência

%Plota a Potência em Watts
figure
plot(tempodecorrido, Pt)
datetick('x', 13,  'keepticks', 'keeplimits')
ylabel('Potência (W)')
xlabel('Tempo decorrido  (horas:minutos:segundos)')
title({'Potência em Watts', datestr(day),...
    ['Potência Máxima (kW): ' num2str(PtMaximaKW)],...
    ['Potência Média (kW): ' num2str(PtMediaKW)]});

%Calcula a Potência em CV
Ptcv = 0.0013596.*Pt(:);         %Potência (cv)
PtcvMaxima = max(Ptcv);         %Valor máximo de potência em CV
PtcvMedia = mean(Ptcv);       %Valor médio de potência em CV
PmMediacv = PtcvMedia/0.95;    %Valor de potência média para escolha do motor considerando eficiência
PmMaximacv = PtcvMaxima/0.95;  %Valor de potência máxima para escolha do motor considerando eficiência

%Plota a Potência em CV
figure
plot(tempodecorrido, Ptcv)
datetick('x', 13,  'keepticks', 'keeplimits')
ylabel('Potência (CV)')
xlabel('Tempo decorrido  (horas:minutos:segundos)')
title({'Potência em CV', datestr(day),...
    ['Potência Máxima em CV: ' num2str(PtcvMaxima)],...
    ['Potência Média em CV: ' num2str(PtcvMedia)]});

%Plota a potência em CV e a Velocidade em Km/h
figure
[hAx,hLine1,hLine2] = plotyy(tempodecorrido, Ptcv, tempodecorrido, V);
datetick('x', 13,  'keepticks', 'keeplimits')
ylabel(hAx(1), 'Potência (CV)')
ylabel(hAx(2),'Velocidade (m/s)')
xlabel('Tempo decorrido  (horas:minutos:segundos)')
title({'Potência e Velocidade x Tempo', datestr(day)})

tacum = cumsum(t);                    %Calcula o tempo acumulado para o período analisado
Energiatotal = trapz(tacum,Pt);       %calcula a energia total em Watts
EnergiatotalKW = Energiatotal/1000;   %calcula a energia total em kW
EnergiaAcum = cumtrapz(tacum,Pt);     %calcula a energia acumulada no tempo em Watts
Energiadiff = diff(EnergiaAcum);      %Diferencia a energia acumulada em Watts
EnergiatotalKWH = EnergiatotalKW/3600;   %Calcula energia em kWh

%Plota a Energia Acumulada em Watts
figure
plot(tempodecorrido, EnergiaAcum)
datetick('x', 13,  'keepticks', 'keeplimits')
ylabel('Energia (W)')
xlabel('Tempo decorrido  (horas:minutos:segundos)')
title({'Energia Acumulada em Watts', datestr(day),...
    ['Energia Total (kWh): ' num2str(EnergiatotalKWH)]});

Energia = [0; Energiadiff];   %Energia em Watts
Energia  = Energia(:);  %Energia diferenciada em Watts
%Plota a Energia não acumulada em Watts
figure
plot(tempodecorrido, Energia)
datetick('x', 13,  'keepticks', 'keeplimits')
ylabel('Energia (W)')
xlabel('Tempo decorrido  (horas:minutos:segundos)')
title({'Energia em Watts', datestr(day),...
    ['Energia Total (kWh): ' num2str(EnergiatotalKWH)]});

%Fim da primeira parte do código


%Início da segunda parte do código

%Essa segunda parte tem por objetivo otimizar a quantidade de baterias a ser
%instalada no veículo a partir de dados informados pelo usuário


%Entrada do nome do arquivo e dados das paradas ao longo do trajeto
prompt = {['Digite o número de paradas, incluindo a saída e a chegada, e clique em "OK". Considere a saída como parada 1. Considere a última parada como ponto de chegada.   -  ',...
    '  (Caso não deseje dimensionar a quantidade de baterias para o veículo, clique em "Cancel") : ']};
dlgtitle = 'Input';
dims = [1 35];
definput = {''};
answer = inputdlg(prompt,dlgtitle,dims,definput);
%Número de paradas
Nparadas = str2num(answer{1});  %número total de paradas
k = Nparadas;  %k = número de paradas que o usuário irá inserir
p = 1:1:k;
zeros(k,k);

%dados do tempo de parada em cada parada
Tempoparada = k;
prompts = cell(1, Tempoparada);
prompts(1:1:end) = compose('Digite, em minutos, o tempo de parada na parada %d (considere a saída como parada 1). Na última parada, considerada ponto de chegada, digite zero. Use apenas valores inteiros, sem casas decimais:', 1:Tempoparada);
outtempo = inputdlg(prompts);
%Prepara os dados dos tempos de parada
for i = 1:k
    tdg(i)=str2num(outtempo{i});   %converte os valores de tempo digitados para número
    tdg(k) = 0;
    t = [tdg];
end
tempodig = [t];    %tempo de carregamento em cada parada digitado pelo usuário

%dados da distância entre cada parada
for i = 1:k-1
    Distentreparadas = k;
    prompts = cell(1, Distentreparadas);
    prompts(1:1:i) = compose(['Digite, em km, a distância entre a Parada: %d e a Parada: ' num2str(i+1) '.\n(Considere a saída como parada 1 e, a última parada, como ponto de chegada).\nUse ponto no lugar de vírgula:'], 1:i);
    outdistancia(i) = inputdlg(prompts(i)); 
    x(i) = str2num(outdistancia{i}); %converte os valores de distância entre paradas digitados para número
    ddd(i) = x(i);
end
distdig1 = [ddd];  %valores de distância digitados pelo usuário
distdig = [cumsum(distdig1)];
distdig = [0 distdig];     %vetor com soma acumulada dos valores de distância digitados pelo usuário
%Corrigindo o último valor da distância digitada pelo usuário
disttraj = cumsum(d)/1000;   %distância medida acumulada de todo o trajeto
ndisttraj = length(disttraj);
x = distdig;
n = length(x);
for i = n:n
    if x(i) > disttraj(ndisttraj)
        x(i) = disttraj(ndisttraj);
    %elseif x(i) < disttraj(ndisttraj)
        %distdiff = disttraj(ndisttraj)-x(i);
        %msgbox(['A distância do último trecho difere da distância medida por ' num2str(distdiff) 'km . Deseja manter a distância informada ou permite que o algoritmo corrija o valor informado para utilizar toda a distância do percurso mapeado pelo GPS?:'])
        %if resposta == sim
            %x(i) = x(i);
        %else
            %x(i) = disttraj(ndisttraj)
        %end
    else
        x(i) = x(i);    
    end
end
distdig = [x];  %distância digitada corrigida

%Entrada dos Parâmetros das baterias e do carregador
prompt = {'Digite o valor da tensão da bateria em Volts (substitua "," por "."):',...
    'Digite o valor da Capacidade Nominal da Bateriam em Ah (substitua "," por "."):',...
    'Digite a largura da bateria, em mm (substitua "," por "."):', ...
    'Digite a altura da bateria, em mm (substitua "," por "."):', ... 
    'Digite o comprimento da bateria, em mm (substitua "," por "."):', ... 
    'Digite o custo/preço da bateria em unidade monetária $$ (substitua "," por "."):',...
    'Digite o valor da Capacidade Nominal do Carregador em Ah (substitua "," por ".") - (Caso desconheça o valor, digite 0 (zero), e o algoritmo usará o valor padrão de 10 Ah):'};
dlgtitle = 'Input';
dims = [1 35];
definput = {'','','','','','',''};
answer = inputdlg(prompt,dlgtitle,dims,definput)
Tensao = str2num(answer{1});       %tensão [volts]
CNB = str2num(answer{2});          %Capacidade Nominal da Bateria [Ah]
LB = str2num(answer{3});            %Largura da bateria em mm
hB = str2num(answer{4});            %Altura da bateria em mm
cmB = str2num(answer{5});           %Comprimento da bateria em mm
Custo = str2num(answer{6});        %Custo/Preço da bateria em unidade monetária $$
CNC = str2num(answer{7});          %Capacidade Nominal do Carregador [Ah]

if CNC == 0
    CNC = 10;
else
    CNC = CNC;
end
CNC = CNC;

%Entrada dos dados do veículo
prompt = {'Digite o comprimento do local destinado às baterias dentro do veículo, em mm (substitua "," por "."):',...
    'Digite a largura do local destinado às baterias dentro do veículo, em mm (substitua "," por "."):', ...
    'Digite a altura do local destinado às baterias dentro do veículo, em mm (substitua "," por "."):'};
dlgtitle = 'Input';
dims = [1 35];
definput = {'','','',''};
answer = inputdlg(prompt,dlgtitle,dims,definput)
CompCarro = str2num(answer{1});          %Comprimento do compartimento do carro destinado às baterias em mm
LCarro = str2num(answer{2});      %Largura do compartimento do carro destinado às baterias em mm
HCarro = str2num(answer{3});      %Altura do compartimento do carro destinado às baterias em mm

%Entrada do Coeficiente de Segurança CS
prompt = ["Escolha o Fator de Segurança a ser", "utilizado no cálculo de otmização", "da quantidade de baterias:"];
list = {'CS = 0','CS = 10%','CS = 20%','CS = 30%','CS = 40%','CS = 50%'};
[indx,tf] = listdlg('PromptString', prompt,'SelectionMode', 'single', 'ListString', list, 'Listsize', [200 125]);
veiculo = [indx, tf];
if veiculo(1) == 1
    CS = 0;         
    elseif veiculo(1) == 2
    CS = 0.1;         
    elseif veiculo(1) == 3
    CS = 0.2;         
    elseif veiculo(1) == 4
    CS = 0.3;         
    elseif veiculo(1) == 5
    CS = 0.4;         
    elseif veiculo(1) == 6
    CS = 0.5;         
end
CS = CS;   % Coeficiente aerodinâmico final

%Parâmetros usados no cálculo de otimização da quantidade de baterias
EspacoVeiculo = (HCarro*LCarro*CompCarro)/(1000000);   %Volume destinado ao conjunto de baterias no veículo em litros;
VolBat = (LB*hB*cmB)/(1000000);             %Volume de cada bateria litros; 
TempoCarregamento = CNB/CNC;                %Tempo de carregamento total de cada bateria;
DEBat = (CNB*Tensao)/VolBat;                %Densidade de Energia de cada bateria em Wh/l;
TaxaCarregamento = DEBat/(TempoCarregamento*60);       %Em W/l*min;

%Pega os valores de energia consumida e plota os gráficos
ind = zeros();
for i = 1:n
    ind(i) = nearest(find((distdig(i)<=disttraj), 1));   %pega valores recebidos do usuário e procura suas posições no vetor disttraj
    valoresdist(i) = disttraj(ind(i));  %Pega os valores aproximados de distância no vetor disttraj
    valoresEne(i) = Energia(ind(i));          %Pega os valores aproximados de energia no vetor Energia, em Watts 
end
ind = [ind];
valoresdist = [valoresdist];  %armazena os valores de distância
valoresEne = [valoresEne];     %armazena os valores de energia
%Converte vetor em matriz com repetição de valores
nc = 2;  %número de colunas em B
nc = nc-1;
c = 1:(length(ind)-nc);
B = cell2mat(cellfun(@(n) ind(n:(n+nc)), num2cell(c(:)), 'uni', false));
dd = B;    %matriz (n-1)x2 com índices dos valores a serem buscados no vetor da Energia
nnn = size(dd);
linhasnnn = nnn(1);
colunasnnn = nnn(2);
if n == 2
    for i = 2:length(dd)-1
        dd(i,1) = dd(i,1)+1;  %soma 1 aos índices da primeira coluna a partir da linha 2 até a última linha
    end
else  
    for i = 2:length(dd)
        dd(i,1) = dd(i,1)+1;  %soma 1 aos índices da primeira coluna a partir da linha 2 até a última linha
    end
end
dd = dd;   %Matriz com índices iniciais e finais de cada trecho percorrido a serem buscados no vetor Energia
ECons = zeros(length(dd));   %Energia consumida por trecho percorrido
for i = 1:nnn    
    E1indx(i) = dd(i,1);            %Pega o índice do valor da linha i na primeira coluna do vetor dd
    E2indx(i) = dd(i,2);            %Pega o índice do valor da linha i na segunda coluna do vetor dd
    EENN(i) = sum(Energia(E1indx(i):E2indx(i)));  %Encontra e soma a energia consumida em cada trecho percorrido
       %Encontra no vetor Energia os valores que estão entre os índices...
       %...da linha i da primeira coluna...
       %...e da linha i na segunda coluna no vetor Energia e soma os valores... 
       %...de cada intervalo incluindo os valores dos índices iniciais e
       %...finais de cada trecho
    
       %Plota os gráficos com a energia gasta em cada trecho do trajeto
    figure()
    kjk(i) = plot((disttraj(E1indx(i):E2indx(i))),Energia(E1indx(i):E2indx(i)));
    ylabel('Energia (W)')
    xlabel('Tempo decorrido  (horas:minutos:segundos)')
    title({'Energia Consumida no Trecho' num2str(i),...
    ['Energia Total (W): ' num2str(EENN(i))]});
end
ECons = [EENN];   %Energia total consumida em cada trecho percorrido, em Watts
EConssoma = sum(ECons);  %Soma a energia total de todos os trechos, em Watts
EConssomakWh = EConssoma/(1000*3600);  %Soma a energia total de todos os trechos, em kWh

%Plota o gráfico de barras com a energia consumida em cada trecho do...
%...trajeto
figure
hB=bar(ECons);      %Usa a variável Energia no array de plotagem
hT=[];              %Espaço reservado para legenda e rótulo de barras
for i = 1:length(hB)  %iteração sobre o número de barras
    hT = [hT text(hB(i).XData+hB(i).XOffset,hB(i).YData,num2str(hB(i).YData.','%.1f'), ...
                          'VerticalAlignment','bottom','horizontalalign','center')];
    ylabel('Energia (W)')
    xlabel('Trechos Percorridos')
    title({'Energia Consumida por Trecho Percorrido',...
    ['Energia Total (kWh): ' num2str(EConssomakWh)]});
end

%Calcula a quantidade de bateria que seria necessária para se percorrer 
%...todo o trajeto sem a realização de paradas para recarregamento
TotalBatSemOtimizacao = EConssoma/((1-CS)*DEBat);
TotalBatSemOtimizacao = ceil(TotalBatSemOtimizacao);
CustoTotalSemOtimizacao = TotalBatSemOtimizacao*Custo;


%Módulo de Otimização do Código - Está em fase de construção


%Programação Linear com a Otimização da Quantidade de Baterias 
%forma resolução([X,fval,exitflag,output] = intlinprog(FO,intcon, A,b,Aeq,beq,lb,ub, options))
%fval = FO'*x; intcon = posição da variável inteira na função objetivo
%solves min FO'*x; A*x ≤ b; Aeq*x = beq; lb ≤ x ≤ ub; 
%A=[] and b=[] if no inequalities exist; Aeq=[] and beq=[] if no equalities exist
%[FO] Min = Custo*X ;
%Restrições;
%X*VolBat <= EspacoVeiculo;
%Carreg(i) <= TaxaCarregamento*tempodig(i);   !Quantidade de energia carregada em cada parada em W/l por bateria;
%Carreg(i) <= (1-CS)*DEBat;
%i = 1: Estoque(i) = 0;
%i = Nparadas: Estoque(i) = 0;
%i: i até (Nparadas-1): Carreg(i)*X + Estoque(i) - Estoque(i+1) - ConsE(i) >= 0;
%i = Nparadas: Carreg(i)*X + Estoque(i) - ConsE(i) >= 0;
%k = Nparadas = número de paradas
%X = inteiro
Carregamentolimite = [TaxaCarregamento.*tempodig];
Estoque = zeros();
Carreg = zeros();
X = optimvar('X', 'LowerBound', 0, 'Type', 'integer');
prob = optimproblem('Objective', Custo*X);
prob.Constraints.c1 = X*VolBat <= EspacoVeiculo;

prob.Constraints.c2 = Carreg(i) - Carregamentolimite(i) <= 0;
prob.Constraints.c3 = Carreg(i) <= (1-CS)*DEBat;

prob.Constraints.c4 = Estoque(1) == 0;
prob.Constraints.c5 = 0 <= Carreg(i)*X + Estoque(i) - Estoque(i+1) - ConsE(i);  %i = 1:k-1

prob.Constraints.c6 = 0 <= Carreg(k)*X + Estoque(k) - ConsE(k);   %i = k:k
prob.Constraints.c4 = Estoque(k) == 0;

problem = prob2struct(prob);
[X,fval,exitflag,output] = intlinprog(problem)



%Informar o usuário quando a soma das distâncias por ele digitadas não for igual ao total da distância percorrida 
for i = n:n
    if x(i) < disttraj(ndisttraj)
        distdiff = disttraj(ndisttraj)-x(i);
        msgbox(['A distância digitada difere da distância medida por ' num2str(distdiff) 'km'])
    end
end




eeemmm = cumsum(d)/1000;
ind = 10 < eeemmm & eeemmm <= 18.5;  %acha as posições (índices) dos valores do usuário no vetor eeemmm e os intervalos entre eles
AAAAA = eeemmm(ind); %Pega os valores estabelecidos nas posições (índices) identificadas pelo "ind" no vetor eeemmm e os valores entre eles

nnn = length(AAAAA);

val = min(AAAAA)                        %Pega valor mínimo do vetor AAAAA
idxAboveVal = find( eeemmm >= val, 1 )  %Acha o índice do valor mínimo do vetor AAAAA no vetor eeemmm
E1indx = idxAboveVal                    %Fixa o índice do valor mínimo do vetor AAAAA encontrado no vetor eeemmm
val = max(AAAAA)                        %Pega o valor máximo do vetor AAAAA
idxAboveVal = find( eeemmm >= val, 1 )  %Acha o índice do valor máxiimo do vetor AAAAA no vetor eeemmm
E2indx = idxAboveVal                    %Fixa o índice do valor máximo do vetor AAAAA encontrado no vetor eeemmm

EEEEE = Energia(E1indx:E2indx); %Encontra no vetor Energia os valores que estão entre os índices mínimo e máximo, inclusivos, do vetor AAAAA
tttempoooo = tempodecorrido(E1indx:E2indx); %Encontra no vetor tempodecorrido os valores que estão entre os índices mínimo e máximo, inclusivos, do vetor AAAAA
%tempoooo = t(E1indx:E2indx); %Encontra no vetor t os valores que estão entre os índices mínimo e máximo, inclusivos, do vetor AAAAA
%somatempoooo = sum(tempoooo);
EEEEEtotalKW = sum(EEEEE)/1000;   %calcula a energia total em kW
%EEEEEtotalKWH = EEEEEtotalKW/3600;  %Calcula energia em kWh
EEEEEtotalKWH = sum(EEEEE);
figure
plot(tttempoooo,EEEEE)
datetick('x', 13,  'keepticks', 'keeplimits')
ylabel('Energia (W)')
xlabel('Tempo decorrido  (horas:minutos:segundos)')
title({'Energia em Watts', datestr(day),...
    ['Energia Total (W): ' num2str(EEEEEtotalKWH)]});


