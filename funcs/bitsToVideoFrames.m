function frames = bitsToVideoFrames(bitstream, frameSize)
    % bitsToVideoFrames - Convierte una secuencia de bits en una secuencia de frames de video.
    % bitstream: Vector de bits en formato (N_frames * frameSize^2 * 8)
    % frameSize: Tamaño de cada frame en formato [height, width]
    %
    % Output:
    % frames: Celda con cada frame reconstruido en escala de grises.

    % Verificar que frameSize es un vector de dos elementos enteros
    if ~isvector(frameSize) || length(frameSize) ~= 2
        error('frameSize must be a 2-element vector [height, width].');
    end
    
    % Extraer el número de frames
    pixelsPerFrame = prod(frameSize); % height * width
    bitsPerFrame = pixelsPerFrame * 8; % 8 bits por pixel

    numFrames = floor(length(bitstream) / bitsPerFrame);
    
    if numFrames == 0
        error('Bitstream does not contain enough data for a single frame.');
    end

    frames = cell(1, numFrames); % Inicializar celda de frames

    for i = 1:numFrames
        % Extraer los bits correspondientes a este frame
        bitStart = (i - 1) * bitsPerFrame + 1;
        bitEnd = bitStart + bitsPerFrame - 1;
        frameBits = bitstream(bitStart:bitEnd);

        % Convertir bits a valores de píxeles (8 bits -> 1 pixel)
        framePixels = uint8(bin2dec(char(reshape(frameBits, 8, []).' + '0')));

        % Asegurar que el reshape sea válido
        if numel(framePixels) == pixelsPerFrame
            frames{i} = reshape(framePixels, frameSize(1), frameSize(2));
        else
            warning('Frame %d has incorrect number of pixels. Skipping.', i);
            frames{i} = [];
        end
    end
end
