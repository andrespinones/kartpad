using System.Buffers.Binary;

if (args.Length != 1)
{
    Console.Error.WriteLine("usage: FixtureDolGenerator <output.dol>");
    return 2;
}

const uint entryPoint = 0x80001000;
const uint commandAddress = 0x80010000;
const uint magic = 0x4B504446; // KPDF — KartPad Display Fixture
const uint width = 256;
const uint height = 192;
const uint rgba = 0x2458A8FF;

static uint Lis(int destination, uint value) =>
    0x3C000000u | ((uint)destination << 21) | ((value >> 16) & 0xFFFFu);
static uint Ori(int destination, int source, uint value) =>
    0x60000000u | ((uint)source << 21) | ((uint)destination << 16) | (value & 0xFFFFu);
static uint Stw(int source, int address, int offset) =>
    0x90000000u | ((uint)source << 21) | ((uint)address << 16) | (uint)(offset & 0xFFFF);

var words = new uint[]
{
    Lis(3, commandAddress),
    Ori(3, 3, commandAddress),
    Lis(4, magic),
    Ori(4, 4, magic),
    Stw(4, 3, 0),
    Lis(4, width),
    Ori(4, 4, width),
    Stw(4, 3, 4),
    Lis(4, height),
    Ori(4, 4, height),
    Stw(4, 3, 8),
    Lis(4, rgba),
    Ori(4, 4, rgba),
    Stw(4, 3, 12),
    0x4E800020u, // blr
};

const int headerSize = 0x100;
var image = new byte[headerSize + words.Length * sizeof(uint)];
BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(0x00, 4), headerSize);
BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(0x48, 4), entryPoint);
BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(0x90, 4), (uint)(words.Length * sizeof(uint)));
BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(0xE0, 4), entryPoint);
for (var index = 0; index < words.Length; ++index)
{
    BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(headerSize + index * 4, 4), words[index]);
}

var output = Path.GetFullPath(args[0]);
Directory.CreateDirectory(Path.GetDirectoryName(output)!);
File.WriteAllBytes(output, image);
Console.WriteLine($"fixtureDol={output} entry=0x{entryPoint:X8} bytes={image.Length}");
return 0;
