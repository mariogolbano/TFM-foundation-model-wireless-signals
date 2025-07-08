function [signal] = QAM_mod(inputBits, modParams)

    M = str2num(modParams.modOrder);  % Modulation order, e.g., 4, 16, 64, 256...
    symbolRate = modParams.symRate;  % Symbol rate (Hz)
    bitsPerSymbol = log2(M);

    % Calcular cuántos bits son necesarios y hacer padding si es necesario
    remainder = mod(length(inputBits), bitsPerSymbol);
    if remainder ~= 0
        padLength = bitsPerSymbol - remainder;
        inputBits = [inputBits; zeros(padLength, 1)];
    end

    % Generar señal QAM
    waveform = qammod(inputBits, M, 'gray', ...
                      'InputType', 'bit', ...
                      'UnitAveragePower', true);

    % Estructura de salida
    signal.type = 'QAM';
    signal.modulation = sprintf('%d-QAM', M);
    signal.sig.real = real(waveform);
    signal.sig.imag = imag(waveform);
    signal.fs = symbolRate;
    signal.oversamplingFactor = 1;
    signal.cbw = symbolRate;
    signal.payload = length(inputBits);  % bits tras padding
    signal.waveformLength = length(waveform);
    signal.lengthBits = length(inputBits) - padLength;  % bits originales

end
