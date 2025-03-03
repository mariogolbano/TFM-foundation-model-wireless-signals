function [signal] = wifiHESU(in_bits, modParams)
% Genera una señal Wifi 802.11 ax High Efficiency SingleUser.
% La función acepta uno de dos parámetros:
% 1. len: La longitud total de la señal Wifi a generar.
% 2. in_bits: Una secuencia de bits de entrada a modular. Debe tener 8*APEPLength (32768) bits como máximo.
    
    cbw = modParams.CBW;
    MCS = modParams.MCS;
    coding = modParams.ChannelCoding;

    % 802.11ax configuration
    heSUCfg = wlanHESUConfig('ChannelBandwidth', cbw, ...
        'NumTransmitAntennas', 1, ...
        'NumSpaceTimeStreams', 1, ...
        'SpatialMapping', 'Direct', ...
        'PreHESpatialMapping', false, ...
        'MCS', MCS, ...
        'DCM', false, ...
        'ChannelCoding', coding, ...
        'APEPLength', 4096, ...
        'GuardInterval', 3.2, ...
        'HELTFType', 4, ...
        'UplinkIndication', false, ...
        'BSSColor', 0, ...
        'SpatialReuse', 0, ...
        'TXOPDuration', 127, ...
        'HighDoppler', false, ...
        'NominalPacketPadding', 0);
    
        
    numPackets = 1;
    
    max_payload_length_bits = 8*getPSDULength(heSUCfg);
    wifi_len = 90960;

    oversampling = 1;

    % Modo: Modula la señal Wifi con los bits de entrada (in_bits)
    fprintf('Mode: Modulating the input bits into a wifi 802.11 ax HESU signal\n')

    niter = ceil(length(in_bits)/max_payload_length_bits);
    sig = [];

    for i = 1:niter
        start_index = (i-1)*max_payload_length_bits + 1;
        end_index = i*max_payload_length_bits;
        in = in_bits(start_index:min(length(in_bits),end_index));
        % Utilizar los bits de entrada proporcionados
        waveform = wlanWaveformGenerator(in, heSUCfg, ...
            'NumPackets', numPackets, ...
            'IdleTime', 0, ...
            'OversamplingFactor', oversampling, ...
            'ScramblerInitialization', 93, ...
            'WindowTransitionTime', 1e-07);
        sig = [sig ; waveform];
    end

    Fs = wlanSampleRate(heSUCfg, 'OversamplingFactor', oversampling); 								 % Specify the sample rate of the waveform in Hz
    
    signal.mod = ['wifiHESU_' MCS];
    signal.type = 'WiFi';
    signal.WiFi = 'HE-SU';
    signal.sig.real = real(sig);
    signal.sig.imag = imag(sig);
    signal.fs = Fs;
    signal.oversamplingFactor = oversampling;
    signal.bw = str2num(extractAfter(cbw, 'CBW')) *1e6;
    signal.channelCoding = heSUCfg.ChannelCoding;
    signal.payload = max_payload_length_bits;
    signal.spaceStreams = heSUCfg.NumSpaceTimeStreams;
    signal.waveformLength = wifi_len;

    signal.MCS = heSUCfg.MCS;
    signal.guardInterval = heSUCfg.GuardInterval;


end
