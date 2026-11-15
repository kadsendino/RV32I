//! Build helper for the RISC-V program. Runs on your PC.
//!
//!   cargo bin              build, then write target/<name>.bin (raw machine code)
//!   cargo asm              build, then write target/<name>.s   (clean assembly)
//!   cargo asm --opt 0      choose the optimisation level (0, 1, 2, 3, s, z)

mod disasm;
mod elf;

use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode};

const TARGET: &str = "riscv32i-unknown-none-elf";

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("error: {e}");
            ExitCode::FAILURE
        }
    }
}

fn run() -> Result<(), String> {
    let mut args = std::env::args().skip(1);
    let cmd = args.next().unwrap_or_default();
    let mut opt: Option<String> = None;
    while let Some(a) = args.next() {
        match a.as_str() {
            "--opt" => opt = Some(args.next().ok_or("--opt needs a value")?),
            _ => return Err(format!("unknown argument '{a}'")),
        }
    }

    let root = project_root();
    let name = package_name(&root)?;
    let elf_path = build(&root, opt.as_deref())?.join(&name);
    let elf = elf::Elf::parse(
        std::fs::read(&elf_path).map_err(|e| format!("{}: {e}", elf_path.display()))?,
    )?;

    let (out, contents) = match cmd.as_str() {
        "bin" => (root.join("target").join(format!("{name}.bin")), to_bin(&elf)),
        "asm" => (root.join("target").join(format!("{name}.s")), to_asm(&elf).into_bytes()),
        _ => return Err("usage: cargo bin | cargo asm [--opt LEVEL]".into()),
    };
    std::fs::write(&out, contents).map_err(|e| format!("{}: {e}", out.display()))?;
    println!("wrote {}", out.strip_prefix(&root).unwrap_or(&out).display());
    Ok(())
}

/// The folder that contains xtask/.
fn project_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).parent().unwrap().to_path_buf()
}

/// Read `name = "..."` from the [package] section of the main Cargo.toml.
fn package_name(root: &Path) -> Result<String, String> {
    let toml = std::fs::read_to_string(root.join("Cargo.toml")).map_err(|e| e.to_string())?;
    let mut in_package = false;
    for line in toml.lines().map(str::trim) {
        if line.starts_with('[') {
            in_package = line == "[package]";
        } else if in_package && line.starts_with("name") {
            if let Some(v) = line.split('"').nth(1) {
                return Ok(v.to_string());
            }
        }
    }
    Err("no package name found in Cargo.toml".into())
}

/// `cargo build --release` for the RISC-V target. Returns the output folder.
fn build(root: &Path, opt: Option<&str>) -> Result<PathBuf, String> {
    let cargo = std::env::var("CARGO").unwrap_or_else(|_| "cargo".into());
    let mut cmd = Command::new(cargo);
    cmd.current_dir(root).args(["build", "--release", "--target", TARGET]);
    if let Some(level) = opt {
        cmd.env("CARGO_PROFILE_RELEASE_OPT_LEVEL", level);
    }
    let status = cmd.status().map_err(|e| format!("failed to run cargo: {e}"))?;
    if !status.success() {
        return Err("build failed".into());
    }
    Ok(root.join("target").join(TARGET).join("release"))
}

/// Raw memory image: every loaded section with contents, placed at its address,
/// gaps filled with zeros, starting at the lowest address (same as objcopy -O binary).
fn to_bin(elf: &elf::Elf) -> Vec<u8> {
    let loaded: Vec<_> = elf
        .sections
        .iter()
        .filter(|s| s.flags & elf::SHF_ALLOC != 0 && s.kind != elf::SHT_NOBITS && s.size > 0)
        .collect();
    let Some(start) = loaded.iter().map(|s| s.addr).min() else {
        return Vec::new();
    };
    let end = loaded.iter().map(|s| s.addr + s.size).max().unwrap();
    let mut image = vec![0u8; (end - start) as usize];
    for s in loaded {
        let o = (s.addr - start) as usize;
        image[o..o + s.size as usize].copy_from_slice(elf.bytes(s));
    }
    image
}

/// Disassemble every code section, with function names as labels.
fn to_asm(elf: &elf::Elf) -> String {
    let symbols = elf.symbols();
    let mut out = String::new();
    for (index, s) in elf.sections.iter().enumerate() {
        if s.flags & elf::SHF_EXECINSTR == 0 || s.kind == elf::SHT_NOBITS {
            continue;
        }
        let mut labels: Vec<_> = symbols.iter().filter(|y| y.section as usize == index).collect();
        labels.sort_by(|a, b| a.value.cmp(&b.value).then(a.name.cmp(&b.name)));
        labels.dedup_by(|a, b| a.value == b.value && a.name == b.name);

        for (i, word) in elf.bytes(s).chunks_exact(4).enumerate() {
            let pc = s.addr + 4 * i as u32;
            for l in labels.iter().filter(|l| l.value == pc) {
                out += &format!("{:#}:\n", rustc_demangle::demangle(&l.name));
            }
            let w = u32::from_le_bytes([word[0], word[1], word[2], word[3]]);
            out += &disasm::decode(w, pc);
            out.push('\n');
        }
    }
    out
}
