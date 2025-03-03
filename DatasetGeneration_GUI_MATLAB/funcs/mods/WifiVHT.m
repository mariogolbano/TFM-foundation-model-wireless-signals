function [signal] = wifiVHT(in_bits, modParams)
% Genera una señal Wifi 802.11 n/ac Very High Throughput.
% La función acepta uno de dos parámetros:
% 1. len: La longitud total de la señal Wifi a generar.
% 2. in_bits: Una secuencia de bits de entrada a modular. Debe tener 8*APEPLength (32768) bits como máximo.
    
    cbw = modParams.CBW;
    MCS = modParams.MCS;
    coding = modParams.ChannelCoding;

    % 802.11n/ac (OFDM) configuration
    vhtCfg = wlanVHTConfig('ChannelBandwidth', cbw, ...
        'NumUsers', 1, ...
        'NumTransmitAntennas', 1, ...
        'NumSpaceTimeStreams', 1, ...
        'SpatialMapping', 'Direct', ...
        'STBC', false, ...
        'MCS', MCS, ...
        'ChannelCoding', coding, ...
        'APEPLength', 4096, ...
        'GuardInterval', 'Long', ...
        'GroupID', 63, ...
        'PartialAID', 275);
    
    numPackets = 1;
    
    max_payload_length_bits = 8*vhtCfg.PSDULength;
    wifi_len = 93120;

    oversampling = 1;

    % Modo: Modula la señal Wifi con los bits de entrada (in_bits)
    fprintf('Mode: Modulating the input bits into a Wifi 802.11 n/ac VHT signal\n')

    niter = ceil(length(in_bits)/max_payload_length_bits);
    sig = [];

    for i = 1:niter
        start_index = (i-1)*max_payload_length_bits + 1;
        end_index = i*max_payload_length_bits;
        in = in_bits(start_index:min(length(in_bits),end_index));
        % Utilizar los bits de entrada proporcionados
        waveform = wlanWaveformGenerator(in, vhtCfg, ...
            'NumPackets', numPackets, ...
            'IdleTime', 0, ...
            'OversamplingFactor', oversampling, ...
            'ScramblerInitialization', 93, ...
            'WindowTransitionTime', 1e-07);
        sig = [sig ; waveform];
    end

    Fs = wlanSampleRate(vhtCfg, 'OversamplingFactor', oversampling); 								 % Specify the sample rate of the waveform in Hz
    
    signal.mod = ['wifiVHT_' MCS];
    signal.type = 'WiFi';
    signal.WiFi = 'VHT';
    signal.sig.real = real(sig);
    signal.sig.imag = imag(sig);
    signal.fs = Fs;
    signal.oversamplingFactor = oversampling;
    signal.bw = 80e6;
    signal.channelCoding = vhtCfg.ChannelCoding;
    signal.guardInterval = vhtCfg.GuardInterval;
    signal.payload = max_payload_length_bits;
    signal.spaceStreams = vhtCfg.NumSpaceTimeStreams;
    signal.waveformLength = wifi_len;

    signal.MCS = vhtCfg.MCS;



end
