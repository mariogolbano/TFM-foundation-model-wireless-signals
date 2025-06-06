function [demodulatedBits] = QAM_demod(receivedSignal, modParams)
    % QAM_demod - Demodula una señal QAM basada en los parámetros de modulación

    % Extraer orden de modulación desde el campo de texto (ej. '16-QAM')
    M = str2double(extractBefore(modParams.modulation, '-'));  % e.g., '16-QAM' → 16
    bitsPerSymbol = log2(M);
    bits_length = modParams.lengthBits;

    % Demodular señal QAM
    rxBits = qamdemod(receivedSignal, M, 'gray', ...
                      'OutputType', 'bit', ...
                      'UnitAveragePower', true);

    % Recortar a longitud original
    demodulatedBits = int8(rxBits(1:bits_length));
end
