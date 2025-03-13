function [demodulatedBits] = demodulateSignal(receivedSignal, modParams)
    % demodulateSignal - Llama dinámicamente a la función de demodulación correspondiente
    % receivedSignal: La señal recibida (compleja)
    % modParams: struct con los parámetros de modulación
    %
    % Output:
    % demodulatedBits: Vector de bits demodulados

    % Extraer el tipo de modulación desde modParams
    modulationType = modParams.type; 

    % Construir el nombre de la función de demodulación
    demodFunction = [modulationType, '_demod'];

    % Verificar si la función existe antes de llamarla
    if exist(demodFunction, 'file') == 2
        demodulatedBits = feval(demodFunction, receivedSignal, modParams);
    else
        error('Demodulation function "%s" does not exist.', demodFunction);
    end
end
