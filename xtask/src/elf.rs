//! Minimal reader for 32-bit little-endian ELF files (what the linker produces).

pub const SHF_ALLOC: u32 = 0x2;
pub const SHF_EXECINSTR: u32 = 0x4;
pub const SHT_SYMTAB: u32 = 2;
pub const SHT_NOBITS: u32 = 8;

const STT_NOTYPE: u8 = 0;
const STT_FUNC: u8 = 2;

pub struct Section {
    pub name: String,
    pub kind: u32,
    pub flags: u32,
    pub addr: u32,
    pub offset: u32,
    pub size: u32,
    pub link: u32,
}

pub struct Symbol {
    pub name: String,
    pub value: u32,
    pub section: u16,
}

pub struct Elf {
    pub data: Vec<u8>,
    pub sections: Vec<Section>,
}

fn u16_at(d: &[u8], o: usize) -> u16 {
    u16::from_le_bytes([d[o], d[o + 1]])
}

fn u32_at(d: &[u8], o: usize) -> u32 {
    u32::from_le_bytes([d[o], d[o + 1], d[o + 2], d[o + 3]])
}

fn c_str(d: &[u8], o: usize) -> String {
    let end = d[o..].iter().position(|&b| b == 0).map_or(d.len(), |p| o + p);
    String::from_utf8_lossy(&d[o..end]).into_owned()
}

impl Elf {
    pub fn parse(data: Vec<u8>) -> Result<Elf, String> {
        if data.len() < 52 || &data[0..4] != b"\x7fELF" {
            return Err("not an ELF file".into());
        }
        if data[4] != 1 || data[5] != 1 {
            return Err("not a 32-bit little-endian ELF file".into());
        }
        let shoff = u32_at(&data, 0x20) as usize;
        let shentsize = u16_at(&data, 0x2E) as usize;
        let shnum = u16_at(&data, 0x30) as usize;
        let shstrndx = u16_at(&data, 0x32) as usize;

        let mut sections = Vec::with_capacity(shnum);
        for i in 0..shnum {
            let o = shoff + i * shentsize;
            sections.push(Section {
                name: String::new(),
                kind: u32_at(&data, o + 4),
                flags: u32_at(&data, o + 8),
                addr: u32_at(&data, o + 12),
                offset: u32_at(&data, o + 16),
                size: u32_at(&data, o + 20),
                link: u32_at(&data, o + 24),
            });
            let name_off = u32_at(&data, o) as usize;
            let strtab = shoff + shstrndx * shentsize;
            let str_off = u32_at(&data, strtab + 16) as usize;
            sections[i].name = c_str(&data, str_off + name_off);
        }
        Ok(Elf { data, sections })
    }

    pub fn bytes(&self, s: &Section) -> &[u8] {
        &self.data[s.offset as usize..(s.offset + s.size) as usize]
    }

    /// Function and label symbols (no section/file symbols, no "$x" mapping symbols).
    pub fn symbols(&self) -> Vec<Symbol> {
        let mut out = Vec::new();
        for symtab in self.sections.iter().filter(|s| s.kind == SHT_SYMTAB) {
            let strtab = &self.sections[symtab.link as usize];
            let d = self.bytes(symtab);
            for e in d.chunks_exact(16).skip(1) {
                let kind = e[12] & 0xF;
                let section = u16_at(e, 14);
                let name = c_str(&self.data, strtab.offset as usize + u32_at(e, 0) as usize);
                if (kind == STT_FUNC || kind == STT_NOTYPE)
                    && section != 0
                    && section < 0xFF00
                    && !name.is_empty()
                    && !name.starts_with('$')
                    && !name.starts_with(".L")
                {
                    out.push(Symbol { name, value: u32_at(e, 4), section });
                }
            }
        }
        out
    }
}
