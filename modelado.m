clc; clear all;
pkg load control;
s = tf('s');

%% Parametros
% Motor
R = 5.9;
L = 0.00025;
B_motor = 0.00000240;
J_motor = 0.000001;
Km = 0.0375;
Ka = 0.0374;
N_box = 40;
% Encoder/Sensor rotativo incremental
N_enc = 1024;
% Cortina
Masa_cortina = 1.336;
Radio_eje = 0.015;
J_cortina = 0.5 * Masa_cortina * (Radio_eje^2);
B_cortina = 0;
% Valores totales de inercia y friccion
J_total = J_motor + (J_cortina / (N_box^2));
B_total = B_motor + (B_cortina / (N_box^2));

%% Funciones de transferencia
% Planta (motor) considerando la caja reductora
N = Km / N_box; % Numerador
D = (L*J_total*s^2) + ((R*J_total + L*B_total)*s) + (R*B_total) + (Km*Ka); %Denominador
% Velocidad angular/tension
G_vel = N/D;
% Posicion angular/tension
G_pos = N/(s*D);
% Conversor de pulsos a voltaje
K_conv = 5 / 521518;
% Driver
K_driver = 4.8;

% Trayectoria directa
disp('Funcion de transferencia de trayectoria directa');
G_total = minreal(K_conv * K_driver * G_pos);

% Sensor (Realimentacion)
H = N_enc * N_box / (2*pi);

% Funcion de transferencia a lazo abierto
disp('Funcion de transferencia a lazo abierto');
FTLA = G_total*H

% Polos de la funcion de transferencia a lazo abierto
disp('Polos de la funcion de transferencia a lazo abierto');
pole(FTLA)
disp('2 Polos con parte real negativa y 1 polo simple en el origen, entonces el sistema es marginalmente estable');
disp('Polo dominante s=-221.5')

% Respuesta de la planta (velocidad) ante un escalón de tensión nominal (24V).
V_nom = 24; % Tension nominal del motor

figure;
step(V_nom * G_vel, 0.1);
grid on;

%% Diseño del controlador PD
% Simplificacion del modelo matematico de la planta G_vel
% Obtencion de la ganancia estática
[num_v, den_v] = tfdata(G_vel, 'v');
K_DC = num_v(end) / den_v(end);
p_mecanico = 221.5;
% A partir de la ganancia estatica se calcula la ganancia equivalente K_eq
K_eq = K_DC * p_mecanico;

% Especificaciones de diseño
ts_req = 8;                 % Tiempo de asentamiento
s_dom = 4 / ts_req;         % Ubicación del polo dominante de lazo cerrado (Criterio 4 tau)

% Cálculo de Ganancia Proporcional (Kp)
% Ganancia total de la cadena directa: K_total = K_conv * K_driver * H * K_eq
K_total_loop = K_conv * K_driver * H * K_eq;

% Usando la aproximación para sistemas sobreamortiguados donde el polo dominante
% se define por el término independiente y el coeficiente lineal de la ec. característica:
Kp = (s_dom * p_mecanico) / K_total_loop;
fprintf('Ganancia Proporcional (Kp) calculada: %.1f\n', Kp);

% Cálculo de Acción Derivativa (Kd)
% Ubicación del cero del PD una década más lejos que el polo dominante
z_pd = 10 * s_dom;
Kd = Kp / z_pd;
fprintf('Ganancia Derivativa (Kd) calculada: %.1f\n', Kd);

% Definición del Controlador C(s) = Kp + Kd*s
C = tf([Kd, Kp], 1);

%% Sistema Controlado

% Trayectoria directa con controlador
% Estructura: Error -> K_conv -> C(s) -> K_driver -> Planta(G_pos)
G_controlado = K_conv * C * K_driver * G_pos;

% Función de transferencia a Lazo Cerrado (T_closed)
% Entrada: Setpoint (pulsos) -> Salida: Posición (rad)
FTLC = feedback(G_controlado, H);

%% Simulación y Gráfico de Respuesta Temporal
input_pulses = 521518;  % Cantidad de pulsos para un recorrido total 1.2m

% Generación de la respuesta
figure;
step(input_pulses * FTLC, 25);
grid on;
