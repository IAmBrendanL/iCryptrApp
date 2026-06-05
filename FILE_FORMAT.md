# The `.icryptr` File Format

This document describes the binary layout of files produced by iCryptr's
[`StreamCryptor`](Shared/Models/StreamCryptor.swift) and the cryptographic
choices behind it. It covers **format version 1** — the only version the
current codebase produces or reads.

## Goals

The format was designed around three constraints:

1. **Confidentiality** of file contents under a user-supplied password.
2. **Integrity / authenticity** — a tampered file (or wrong password) must be
   detected before any plaintext is written to disk.
3. **Streamable** — encryption and decryption operate in 128 MiB chunks so the
   app can handle multi-gigabyte files on memory-constrained iOS devices
   without ever loading the whole file.

## Layout

A `.icryptr` file is a single contiguous byte stream. The header is grouped
so all filename fields come first, then all file-body fields:

```
Offset (bytes)   Size              Field
──────────────   ───────────────   ─────────────────────────────────────────────
0                4                 Magic header   ("iCR" + version byte 0x01)
4                64                Salt           (PBKDF2 salt, random)
─── filename group ─────────────────────────────────────────────────────────────
68               16                Filename IV    (AES-CBC IV for the name, random)
84               2                 Name length L  (UInt16, host byte order, ciphertext length)
86               L                 Encrypted filename + extension (AES-256-CBC + PKCS#7)
─── file-body group ────────────────────────────────────────────────────────────
86 + L           16                File-body IV   (AES-CBC IV for the file body, random)
86 + L + 16      ciphertextLen     AES-256-CBC ciphertext of the file body (PKCS#7 padded)
fileSize − 32    32                HMAC-SHA256 tag covering everything before it
```

### Field-by-field

#### Magic header (4 bytes)

The four bytes `0x69 0x43 0x52 0x01` — ASCII `iCR` followed by a version byte.
Defined as `StreamCryptor.magicV1`. The version byte exists so future format
revisions can branch on it; today only `0x01` is recognized. The magic is
checked first on decryption — files that don't start with it are rejected
immediately.

#### Salt (64 bytes)

Cryptographically random bytes from `SecRandomCopyBytes`, generated fresh per
file. Fed to PBKDF2 along with the user's password. Stored in plaintext
because PBKDF2 needs the same salt to re-derive the key on decryption — that
is the salt's purpose, not a secret.

#### Filename IV (16 bytes)

The AES-CBC initialization vector used to encrypt the filename, from
`SecRandomCopyBytes`, generated fresh per file. AES block size is 16 bytes
(`kCCBlockSizeAES128`, which applies to AES-256 too — the *block* size is
128 bits regardless of key size). A **distinct IV** from the file-body IV
is required: encrypting two messages with the same AES key and the same IV
in CBC mode leaks whether they share any leading bytes. Stored in plaintext
because CBC needs the IV to decrypt the first block; the HMAC tag still
authenticates it against tampering.

#### Filename length (2 bytes)

A `UInt16` written in **host byte order** (little-endian on all current Apple
platforms). This is the length of the encrypted filename **ciphertext**, not
the plaintext name. 16 bits is enough for any realistic filename — UTF-8
takes 1–4 bytes per character, so the upper bound is roughly 16k characters;
PKCS#7 adds at most one extra 16-byte block.

> **Portability note:** because the length is host byte order, an `.icryptr`
> file written on a hypothetical big-endian Apple platform would not be
> readable on a little-endian one. In practice every Apple platform iCryptr
> ships on is little-endian, so this has not mattered. Future format
> revisions should switch to a defined byte order.

#### Encrypted filename (variable)

The original file's `lastPathComponent` (name + extension) encoded as UTF-8,
then **encrypted with AES-256 in CBC mode with PKCS#7 padding** using the
same AES key as the file body and the dedicated *Filename IV* above. The
filename length therefore does not leak the exact plaintext length — only a
rounded-up multiple of 16 bytes. Decryption recovers the original name and
extension so the output file can be written with its proper name.

The filename is never stored in plaintext, so the encrypted file does not
leak file names like `tax_return_2025.pdf` on disk or in backups.

#### File-body IV (16 bytes)

The AES-CBC initialization vector used to encrypt the file body. Same source
and rationale as the Filename IV. Distinct from the Filename IV (see above
on CBC IV reuse).

#### Ciphertext (variable)

The file body, encrypted with **AES-256 in CBC mode with PKCS#7 padding**
(`kCCAlgorithmAES` + `kCCOptionPKCS7Padding`). The AES key is the first 32
bytes of the PBKDF2 output (see *Key derivation* below). Padding adds 1–16
bytes so the total ciphertext length is always a multiple of 16.

#### HMAC tag (32 bytes)

An HMAC-SHA256 tag appended to the end of the file. Computed by streaming
the **entire file content from offset 0 up to (fileSize − 32)** through
`CCHmac`. That covers:

- the magic header,
- the salt, filename IV, and file-body IV,
- the filename length and encrypted filename,
- and the full ciphertext.

This is an **encrypt-then-MAC** construction layered on top of CBC, which
gives authenticated encryption: any tampering with any byte of the header or
ciphertext, or use of the wrong password, produces a different HMAC and
decryption is aborted *before* a single byte of plaintext is written.

The HMAC key is independent of the AES key — both are derived from the same
password+salt by extending the PBKDF2 output to 64 bytes and splitting it
(see below). Using a separate key for the MAC is the standard recommendation
and avoids any cross-protocol interaction between the cipher and MAC.

## Key derivation

A single PBKDF2-HMAC-SHA256 invocation produces 64 bytes of key material:

```
keyMaterial = PBKDF2-HMAC-SHA256(
    password = user password (UTF-8 bytes),
    salt     = 64-byte file salt,
    rounds   = 750_000,
    dkLen    = 64
)

aesKey  = keyMaterial[0..32]    // AES-256 encryption key
hmacKey = keyMaterial[32..64]   // HMAC-SHA256 authentication key
```

750,000 rounds is a fixed cost calibrated to be painful for a brute-force
attacker but tolerable on the slowest device the app targets. The round
count is **not** stored in the file — it's a constant in code. Changing it
would require a new format version (or a stored round-count field) so older
files remain decryptable.

## Two-pass decryption

Because the HMAC tag is at the *end* of the file but covers the *whole*
file, `StreamCryptor` decrypts in two passes:

1. **Pass 1 — verify.** Stream bytes `[0, fileSize − 32)` through
   `CCHmac`, compute the tag, and compare it against the trailing 32 bytes.
   If they don't match (tampering, corruption, or wrong password), abort
   with no output written.
2. **Pass 2 — decrypt.** Seek back to the start of the ciphertext (just
   past the header) and stream the body through `CCCryptorUpdate` /
   `CCCryptorFinal`, writing plaintext to the output file.

The two-pass cost (reading the file twice) is the price of authenticated
encryption with the tag appended at the end. The alternative — decrypting
and verifying simultaneously — would risk emitting plaintext that later
turns out to be from a tampered file.

## What this format does *not* protect against

- **Filename length leakage.** The filename itself is encrypted, but its
  length is visible (rounded up to the next 16-byte block by PKCS#7). An
  attacker learns roughly how long the original name was.
- **File-existence leakage.** An attacker can see that a `.icryptr` file
  exists and learn its (rounded-to-block) original size from the ciphertext
  length.
- **Weak passwords.** PBKDF2 at 750k rounds is a meaningful brute-force
  speed bump, but a 4-character password is still a 4-character password.
  The file format does not protect against this. Implementations are free to set minimum complexity rules.

## Versioning and future changes

The version byte in the magic header (`0x01`) is the format's only version
identifier. Any change that breaks read-compatibility — different KDF, larger
salt, different cipher mode, defined byte order for the length field — should
bump it and `StreamCryptor` should branch on the byte to support both old and
new files.
