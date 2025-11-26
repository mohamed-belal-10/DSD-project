from PIL import Image
import matplotlib.pyplot as plt

class LZWCompressor:
    def __init__(self, pixel_width=8, code_width=12, dict_size=4096):
        self.PIXEL_WIDTH = pixel_width
        self.CODE_WIDTH = code_width
        self.DICT_SIZE = dict_size
        self.dictionary = {}
        self.reset()

    def reset(self):
        # Reset dictionary to all single-symbol entries
        self.dictionary = {}
        for i in range(256):  # For 8-bit grayscale
            # Single symbol as string
            self.dictionary[chr(i)] = i
        self.dict_index = 256  # Next available code
        self.curr_str = ''
        self.codes = []

    def compress(self, input_pixels):
        self.reset()
        for pixel in input_pixels:
            symbol = chr(pixel)  # Use single ASCII char as symbol, as in VHDL "std_logic_vector"
            new_str = self.curr_str + symbol
            if new_str in self.dictionary:
                self.curr_str = new_str
            else:
                # Output code for curr_str
                if self.curr_str != '':
                    self.codes.append(self.dictionary[self.curr_str])
                # Add new_str to the dictionary
                if self.dict_index < self.DICT_SIZE:
                    self.dictionary[new_str] = self.dict_index
                    self.dict_index += 1
                # Reset curr_str to symbol
                self.curr_str = symbol

        # Output code for the last string
        if self.curr_str != '':
            self.codes.append(self.dictionary[self.curr_str])
        return self.codes

if __name__ == "__main__":
    # Open the image
    img = Image.open(r"C:\Users\dell\Downloads\patteern4.bin").convert('L') # 'L' mode = grayscale
    pixels = list(img.getdata())
    lzw = LZWCompressor()
    codes = lzw.compress(pixels)
    print("Output codes:", codes)

    # Show the original image
    img.show()  # Will open image in default viewer

    # OR, show with matplotlib in a script
    plt.imshow(img, cmap='gray')
    plt.title('Original Grayscale Image')
    plt.axis('off')
    plt.show()

    # Compression ratio
    original_size = len(pixels)       # bytes
    compressed_size = len(codes) * 2 # bytes, if each code stored in 2 bytes
    print("Original size (bytes):", original_size)
    print("Compressed size (bytes):", compressed_size)
    print("Compression ratio:", compressed_size / original_size)
