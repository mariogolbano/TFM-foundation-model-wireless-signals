function [signals, datasetAttributes] = loadDatasetSignals_selection(filename, selectedIndices)
    % Cargar señales o bits desde un dataset HDF5
    % filename: Nombre del archivo HDF5
    % selectedIndices: Índices de las señales a cargar

    % Verificar si el archivo existe
    if ~isfile(filename)
        error('The specified file does not exist: %s', filename);
    end

    % Obtener información del dataset
    info = h5info(filename, '/dataset');
    dataSize = info.Dataspace.Size;
    
    % Obtener atributos del dataset
    datasetAttributes = struct();
    datasetAttributes.FrameSize = h5readatt(filename, '/dataset', 'FrameSize');

    % Asegurar que los índices no excedan el total disponible
    numAvailableSamples = dataSize(end);
    if any(selectedIndices > numAvailableSamples) || any(selectedIndices < 1)
        error('Selected indices out of range.');
    end

    % Número de dimensiones en el dataset
    numDims = length(dataSize);

    % Inicializar la variable para almacenar los datos
    signals = [];

    % Leer cada señal de manera individual usando los índices seleccionados
    for i = 1:length(selectedIndices)
        index = selectedIndices(i);
        start = ones(1, numDims); % Inicio en todas las dimensiones
        start(end) = index; % Ajustar solo la dimensión de las señales
        count = dataSize;
        count(end) = 1; % Leer solo una muestra en esa dimensión
        
        % Leer la señal individualmente y concatenarla
        rawData = h5read(filename, '/dataset', start, count);
        
        % Determinar si los datos son señales complejas o bits
        if length(dataSize) > 1 && dataSize(2) == 2
            signal = rawData(:,1,:) + 1j * rawData(:,2,:);
        else
            signal = rawData;
        end
        
        % Agregar la señal procesada a la salida
        signals = cat(2, signals, squeeze(signal)); % Concatenar como nueva columna
    end
end
