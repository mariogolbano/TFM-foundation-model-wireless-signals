function [signal] = OFDM_mod(in_bits, modParams)
    % Definir índices de modulación válidos
    mod_indexes = [2, 4, 16, 64, 256, 1024]; 

    % Extraer parámetros desde modParams
    fft_length = modParams.FFTLength;
    cyclicprefix = modParams.cyclicPrefixLength;
    numsymbs = modParams.numSymbols;
    scs = modParams.subcarrierSpacing;
    insertDCnull = modParams.DCnull;
    modulation_type = modParams.modulation; % Ejemplo: 'BPSK', 'QPSK', '16QAM', etc.

    % Determinar el índice de modulación
    switch modulation_type
        case 'BPSK'
            M = 2;
        case 'QPSK'
            M = 4;
        case '16QAM'
            M = 16;
        case '64QAM'
            M = 64;
        case '256QAM'
            M = 256;
        case '1024QAM'
            M = 1024;
        otherwise
            error('Modulation type not recognized.');
    end

    % Validar el índice de modulación
    if ~ismember(M, mod_indexes)
        error('Modulation index not accepted. Must be one of: 2, 4, 16, 64, 256, 1024');
    end

    % Configuración del modulador OFDM
    ofdmMod = comm.OFDMModulator('FFTLength', fft_length, ...
        'NumGuardBandCarriers', [6;5], ...
        'InsertDCNull', insertDCnull, ...
        'CyclicPrefixLength', cyclicprefix, ...
        'Windowing', false, ...
        'OversamplingFactor', 1, ...
        'NumSymbols', numsymbs, ...
        'NumTransmitAntennas', 1, ...
        'PilotInputPort', false);
    
    len_bits = (fft_length - ofdmMod.NumGuardBandCarriers(1) - ofdmMod.NumGuardBandCarriers(2) - insertDCnull) * ofdmMod.NumSymbols * log2(M);
    
    sig = [];
    if length(in_bits) > len_bits
        niter = ceil(length(in_bits) / len_bits);
    else
        niter = 1;
    end

    for i = 1:niter
        start_index = (i - 1) * len_bits + 1;
        end_index = min(i * len_bits, length(in_bits));
        in = in_bits(start_index:end_index);
    
        % Rellenar con ceros si es necesario
        if length(in) < len_bits
            in = [in; zeros(len_bits - length(in), 1)];
        end
    
        % Modulación según el tipo seleccionado
        if M == 2 
            usedInput = in(1:log2(M) * (floor(length(in) / log2(M))));
            symbolInput = bit2int(usedInput, log2(M));
            
            phaseOffset = 0;
            dataInput = pskmod(symbolInput, M, phaseOffset, 'gray');
            modulation = 'BPSK';
    
        elseif M == 4
            usedInput = in(1:log2(M) * (floor(length(in) / log2(M))));
            symbolInput = bit2int(usedInput, log2(M));
            
            phaseOffset = pi / M;
            dataInput = pskmod(symbolInput, M, phaseOffset, 'gray');
            modulation = 'QPSK';
        else
            dataInput = qammod(in, M, 'gray', 'InputType', 'bit', 'UnitAveragePower', true);
            modulation = [num2str(M) 'QAM'];
        end
    
        ofdmInfo = info(ofdmMod);
        ofdmSize = ofdmInfo.DataInputSize;
    
        % Asegurar que el tamaño de dataInput sea compatible con ofdmSize
        if length(dataInput) < prod(ofdmSize)
            dataInput = [dataInput; zeros(prod(ofdmSize) - length(dataInput), 1)];
        end
        dataInput_reshape = reshape(dataInput, ofdmSize);
        
        % Generar la waveform
        waveform = ofdmMod(dataInput_reshape);
        sig = [sig ; waveform];

        if i==1
            wf_len = length(waveform);
        end
        
    end
    
    Fs = ofdmMod.FFTLength * scs * ofdmMod.OversamplingFactor; % Sample rate en Hz
    
    % Almacenar en la estructura de salida
    signal.mod = ['OFDM_' modulation_type];
    signal.type = 'OFDM';
    signal.modulation = modulation;
    signal.sig.real = real(sig);
    signal.sig.imag = imag(sig);
    signal.fs = Fs;
    signal.oversamplingFactor = ofdmMod.OversamplingFactor;
    signal.cbw = 20e6;
    signal.payload = len_bits;
    signal.waveformLength = wf_len;
    signal.cyclicPrefixLength = ofdmMod.CyclicPrefixLength;
    signal.FFTLength = ofdmMod.FFTLength;
    signal.guardBandCarriers = ofdmMod.NumGuardBandCarriers;
    signal.numSymbols = ofdmMod.NumSymbols;
    signal.subcarrierSpacing = scs;
    signal.DCnull = ofdmMod.InsertDCNull;
    signal.lengthBits = length(in_bits);

end
