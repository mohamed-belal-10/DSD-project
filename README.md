# LZW Image Compressor — VHDL + Python Reference Model

A hardware implementation of the **Lempel-Ziv-Welch (LZW)** compression
algorithm, written in VHDL for FPGA synthesis, verified against a Python
reference model that runs the same algorithm on real grayscale images.

Built as a digital system design project: the VHDL core is the actual
deliverable, and the Python script exists to independently confirm the
core produces correct output before trusting the RTL simulation.

## What's in this repo

| File | Purpose |
|---|---|
| `project/LZW_Compressor.vhd` | Synchronous LZW compressor core: accepts one pixel per clock, builds a dictionary on the fly, and streams out fixed-width codes. |
| `project/tb_LZW_Compressor.vhd` | Self-checking testbench — drives an 8-pixel grayscale test pattern through the core and generates the clock/reset/handshake sequence. |
| `project/lzw_compressor.py` | Python reference implementation of the same algorithm, used to cross-check the hardware's behavior against a known-correct software model, and to visualize real images before/after compression. |
| `requirements.txt` | Python dependencies for the reference model. |

## How the compressor works

The VHDL core implements the classic LZW encoding loop directly in hardware:

- **Dictionary**: initialized with all 256 single-pixel (8-bit grayscale) values on `start`, then grown with new two-symbol strings as they're seen — up to `DICT_SIZE` entries (default 4096, i.e. 12-bit codes).
- **Streaming interface**: one pixel in per clock (`pixel_in` / `pixel_valid`), one code out per match miss (`code_out` / `code_valid`), with a `done` flag once the stream ends.
- **Generic parameters** (`PIXEL_WIDTH`, `CODE_WIDTH`, `DICT_SIZE`) make the pixel depth and dictionary size configurable at instantiation time rather than hardcoded.

### Interface

```vhdl
entity LZW_Compressor is
    generic (
        PIXEL_WIDTH : integer := 8;    -- grayscale pixel width
        CODE_WIDTH  : integer := 12;   -- output code width
        DICT_SIZE   : integer := 4096  -- dictionary depth (2^CODE_WIDTH)
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        pixel_in    : in  std_logic_vector(PIXEL_WIDTH-1 downto 0);
        pixel_valid : in  std_logic;
        start       : in  std_logic;
        code_out    : out std_logic_vector(CODE_WIDTH-1 downto 0);
        code_valid  : out std_logic;
        done        : out std_logic
    );
end entity;
```

## Running the simulation

Any standard VHDL simulator works (ModelSim, Vivado xsim, GHDL). Example with GHDL:

```bash
ghdl -a project/LZW_Compressor.vhd
ghdl -a project/tb_LZW_Compressor.vhd
ghdl -e tb_LZW_Compressor
ghdl -r tb_LZW_Compressor --wave=wave.ghw
```

Then inspect `wave.ghw` (e.g. with GTKWave) to confirm `code_out` matches the
codes the Python model produces for the same input sequence.

## Running the Python reference model

```bash
pip install -r requirements.txt
python project/lzw_compressor.py
```

The script loads a grayscale image, runs it through a pure-Python LZW
compressor with the same dictionary-growth rules as the VHDL core, prints the
resulting code stream, and displays the source image with `matplotlib`. Point
it at your own image by editing the path passed to `Image.open(...)`.

## Verifying hardware against software

The testbench's built-in test pattern:

```
0x12, 0x12, 0x23, 0x23, 0x34, 0x12, 0x23, 0x34
```

feeding the same 8-byte sequence into `LZWCompressor.compress()` in the
Python model should produce the identical code sequence as `code_out` in the
VHDL simulation. That agreement is the correctness check for the whole
project — the Python model is the source of truth for "what LZW should
output," and the VHDL core is judged against it.

## Notes

- The dictionary in this implementation stores 2-symbol strings (current
  symbol + one appended symbol), which keeps the hardware simple but caps
  how much run-length repetition can compress in a single pass — see
  `LZW_Compressor.vhd` for the exact string-matching logic if you're
  extending it to longer match strings.
- `PIXEL_WIDTH`, `CODE_WIDTH`, and `DICT_SIZE` are VHDL generics — resimulate
  with different values to explore the codeword-size/compression-ratio
  tradeoff instead of editing the entity.
