using System.Buffers.Binary;

if (args.Length != 1) return 2;
const uint entry = 0x80001000, output = 0x80010000, data = 0x80011000;
static uint Lis(int rd,uint v)=>0x3c000000u|((uint)rd<<21)|((v>>16)&0xffffu);
static uint Ori(int rd,int ra,uint v)=>0x60000000u|((uint)ra<<21)|((uint)rd<<16)|(v&0xffffu);
static uint Addi(int rd,int ra,int v)=>0x38000000u|((uint)rd<<21)|((uint)ra<<16)|(uint)(v&0xffff);
static uint Stw(int rs,int ra,int d)=>0x90000000u|((uint)rs<<21)|((uint)ra<<16)|(uint)(d&0xffff);
static uint Add(int rd,int ra,int rb)=>0x7c000214u|((uint)rd<<21)|((uint)ra<<16)|((uint)rb<<11);
static uint Lfs(int fd,int ra,int d)=>0xc0000000u|((uint)fd<<21)|((uint)ra<<16)|(uint)(d&0xffff);
static uint Stfs(int fs,int ra,int d)=>0xd0000000u|((uint)fs<<21)|((uint)ra<<16)|(uint)(d&0xffff);
static uint Fadds(int fd,int fa,int fb)=> (59u<<26)|((uint)fd<<21)|((uint)fa<<16)|((uint)fb<<11)|(21u<<1);

var words=new uint[] {
  Lis(3,output),Ori(3,3,output),Addi(4,0,0x7fff),Add(5,4,4),Stw(5,3,0),
  Lis(6,data),Ori(6,6,data),Lfs(1,6,0),Lfs(2,6,4),Fadds(3,1,2),Stfs(3,3,4),
  0x4e800020u
};
const int header=0x100;
var codeBytes=words.Length*4;
var image=new byte[header+codeBytes+8];
BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(0x00,4),(uint)header);
BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(0x1c,4),(uint)(header+codeBytes));
BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(0x48,4),entry);
BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(0x64,4),data);
BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(0x90,4),(uint)codeBytes);
BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(0xac,4),8u);
BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(0xe0,4),entry);
for(int i=0;i<words.Length;++i) BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(header+i*4,4),words[i]);
BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(header+codeBytes,4),0x3fc00000u); // 1.5
BinaryPrimitives.WriteUInt32BigEndian(image.AsSpan(header+codeBytes+4,4),0x40100000u); // 2.25
var path=Path.GetFullPath(args[0]); Directory.CreateDirectory(Path.GetDirectoryName(path)!); File.WriteAllBytes(path,image);
Console.WriteLine($"semanticFixture={path} entry=0x{entry:X8} bytes={image.Length}");
return 0;
