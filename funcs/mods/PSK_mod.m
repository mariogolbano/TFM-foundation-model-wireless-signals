function [signal] = PSK_mod(inputBits, modParams)

    M = str2double(modParams.modOrder(1));  % Modulation order, e.g., 2, 4, 8, 16, etc.
    Fs = modParams.symRate;  % Symbol rate (Hz)

    % Ajustar la longitud del bitstream al número de bits por símbolo
    usedInput = inputBits(1:log2(M)*(floor(length(inputBits)/log2(M))));
    symbolInput = bit2int(usedInput, log2(M));

    % Generar modulación PSK
    phaseOffset = pi / M;
    waveform = pskmod(symbolInput, M, phaseOffset, 'gray');
%%
    % Estructura de salida
    signal.type = 'PSK';
    signal.modulation = sprintf('%d-PSK', M);
    signal.sig.real = real(waveform);
    signal.sig.imag = imag(waveform);
    signal.fs = Fs;  % La frecuencia de muestreo se considera igual al símbolo por defecto
    signal.oversamplingFactor = 1;
    signal.cbw = Fs;  % Puedes ajustar esto si tu ancho de banda no es igual al symbolRate
    signal.payload = length(usedInput);
    signal.waveformLength = length(waveform);
    signal.lengthBits = length(inputBits);
%%
end
