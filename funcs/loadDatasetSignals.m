function signals = loadDatasetSignals(filename, numSamples)
    % Cargar señales o bits desde un dataset HDF5
    % filename: Nombre del archivo HDF5
    % numSamples: Número de señales a cargar (si es mayor que las disponibles, se cargan todas)

    % Verificar si el archivo existe
    if ~isfile(filename)
        error('The specified file does not exist: %s', filename);
    end

    % Obtener información del dataset
    info = h5info(filename, '/dataset');
    dataSize = info.Dataspace.Size;
    
    % Determinar el número total de señales en el dataset (última dimensión)
    numAvailableSamples = dataSize(end);

    % Comprobar si se solicitan más señales de las disponibles
    if numSamples > numAvailableSamples
        warning('Requested %d samples, but only %d are available. Loading all available samples.', ...
                numSamples, numAvailableSamples);
        numSamples = numAvailableSamples;
    end

    % Crear parámetros START y COUNT dinámicamente
    start = ones(1, length(dataSize));   % Empieza desde el primer elemento en cada dimensión
    count = dataSize;                    % Inicialmente toma todo
    count(end) = numSamples;             % Ajustar la cantidad de muestras a leer
    
    % Leer los datos desde el archivo HDF5
    rawData = h5read(filename, '/dataset', start, count);

    % Determinar si los datos son señales complejas o bits
    if length(dataSize) > 1 && dataSize(2) == 2
        % Si hay 2 canales en la segunda dimensión, significa que tenemos (real, imag)
        signals = rawData(:,1,:) + 1j * rawData(:,2,:);
    else
        % Si hay 1 solo canal, cargamos los bits tal cual
        signals = rawData;
    end

    % Asegurar que la salida tenga dimensiones correctas
    signals = squeeze(signals); % Eliminar dimensiones singleton
end
