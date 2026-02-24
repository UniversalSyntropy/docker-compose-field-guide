# Advanced Secrets Management

How to graduate from plain-text secret files to encrypted secrets at rest.

> **Starting point:** This guide assumes you already use Docker Compose
> file-based secrets as described in
> [BEST-PRACTICES.md §3.6](BEST-PRACTICES.md#36-secrets-management).
> If you're still putting passwords in `.env` or inline in your compose file,
> start there first.

---

## The Problem with Plain-Text Secrets

Docker Compose file-based secrets (e.g. `secrets/db_password.txt`) are a
good baseline — they keep passwords out of environment variables and compose
files. But the secret files themselves are plain text on disk:

- Anyone with read access to the filesystem can see them
- They can't be safely committed to version control
- There's no audit trail for who accessed or changed them
- Backups may include them unencrypted

For a homelab on a single machine you trust, this is usually acceptable.
When you start sharing access, backing up to the cloud, or managing
secrets across multiple machines, you need encryption at rest.

---

## Option 1: Mozilla SOPS

[SOPS](https://github.com/getsops/sops) (Secrets OPerationS) encrypts
files in place — you can commit them to git safely because only the
*values* are encrypted, not the keys. This makes diffs readable.

### How it works

1. You create a secret file as normal
2. SOPS encrypts it using a key (age, GPG, or a cloud KMS)
3. The encrypted file is safe to commit to git
4. At deploy time, you decrypt and pipe the value into the secret file

### Setup with age (recommended for homelab)

```bash
# Install sops and age
brew install sops age          # macOS
# apt install sops age         # Debian/Ubuntu (check versions)

# Generate an age key pair
age-keygen -o ~/.config/sops/age/keys.txt
# Output: public key: age1xxxxxxxxx...

# Create a SOPS config in your repo root
cat > .sops.yaml << 'EOF'
creation_rules:
  - path_regex: secrets/.*\.enc\..*
    age: >-
      age1xxxxxxxxx...
EOF
```

### Encrypt a secret

```bash
# Create the plain-text secret
echo -n "my-database-password" > secrets/db_password.txt

# Encrypt it
sops encrypt secrets/db_password.txt > secrets/db_password.enc.txt

# Remove the plain-text version
rm secrets/db_password.txt

# The encrypted file is safe to commit
git add secrets/db_password.enc.txt
```

### Decrypt at deploy time

```bash
# Decrypt to the path Docker Compose expects
sops decrypt secrets/db_password.enc.txt > secrets/db_password.txt

# Deploy
docker compose up -d

# Optionally remove the decrypted file after deploy
# rm secrets/db_password.txt
```

> **Gotcha:** Your age private key (`~/.config/sops/age/keys.txt`) is now
> the single point of failure. Back it up securely — if you lose it, you
> can't decrypt your secrets.

### Automating decryption

Add a helper script to decrypt all secrets before deploy:

```bash
#!/usr/bin/env bash
# scripts/decrypt-secrets.sh
set -euo pipefail
for enc in secrets/*.enc.*; do
    plain="${enc/.enc/}"
    echo "Decrypting: $enc -> $plain"
    sops decrypt "$enc" > "$plain"
done
echo "All secrets decrypted."
```

---

## Option 2: Doppler

[Doppler](https://www.doppler.com/) is a hosted secrets manager with a
generous free tier. It centralises secrets in a web dashboard and injects
them at runtime.

### How it works

1. You store secrets in Doppler's dashboard (organised by project and
   environment)
2. At deploy time, the Doppler CLI fetches secrets and writes them to files
3. Docker Compose reads them as normal file-based secrets

### Setup

```bash
# Install the Doppler CLI
brew install dopplerhq/cli/doppler    # macOS
# curl -Ls https://cli.doppler.com/install.sh | sh   # Linux

# Authenticate
doppler login

# Set up your project
doppler setup
```

### Inject secrets at deploy time

```bash
# Write each secret to the file Docker Compose expects
doppler secrets get DB_PASSWORD --plain > secrets/db_password.txt

# Or use Doppler's run command to inject as env vars (less secure)
doppler run -- docker compose up -d
```

> **Trade-off:** Doppler requires internet access to fetch secrets. If your
> homelab has no internet during deploy, SOPS with local age keys is the
> better choice.

---

## Option 3: git-crypt

[git-crypt](https://github.com/AGWA/git-crypt) transparently encrypts
files when they're committed to git and decrypts them on checkout. Simpler
than SOPS, but less flexible.

### Setup

```bash
# Install
brew install git-crypt       # macOS

# Initialise in your repo
git-crypt init

# Add a .gitattributes rule for secret files
echo "secrets/** filter=git-crypt diff=git-crypt" >> .gitattributes

# Export the symmetric key (back this up securely)
git-crypt export-key /path/to/git-crypt-key
```

### How it works

- Files matching the `.gitattributes` pattern are encrypted in the git
  repository but decrypted in your working directory
- Anyone who clones the repo without the key sees encrypted blobs
- `git-crypt unlock /path/to/key` decrypts on a new machine

> **Limitation:** git-crypt encrypts entire files — you can't see which
> values changed in a diff. SOPS is better for this.

---

## Comparison

| Feature | Plain-text files | SOPS + age | Doppler | git-crypt |
| ------- | ---------------- | ---------- | ------- | --------- |
| Safe to commit to git | No | Yes | N/A (secrets in cloud) | Yes |
| Readable diffs | Yes | Yes (keys visible) | N/A | No |
| Works offline | Yes | Yes | No | Yes |
| Audit trail | No | Git history | Yes (dashboard) | Git history |
| Multi-machine | Manual copy | Decrypt on each host | CLI fetch | Unlock on each host |
| Free | Yes | Yes | Free tier | Yes |
| Complexity | Low | Medium | Medium | Low |

### Recommendation

- **Single homelab machine:** Plain-text files in a gitignored `secrets/`
  directory are fine. Focus on file permissions (`chmod 600`).
- **Secrets in version control:** Use **SOPS + age**. It's the most
  flexible option, works offline, and produces readable diffs.
- **Multi-machine or team:** Consider **Doppler** for centralised
  management, or SOPS with a shared age key.
- **Simple encryption, no fancy diffs needed:** **git-crypt** gets the
  job done with minimal setup.

---

## Further Reading

- [SOPS documentation](https://github.com/getsops/sops)
- [age encryption](https://github.com/FiloSottile/age)
- [Doppler documentation](https://docs.doppler.com/)
- [git-crypt documentation](https://github.com/AGWA/git-crypt)
- [Docker secrets documentation](https://docs.docker.com/compose/how-tos/use-secrets/)
- [BEST-PRACTICES.md §3.6 — Secrets Management](BEST-PRACTICES.md#36-secrets-management)

---

[← Back to README](../README.md)
