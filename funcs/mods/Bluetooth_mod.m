function [signal] = bt1(varargin)
% Genera una señal Bluetooth BR/EDR.
% La función acepta uno de dos parámetros:
% 1. len: La longitud total de la señal Bluetooth a generar.
% 2. in_bits: Una secuencia de bits de entrada a modular. Debe tener exactamente 224 bits.

    % Bluetooth BR/EDR configuration
    bluetoothCfg = bluetoothWaveformConfig('Mode', 'BR', ...
        'PacketType', 'DM5', ...
        'LogicalTransportAddress', [0;0;1], ...
        'HeaderControlBits', [1;1;1], ...
        'ModulationIndex', 0.32, ...
        'SamplesPerSymbol', 8, ...
        'WhitenInitialization', [1;1;1;1;1;1;1], ...
        'LLID', [1;1], ...
        'FlowIndicator', true);

    bluetoothCfg.PayloadLength = 224;
    bluetoothCfg.WhitenStatus = 'On';
    bluetoothCfg.DeviceAddress = '0123456789AB';
    
    payloadLength = getPayloadLength(bluetoothCfg);
    max_payload_length_bits = 8 * payloadLength;
    % Definir longitud máxima del payload para el paquete DM5
    bt_len = 22968; % Longitud del paquete Bluetooth en muestras

    % Verificar los parámetros de entrada
    if length(varargin) == 1 && isscalar(varargin{1})
        % Modo: Generar señal Bluetooth con longitud especificada (len)
        len = varargin{1};
        %fprintf('Mode: Generating a bluetooth signal of %d samples\n', len)
        n_iters = ceil(len / bt_len);
        use_input_bits = false;
    elseif isvector(varargin{1})
        % Modo: Modula la señal Bluetooth con los bits de entrada (in_bits)
        %fprintf('Mode: Modulating the input bits into a bluetooth signal\n')

        in_bits = varargin{1};
        use_input_bits = true;
    else
        error('Only 1 of the 2 following parameters accepted as input: Length of the bluetooth signal to generate (int) or a sequence of bits of %d bits max for modulating the signal\n\n', max_payload_length_bits)
    end

    % Inicializar la señal Bluetooth
    if ~use_input_bits
        bt = zeros(len, 1);
        for i = 1:n_iters
            % Generar bits de entrada aleatorios
            in = randi([0 1], max_payload_length_bits, 1);
            % Generar la señal Bluetooth
            waveform = bluetoothWaveformGenerator(in, bluetoothCfg);
            filterSpan = 8 * any(strcmp(bluetoothCfg.Mode, {'EDR2M', 'EDR3M'}));
            packetDuration = bluetoothPacketDuration(bluetoothCfg.Mode, bluetoothCfg.PacketType, payloadLength);
            waveform = waveform(1:(packetDuration + filterSpan) * bluetoothCfg.SamplesPerSymbol);
            bt((i-1)*bt_len + 1:min(i*bt_len, len)) = waveform(1:min(bt_len, len - (i-1)*bt_len));
        end
        sig = bt(1:len);
    else
        niter = ceil(length(in_bits)/max_payload_length_bits);
        sig = [];
        lengthBits = length(in_bits);
        in_bits = [in_bits; zeros(niter*max_payload_length_bits - length(in_bits), 1)];
        for i = 1:niter
            start_index = (i-1)*max_payload_length_bits + 1;
            end_index = i*max_payload_length_bits;
            in = in_bits(start_index:end_index);
            % Utilizar los bits de entrada proporcionados
            waveform = bluetoothWaveformGenerator(double(in), bluetoothCfg);
            filterSpan = 8 * any(strcmp(bluetoothCfg.Mode, {'EDR2M', 'EDR3M'}));
            packetDuration = bluetoothPacketDuration(bluetoothCfg.Mode, bluetoothCfg.PacketType, payloadLength);
            waveform = waveform(1:(packetDuration + filterSpan) * bluetoothCfg.SamplesPerSymbol);
            sig = [sig ; waveform];
        end
    end
    
    Fs = bluetoothCfg.SamplesPerSymbol*10^06; 								 % Specify the sample rate of the waveform in Hz
    
    signal.mod = 'bluetooth1';
    signal.type = 'Bluetooth';
    signal.sig.real = real(sig);
    signal.sig.imag = imag(sig);
    signal.fs = Fs;
    signal.oversamplingFactor = bluetoothCfg.SamplesPerSymbol;
    signal.bw = 1e6;    
    signal.channelCoding = '';
    signal.payload = max_payload_length_bits;
    signal.spaceStreams = 1;
    signal.waveformLength = bt_len;
    
    switch bluetoothCfg.Mode
        case 'BR'
            signal.Bluetooth = 'BR';
            signal.modulation = 'GFSK';
            signal.modIndex = bluetoothCfg.ModulationIndex;
        case 'EDR2M'
            signal.Bluetooth = 'ERR2M';
            signal.modulation = 'pi/4 DQPSK';
        case 'EDR3M'
            signal.Bluetooth = 'EDR3M';
            signal.modulation = '8-DPSK';
    end
    signal.lengthBits = lengthBits;

end
