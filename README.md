# Hong Kong University Of Science and Technology Bus Terminal Tool

A command-line tool to check Hong Kong bus arrival times from your terminal.

## Features

- Check ETAs for buses at predefined stops
- Search for bus stops by name
- Get inbound and outbound ETAs
- Support for KMB and CTB/NWFB buses
- Easy to use command-line interface

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/hkbus-on-terminal.git
cd hkbus-on-terminal
```

2. Run the installation script:
```bash
./install.sh
```

3. Restart your terminal or run:
```bash
source ~/.zshrc  # or ~/.bashrc if using bash
```

## Usage

Basic commands:

```

# Legacy mode: Get inbound/outbound ETAs for UST
bus i 91M  # Inbound
bus o 91M  # Outbound
bus o 792M  # Other examples

```

<!-- ## Adding More Stops

To add more stops, modify the `STOPS` array in `ust-eta/bus.sh`. Each entry should follow this format:

```
"StopName:CTB_ID:KMB_ID:Description"
``` -->

## Requirements

- bash
- curl
- jq (for JSON processing)

## License

MIT

## Acknowledgements

This project uses public transportation data from:
- KMB API: https://data.etabus.gov.hk
- CTB/NWFB API: https://rt.data.gov.hk