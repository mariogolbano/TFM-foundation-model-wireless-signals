function [signal] = DSSS_mod(inputBits, modParams)
    
    dataRate = modParams.DataRate;
    % Seleccionar el código de dispersión y la modulación según el data rate
    switch dataRate
        case '1Mbps'  % 1 Mbps - DBPSK con código Barker
            rate = 1;
            modulation = 'DBPSK';
            spreadingCode = [1 1 1 -1 1 1 -1 1 1 -1 -1]'; % Código Barker de 11 chips
            modulatedSymbols = 2 * inputBits - 1;  % BPSK (DBPSK en la implementación real)
            
        case '2Mbps'  % 2 Mbps - DQPSK con código Barker
            rate = 2;
            modulation = 'DQPSK';
            spreadingCode = [1 1 1 -1 1 1 -1 1 1 -1 -1]'; % Código Barker de 11 chips
            
            if mod(length(inputBits), 2) ~= 0
                inputBits = [inputBits; 0];
            end

            inPhase = 2 * inputBits(1:2:end) - 1;  % Bits impares -> eje I (In-Phase)
            quadrature = 2 * inputBits(2:2:end) - 1;  % Bits pares -> eje Q (Quadrature)
            
            modulatedSymbols = inPhase + 1i * quadrature;  % Construcción de símbolos QPSK
            
        case {'5.5Mbps', '11Mbps'}  % 5.5 Mbps y 11 Mbps - CCK
            modulation = 'CCK';
            modulatedSymbols = cck_chips(inputBits, dataRate);  % Modulación CCK
            spreadingCode = [];  % No se usa código Barker en CCK

        otherwise
            error('Datarate not allowed. Use 1Mbps, 2Mbps, 5.5Mbps, or 11Mbps.');
    end
    
    % Si se usa DSSS (1 y 2 Mbps), aplicar el código de dispersión
    if ~isempty(spreadingCode)
        seqLen = length(spreadingCode);
        chips = spreadingCode * modulatedSymbols';  % Aplicar la dispersión
        txWaveform = reshape(chips, seqLen * length(inputBits) / rate, 1);  % Reorganizar como columna
    else
        txWaveform = modulatedSymbols;  % En CCK, los chips ya están generados
    end

    signal.type = 'DSSS';
    signal.DSSS = dataRate;
    signal.modulation = modulation;
    signal.sig.real = real(txWaveform);
    signal.sig.imag = imag(txWaveform);
    signal.fs = 11e6;
    signal.oversamplingFactor = 1;
    signal.bw = 20e6;
    signal.payload = length(inputBits);
    signal.waveformLength = length(txWaveform);

end
