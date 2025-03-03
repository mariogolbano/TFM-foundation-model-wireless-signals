function [signal] = wifiNonHT(in_bits, modParams)
% Genera una señal Wifi 802.11 ab Non-high Throughput.
% La función acepta uno de dos parámetros:
% 1. len: La longitud total de la señal Wifi a generar.
% 2. in_bits: Una secuencia de bits de entrada a modular. Debe tener 8*APEPLength (32768) bits como máximo.
    
    dataRate = modParams.DataRate;
    
    % 802.11b/g (DSSS) configuration
    dsssCfg = wlanNonHTConfig('Modulation', 'DSSS', ...
        'DataRate', dataRate, ...
        'Preamble', 'Long', ...
        'LockedClocks', true, ...
        'PSDULength', 4095);    
    
    numPackets = 1;
    
    max_payload_length_bits = 8*dsssCfg.PSDULength;
    switch dataRate
        case '1Mbps'
            wifi_len = 362472;
        case '2Mbps'
            wifi_len = 182292;
        case '5.5Mbps'
            wifi_len = 67632;
        case '11Mbps'
            wifi_len = 34872;
    end

    oversampling = 1;
    
    % Modo: Modula la señal Wifi con los bits de entrada (in_bits)
    fprintf('Mode: Modulating the input bits into a Wifi 802.11 ab NonHT signal\n')

    niter = ceil(length(in_bits)/max_payload_length_bits);
    sig = [];

    for i = 1:niter
        start_index = (i-1)*max_payload_length_bits + 1;
        end_index = i*max_payload_length_bits;
        in = in_bits(start_index:min(length(in_bits),end_index));
        % Utilizar los bits de entrada proporcionados
        waveform = wlanWaveformGenerator(in, dsssCfg, ...
            'NumPackets', numPackets, ...
            'IdleTime', 0);
        sig = [sig ; waveform];
    end

    Fs = wlanSampleRate(dsssCfg); 								 % Specify the sample rate of the waveform in Hz
    
    signal.mod = ['wifiNonHT_' dataRate] ;
    signal.type = 'WiFi';
    signal.WiFi = 'NonHT';
    signal.sig.real = real(sig);
    signal.sig.imag = imag(sig);
    signal.fs = Fs;
    signal.oversamplingFactor = oversampling;
    signal.bw = 20e6;
    signal.dataRate = dsssCfg.DataRate;
    switch dsssCfg.DataRate
        case '1Mbps'
            signal.modulation = 'DBPSK';
        case '2Mbps'
            signal.modulation = 'DQPSK';
        case '5.5Mbps'
            signal.modulation = 'CCK';
        case '11Mbps'
            signal.modulation = 'CCK';
    end
    signal.payload = max_payload_length_bits;
    signal.spaceStreams = dsssCfg.NumTransmitAntennas;
    signal.waveformLength = wifi_len;
    signal.MCS = dsssCfg.MCS;



end
