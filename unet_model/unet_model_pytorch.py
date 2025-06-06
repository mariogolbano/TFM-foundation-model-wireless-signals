import torch
import torch.nn as nn
import torch.nn.functional as F

class UNet1D(nn.Module):
    """
    1D U-Net architecture for signal denoising or reconstruction tasks.

    This network consists of:
    - An encoder path with downsampling
    - A bottleneck (middle) block
    - A decoder path with upsampling and skip connections
    - A final output layer

    Parameters:
    -----------
    input_channels : int
        Number of input channels in the signal (e.g., 2 for I/Q data).
    output_channels : int
        Number of output channels (typically same as input for reconstruction).
    k_sz : int
        Kernel size for most convolutional layers.
    long_k_sz : int
        Larger kernel size for the first convolutional layer to capture long-range dependencies.
    k_neurons : int
        Base number of filters to scale the channel dimensions.
    """
    def __init__(self, input_channels, output_channels, k_sz=3, long_k_sz=101, k_neurons=32):
        super(UNet1D, self).__init__()

        self.encoders = nn.ModuleList()
        self.pools = nn.ModuleList()
        self.decoders = nn.ModuleList()
        self.upsamples = nn.ModuleList()
        
        # ========== Encoder Path ==========
        k_list = [8, 8, 8, 8, 8]  # Number of filter multipliers per layer
        for i, k in enumerate(k_list):
            if i == 0:
                # First encoder block uses a large kernel to capture broader context
                self.encoders.append(nn.Sequential(
                    nn.Conv1d(input_channels, k_neurons * k, long_k_sz, padding=long_k_sz // 2),
                    nn.ReLU(),
                    nn.Conv1d(k_neurons * k, k_neurons * k, k_sz, padding=k_sz // 2),
                    nn.ReLU()
                ))
            else:
                self.encoders.append(nn.Sequential(
                    nn.Conv1d(k_neurons * k_list[i-1], k_neurons * k, k_sz, padding=k_sz // 2),
                    nn.ReLU(),
                    nn.Conv1d(k_neurons * k, k_neurons * k, k_sz, padding=k_sz // 2),
                    nn.ReLU()
                ))
            # Downsampling and dropout
            self.pools.append(nn.Sequential(
                nn.MaxPool1d(2),
                nn.Dropout(0.25 if i == 0 else 0.5)
            ))

        # ========== Bottleneck (Middle Block) ==========
        self.middle = nn.Sequential(
            nn.Conv1d(k_neurons * 8, k_neurons * 8, k_sz, padding=k_sz // 2),
            nn.ReLU(),
            nn.Conv1d(k_neurons * 8, k_neurons * 8, k_sz, padding=k_sz // 2),
            nn.ReLU()
        )
        
        # ========== Decoder Path ==========
        k_decoder_list = [8, 8, 4, 2, 1]  # Channel scaling for decoder layers
        last_k = 8  # Start with the last encoder output channel multiplier
        for i, k in enumerate(k_decoder_list):
            # Upsampling with transposed convolution
            self.upsamples.append(nn.ConvTranspose1d(
                in_channels=k_neurons * last_k,
                out_channels=k_neurons * k,
                kernel_size=k_sz,
                stride=2,
                padding=k_sz // 2,
                output_padding=1
            ))
            # Decoder block with skip connection input
            self.decoders.append(nn.Sequential(
                nn.Conv1d(k_neurons * (k + 8), k_neurons * k, k_sz, padding=k_sz // 2),  # input = upsample + skip
                nn.ReLU(),
                nn.Conv1d(k_neurons * k, k_neurons * k, k_sz, padding=k_sz // 2),
                nn.ReLU()
            ))
            last_k = k  # Update for next iteration
        
        # ========== Output Layer ==========
        self.output_layer = nn.Conv1d(k_neurons, output_channels, kernel_size=1)

    def forward(self, x):
        """
        Forward pass of the U-Net.

        Parameters:
        -----------
        x : torch.Tensor
            Input tensor of shape [B, C_in, L], where:
            - B is batch size
            - C_in is number of input channels (e.g., 2)
            - L is signal length

        Returns:
        --------
        torch.Tensor
            Output tensor of shape [B, C_out, L]
        """
        skips = []  # To store outputs for skip connections
        
        # Encoder path
        for encoder, pool in zip(self.encoders, self.pools):
            x = encoder(x)
            skips.append(x)
            x = pool(x)
        
        # Middle block
        x = self.middle(x)
        
        # Decoder path with skip connections
        for upsample, decoder in zip(self.upsamples, self.decoders):
            x = upsample(x)
            x = torch.cat([x, skips[-(len(self.upsamples) - len(self.decoders) + self.decoders.index(decoder))]], dim=1)
            x = decoder(x)
        
        # Final output layer
        x = self.output_layer(x)
        
        return x
