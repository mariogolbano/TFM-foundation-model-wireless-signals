import torch
import torch.nn as nn
import torch.nn.functional as F

class UNet(nn.Module):
    def __init__(self, input_channels, output_channels, k_sz=3, long_k_sz=101, k_neurons=32):

        super(UNet, self).__init__()
        self.input_channels = input_channels   # N channels of the input signals. For RF signals tipically 2 (real and imaginary)
        self.output_channels = output_channels # N channels of the output signal. Typically same as input: 2.
        self.k_sz = k_sz  # kernel size for convolution layers. Default 3
        self.long_k_sz = long_k_sz  # A larger kernel size for the first layer for better feature extraction at start
        self.k_neurons = k_neurons  # Base number of filters used in conv layers. Each succesive layer increases the number of filters
        
        # Encoder layers
        self.encoders = nn.ModuleList()
        for n_layer, k in enumerate([8, 8, 8, 8, 8]):
            if n_layer == 0:
                self.encoders.append(nn.Sequential(
                    nn.Conv1d(input_channels if n_layer == 0 else k_neurons * (k // 2), k_neurons * k, long_k_sz, padding=long_k_sz // 2),
                    nn.ReLU(),
                    nn.Conv1d(k_neurons * k, k_neurons * k, k_sz, padding=k_sz // 2),
                    nn.ReLU(),
                    nn.MaxPool1d(2),
                    nn.Dropout(0.25 if n_layer == 0 else 0.5)
                ))
            else:
                self.encoders.append(nn.Sequential(
                    nn.Conv1d(k_neurons * (k // 2), k_neurons * k, k_sz, padding=k_sz // 2),
                    nn.ReLU(),
                    nn.Conv1d(k_neurons * k, k_neurons * k, k_sz, padding=k_sz // 2),
                    nn.ReLU(),
                    nn.MaxPool1d(2),
                    nn.Dropout(0.5)
                ))

        # Bottleneck layers
        self.bottleneck = nn.Sequential(
            nn.Conv1d(k_neurons * 8, k_neurons * 8, k_sz, padding=k_sz // 2),
            nn.ReLU(),
            nn.Conv1d(k_neurons * 8, k_neurons * 8, k_sz, padding=k_sz // 2),
            nn.ReLU()
        )

        # Decoder layers
        self.decoders = nn.ModuleList()
        for n_layer, k in enumerate([8, 8, 4, 2, 1]):
            self.decoders.append(nn.Sequential(
                nn.ConvTranspose1d(k_neurons * (k * 2), k_neurons * k, k_sz, stride=2, padding=k_sz // 2, output_padding=1),
                nn.ReLU(),
                nn.Dropout(0.5),
                nn.Conv1d(k_neurons * k, k_neurons * k, k_sz, padding=k_sz // 2),
                nn.ReLU(),
                nn.Conv1d(k_neurons * k, k_neurons * k, k_sz, padding=k_sz // 2),
                nn.ReLU()
            ))

        # Output layer
        self.output_layer = nn.Conv1d(k_neurons, output_channels, kernel_size=1)

    def forward(self, x):
        print(f"Input: {x.shape}")
        skips = []

        # Encoder pass
        for i, encoder in enumerate(self.encoders):
            x = encoder(x)
            print(f"Encoder layer {i + 1}: {x.shape}")
            skips.append(x)
        
        # Bottleneck pass
        x = self.bottleneck(x)
        print(f"Bottleneck: {x.shape}")

        # Decoder pass
        for i, (decoder, skip) in enumerate(zip(self.decoders, reversed(skips))):
            print(f"Decoder input before interpolation (layer {i + 1}): {x.shape}")
            x = torch.cat([F.interpolate(x, scale_factor=2, mode='linear', align_corners=True), skip], dim=1)
            print(f"Decoder input after concatenation (layer {i + 1}): {x.shape}")
            x = decoder(x)
            print(f"Decoder output (layer {i + 1}): {x.shape}")

        # Output layer
        x_out = self.output_layer(x)
        print(f"Output: {x_out.shape}")

        return x_out

