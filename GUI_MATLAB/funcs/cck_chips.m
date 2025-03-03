function cckChips = cck_chips(inputBits, dataRate)
    % Verifica que el data rate sea válido
    if ~strcmp(dataRate,'5.5Mbps') && ~strcmp(dataRate,'11Mbps')
        error('CCK solo es válido para 5.5 Mbps y 11 Mbps');
    end

    % Define cuántos bits se usan en la fase
    if strcmp(dataRate,'5.5Mbps')
        bitsPerSymbol = 4;
    else
        bitsPerSymbol = 8;
    end

    % Asegurar que la longitud de inputBits es un múltiplo de bitsPerSymbol
    if mod(length(inputBits), bitsPerSymbol) ~= 0
        dif = bitsPerSymbol - mod(length(inputBits), bitsPerSymbol);
        inputBits = [inputBits zeros(1, dif)];
    end

    % Convertir bits a valores -1 y 1 (BPSK en fase diferencial)
    numSymbols = length(inputBits) / bitsPerSymbol;
    cckChips = zeros(numSymbols, 8);  % Matriz para almacenar chips

    prevPhi1 = 0; % Fase diferencial inicial

    for i = 1:numSymbols
        % Extraer los bits de fase para este símbolo
        bits = inputBits((i-1)*bitsPerSymbol + (1:bitsPerSymbol));

        % Convertir bits a ángulos de fase (DQPSK)
        phi1 = prevPhi1 + pi * (2 * bits(1) - 1);  % Fase diferencial
        phi2 = pi/2 * (2 * bits(2) - 1); 
        phi3 = pi/2 * (2 * bits(3) - 1);
        phi4 = 0;
        
        % Si es 11 Mbps, usar phi4 (bits extra)
        if strcmp(dataRate,'11Mbps')
            phi4 = pi/2 * (2 * bits(4) - 1);
        end

        % Calcular los 8 chips de CCK según la ecuación
        cckChips(i, :) = exp(1j * [...
            phi1, ...
            phi1 + phi2, ...
            phi1 + phi3, ...
            phi1 + phi2 + phi3, ...
            phi1 + phi4, ...
            phi1 + phi2 + phi4, ...
            phi1 + phi3 + phi4, ...
            phi1 + phi2 + phi3 + phi4]);

        % Actualizar la fase diferencial
        prevPhi1 = phi1;
    end

    % Convertir a un solo vector (ordenado para transmisión)
    cckChips = reshape(cckChips.', [], 1);
end
