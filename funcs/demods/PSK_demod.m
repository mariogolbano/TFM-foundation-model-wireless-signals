function [demodulatedBits] = PSK_demod(receivedSignal, modParams)
    % PSK_demod - Demodula una señal PSK basada en los parámetros de modulación

    % Extraer orden de modulación
    M = str2num(modParams.modulation(1));  % e.g., 2, 4, 8, 16, etc.
    bitsPerSymbol = log2(M);
    bits_length = modParams.lengthBits;

    % Demodular señal
    phaseOffset = pi / M;
    rxSymbols = pskdemod(receivedSignal, M, phaseOffset, 'gray');

    % Convertir a bits
    demodulatedBits = int2bit(rxSymbols, bitsPerSymbol);

    % Recortar a longitud original
    demodulatedBits = int8(demodulatedBits(1:bits_length));
end
