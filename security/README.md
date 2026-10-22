# Security port: CVE-2026-109618 / CVE-2026-109619 (RCE) to php5.6

PHP 8.5.12 / 8.4.27 / 8.3.36 / 8.2.35 (2026-10-21) fix two critical unauthenticated RCEs.
PHP <= 8.1 gets no upstream updates; the PHP security team published a minimal source
backport branch for 7.4 (`PHP-7.4-CVE-2026-109618-109619`, commit `712e60f9ed`).
There is no official 5.6 backport - the 5.6 patch here is a manual port of the same fix.

- GHSA-w8hw-w9fx-j79w / CVE-2026-109618 - RCE via OOM corruption: OOM `longjmp()`
  (zend_bailout) out of partially initialized request state, consumed during shutdown.
- GHSA-6wmf-4rv5-p3rp / CVE-2026-109619 - RCE via stale global state: worker-global
  state (exception, error handling, http_globals, SAPI request_info, llists,
  session upload progress) survives request shutdown as a dangling pointer and is
  consumed before the next request initialization.

## Files

- `CVE-2026-109618-109619-php56.patch` - manual port to php5 5.6.40+dfsg-0+deb8u12
  (Debian jessie), generated against the tree with the full 86-patch debian series applied.

## Deviations from the upstream backport (C89 build fixes)

The upstream 7.4 backport branch is on the EOL 7.4 line and was never compiled by the
PHP team; it carries two constructs that do not build on jessie (gcc 4.9 / glibc 2.19,
C89):

- `if (!PS(rfc1867_enabled) || true)` in `ext/session/session.c` - `true` is a C99
  macro from `<stdbool.h>`, which 5.6 does not include (it only reaches the translation
  unit transitively through newer glibc headers, so it compiles on modern hosts and
  breaks on jessie: `'true' undeclared`). The patch uses `|| 1` instead.
- `_exit(1)` in `Zend/zend_alloc.c` / `zend_alloc.h` - glibc's `<stdlib.h>` declares
  `_exit` only in XOpen mode (`_XOPEN_SOURCE`); in the default gnu mode only the POSIX
  `_Exit` is declared. The patch uses `_Exit(1)` (identical semantics: immediate
  process termination, no atexit/stdio cleanup). `Zend/zend_alloc.h` also gains
  `#include <stdlib.h>` so the call is declared (the original code relied on an
  implicit declaration of `exit`).

## Source packages (sha256 pinned in the Dockerfile)

- php5 5.6.40+dfsg-0+deb8u12 from the official Debian jessie-security archive
  `http://archive.debian.org/debian-security/pool/updates/main/p/php5/`:
  - `57771203be7b7f8485bcf4e134e2ffffcd93574780d3f9c68a49b79a73c4382e`  `php5_5.6.40+dfsg-0+deb8u12.dsc`
  - `1ffdf771591b6afdff5c3b2b22febe6043f92bc67bb6f8e4629183127819345d`  `php5_5.6.40+dfsg.orig.tar.gz`
  - `4ad44b74eb76b077c3f44b81266cc5b1cb47d138b0af70c1a2b57afbce02aafa`  `php5_5.6.40+dfsg-0+deb8u12.debian.tar.xz`
- The built 5.6 debs are versioned `5.6.40+dfsg-0+deb8u12` - Debian's own version, so
  they replace the stock php5-* packages in base images in place (the php5 extension
  packages pin `php5-common (= 5.6.40+dfsg-0+deb8u12)` strictly).
- The built binaries carry a vendor marker in their version banner (`php -v`):
  `PHP 5.6.40-0+deb8u12+manageservers` (set via `PHP_EXTRA_VERSION` in configure.in).

## Verified (2026-10-21, 2026-10-22)

- 5.6: patch applied to the exact deb source; built with gcc; A/B OOM test:
  unpatched binary - longjmp, request shutdown ran, exit 255; patched binary -
  immediate `_Exit(1)` from the allocator, shutdown never ran, exit 1.
  `max_multipart_body_parts` INI registered (default "-1"). Basic CLI functionality OK.
- 2026-10-22: source switched to the official jessie package (dropped the nmu1 NMU);
  the 5.6 patch applies cleanly on top of the official 86-patch debian series
  (dry-run verified).

## Applying

The multistage Dockerfile in this repo (`Dockerfile`, stage `build-php56`) does this
automatically: the builder stage unpacks the source package with `dpkg-source -x`
(applying the official debian series), appends the patches to `debian/patches/series`,
applies them with `patch -p1 --forward`, and runs `dpkg-buildpackage -b`
(nocheck, build-deps unchecked). If you build the debs out-of-tree instead:

php5 (jessie, format 3.0 quilt):

    cp CVE-2026-109618-109619-php56.patch debian/patches/
    echo CVE-2026-109618-109619-php56.patch >> debian/patches/series # last series entry
    patch -p1 --forward < debian/patches/CVE-2026-109618-109619-php56.patch

## Behavior changes (by design of the upstream minimal mitigation)

1. OOM and integer-overflow in memory allocation now terminate the worker process
   immediately (`_Exit(1)`) instead of `zend_bailout()` longjmp + 500.
   php-fpm replaces the child, Apache replaces the worker.
2. Session upload progress tracking is disabled (the `php_session_rfc1867_callback`
   tracking part is short-circuited) - same as the official 7.4 backport.
   Applications relying on `$_SESSION['_upload']` progress will stop updating it.
   The advisory itself recommends `session.upload_progress.enabled=0`.
3. `max_multipart_body_parts` (default -1 = `max_input_vars` + `max_file_uploads`)
   limits the number of parts in a multipart body; the INI is added by the patch.
4. Multipart part headers: only `Content-Disposition` / `Content-Type` are kept,
   duplicates are ignored (removes an OOM amplification vector).
