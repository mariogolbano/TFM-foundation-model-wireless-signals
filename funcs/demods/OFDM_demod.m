function [demodulatedBits] = OFDM_demod(receivedSignal, modParams)
    % OFDM_demod - Demodula una señal OFDM basada en la metadata almacenada en un archivo .mat
    % signal: Estructura que contiene la señal recibida con real e imaginaria separadas
    % modParams: struct with all params. Loaded from mat metadata file.
    
    % Extraer parámetros relevantes
    fft_length = modParams.FFTLength;
    cyclicprefix = modParams.cyclicPrefixLength;
    numsymbs = modParams.numSymbols;
    scs = modParams.subcarrierSpacing;
    insertDCnull = modParams.DCnull;
    bitsPerBlock = modParams.payload;
    wf_len = modParams.waveformLength; % 8000 muestras por bloque
    bits_length = modParams.lengthBits;
    
    if isequal(modParams.modulation, 'BPSK')
        M = 2;
    elseif isequal(modParams.modulation, 'QPSK')
        M = 4;
    else
        M = str2double(extractBefore(modParams.modulation, 'Q'));
    end

    % Crear el objeto OFDM demodulador con los mismos parámetros
    ofdmDemod = comm.OFDMDemodulator('FFTLength', fft_length, ...
        'NumGuardBandCarriers', modParams.guardBandCarriers, ...
        'CyclicPrefixLength', cyclicprefix, ...
        'NumSymbols', numsymbs, ...
        'NumReceiveAntennas', 1, ...
        'PilotOutputPort', false);
    
    % Determinar el número total de bloques de OFDM a procesar
    numBlocks = floor(length(receivedSignal) / wf_len);
    demodulatedBits = [];
    
    for i = 1:numBlocks
        % Extraer un bloque de 8000 muestras
        startIdx = (i - 1) * wf_len + 1;
        endIdx = min(i * wf_len, length(receivedSignal));
        rxBlock = receivedSignal(startIdx:endIdx);
        
        % Demodular OFDM
        rxSymbols = ofdmDemod(rxBlock);
        rxSymbols = rxSymbols(:); % Convertir a vector columna
        
        % Demodular según el esquema de modulación
        switch M
            case 2
                phaseOffset = 0;
                rxBits = int2bit(pskdemod(rxSymbols, M, phaseOffset, 'gray'), log2(M));
            case 4
                phaseOffset = pi / M;
                rxBits = int2bit(pskdemod(rxSymbols, M, phaseOffset, 'gray'), log2(M));
            otherwise
                rxBits = qamdemod(rxSymbols, M, 'gray', 'OutputType', 'bit', 'UnitAveragePower', true);
        end

        
        % Acumular bits demodulados
        demodulatedBits = [demodulatedBits; rxBits];
    end
    
    demodulatedBits = int8(demodulatedBits(1:bits_length));
end
