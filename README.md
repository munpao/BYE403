# BYE403 👋🚫

> **Multi-threaded HTTP 403 Forbidden bypass tool using custom headers**

```
    ____  __  ______ ___  ____  _____
   / __ )\ \/ / __  / _ \|___ \|__  /
  / __  | \  / /_/ /  __/ ___) | / /
 /_/ /_/  /_/\____/\___/ /____(_)_/

  HTTP 403 Bypass Header Fuzzer
  by CoreFlareSec — AI-Augmented ICS Security
```

---

## 📋 What is BYE403?

BYE403 fuzzes HTTP headers to bypass **403 Forbidden** restrictions.

It sends requests with **5,000+ header variants** in parallel and identifies which ones return a non-403 response — helping pentesters quickly find access control misconfigurations.

---

## ✨ Features

- ⚡ **Multi-threaded** — up to 10 parallel workers
- 📋 **5,000+ payloads** — `X-` dash + `X_` underscore variants
- 🍪 **Cookie support** — for authenticated sessions
- 📊 **Progress bar** — real-time visual progress
- 💾 **Output to file** — with metadata for reporting
- 🛑 **Ctrl+C safe** — clean interrupt handling
- 🎨 **Color-coded** — easy to spot hits

---

## 🚀 Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/BYE403
cd BYE403
chmod +x bye403.sh
bash bye403.sh -u http://TARGET/admin
```

---

## 📌 Usage

```bash
bash bye403.sh -u <URL> [options]
```

### Options

| Flag | Description | Default |
|------|-------------|---------|
| `-u` | Target URL **(required)** | — |
| `-w` | Wordlist path | `wordlists/403-bypass-clean.txt` |
| `-c` | Cookie string | — |
| `-t` | Threads (max 10) | `4` |
| `-s` | HTTP code to skip | `403` |
| `-o` | Output file | — |
| `-T` | Timeout per request (sec) | `10` |
| `-h` | Show help | — |

### Examples

```bash
# Basic
bash bye403.sh -u http://192.168.1.100/admin

# With cookie
bash bye403.sh -u http://192.168.1.100/admin \
  -c "PHPSESSID=abc123def456"

# 5 threads + save output
bash bye403.sh -u http://192.168.1.100/admin \
  -t 5 \
  -o results.txt

# Custom port + cookie
bash bye403.sh -u http://192.168.1.100:631/admin \
  -c "session=abc123" \
  -t 5 \
  -o results.txt

# Full options
bash bye403.sh \
  -u http://TARGET/admin \
  -w wordlists/403-bypass-clean.txt \
  -c "PHPSESSID=abc123" \
  -t 5 \
  -s 403 \
  -o results.txt \
  -T 10
```

---

## 🎯 Example Output

```
    ____  __  ______ ___  ____  _____
   / __ )\ \/ / __  / _ \|___ \|__  /
  / __  | \  / /_/ /  __/ ___) | / /
 /_/ /_/  /_/\____/\___/ /____(_)_/

  HTTP 403 Bypass Header Fuzzer
  by CoreFlareSec

┌─────────────────────────────────────────────┐
│                 Configuration                │
├─────────────────────────────────────────────┤
│  Target       : http://192.168.1.100/admin  │
│  Wordlist     : 403-bypass-clean.txt (5018) │
│  Threads      : 5                           │
│  Skip Code    : HTTP 403                    │
│  Timeout      : 10s/request                 │
└─────────────────────────────────────────────┘

[*] START — 2026-05-19 14:32:01
[*] Splitting into 5 chunks (~1004 headers each)
[*] Fuzzing... Press Ctrl+C to stop
─────────────────────────────────────────────────
[~] [████░░░░░░░░░░░░░░░░] 420/5018 (8%)
[~] [████████░░░░░░░░░░░░] 1005/5018 (20%)
[HIT] HTTP 200 → X_ORIGINATING_IP: 127.0.0.1
[~] [████████████░░░░░░░░] 2010/5018 (40%)
─────────────────────────────────────────────────
[*] STOP  — 2026-05-19 14:33:45
[*] Elapsed    : 104s
[*] Tested     : 5018 headers
[*] Threads    : 5

[✓] Bypasses   : 1 found!

──── RESULTS ────
[HIT] HTTP 200 → X_ORIGINATING_IP: 127.0.0.1
─────────────────

[✓] ลอง header ด้านบนใน Burp Repeater
[*] Saved to   : results.txt
```

---

## 📁 Structure

```
BYE403/
├── bye403.sh                    ← Main script
├── README.md                    ← Documentation
├── LICENSE                      ← MIT License
├── .gitignore
└── wordlists/
    ├── 403-bypass-clean.txt     ← 5,018 ready-to-use payloads
    └── 403-headers-names.txt    ← 423 header names only
```

---

## 📝 Wordlist Details

| File | Entries | Description |
|------|---------|-------------|
| `403-bypass-clean.txt` | **5,018** | Headers + values (ready to use) |
| `403-headers-names.txt` | **423** | Header names only |

**Includes both formats:**

```
X-Forwarded-For: 127.0.0.1        ← dash format
X_FORWARDED_FOR: 127.0.0.1        ← underscore format ⭐
X_ORIGINATING_IP: 127.0.0.1       ← underscore (common bypass)
```

**Values tested:** `127.0.0.1` · `localhost` · `0.0.0.0` · `::1` · `127.0.0.2` · `10.0.0.1` · `192.168.1.1`

Sources: [SecLists](https://github.com/danielmiessler/SecLists) + custom ICS/pentest additions

---

## 🔍 How It Works

```
BYE403 splits wordlist → N chunks (by threads)
Each worker reads chunk → sends curl request with header
If response != 403 → prints [HIT]
All workers run in parallel → fast results
```

**Speed comparison:**

| Threads | 5,018 headers | Approx. time |
|---------|--------------|--------------|
| 1 | Sequential | ~8 min |
| 4 | Parallel | ~2 min |
| 5 | Parallel | ~1.5 min |
| 10 | Parallel | ~1 min |

---

## 🔧 Requirements

```bash
bash   # v4+
curl   # any version
```

No additional dependencies needed.

---

## ⚠️ Disclaimer

> **BYE403** is for **educational purposes** and **authorized penetration testing only**.  
> Do not use against systems without explicit permission.  
> The author is not responsible for any misuse.

---

## 📄 License

MIT License — See [LICENSE](LICENSE)

---

## 🔗 References

- [HackTricks — 403 Bypass](https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/403-and-401-bypasses)
- [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)
- [SecLists](https://github.com/danielmiessler/SecLists)

---

<div align="center">

**BYE403** — Say goodbye to 403 👋

Made with 🔥 by [**CoreFlareSec**](https://github.com/YOUR_USERNAME)  
AI-Augmented ICS Security Consultant

</div>
