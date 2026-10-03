#!/usr/bin/env python3
"""Minimal VNC (RFB 3.8) client: connect, request a full Raw framebuffer update,
write a PNG. No external dependencies. Usage: vnccap.py HOST PORT OUT.png"""
import socket, struct, sys, zlib


def recv_exact(s, n):
    b = b""
    while len(b) < n:
        c = s.recv(n - len(b))
        if not c:
            raise EOFError("socket closed")
        b += c
    return b


def png_write(path, w, h, img):
    raw = b"".join(b"\x00" + bytes(img[y * w * 3:(y + 1) * w * 3]) for y in range(h))

    def chunk(t, d):
        c = t + d
        return struct.pack(">I", len(d)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)

    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    open(path, "wb").write(sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def main():
    host, port, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
    s = socket.create_connection((host, port), timeout=20)
    recv_exact(s, 12)                      # server version
    s.sendall(b"RFB 003.008\n")
    nsec = recv_exact(s, 1)[0]
    types = recv_exact(s, nsec)
    s.sendall(bytes([1]) if 1 in types else bytes([types[0]]))   # None auth
    if struct.unpack(">I", recv_exact(s, 4))[0] != 0:
        raise SystemExit("auth failed")
    s.sendall(b"\x01")                      # shared
    hdr = recv_exact(s, 24)
    w, h = struct.unpack(">HH", hdr[0:4])
    bpp, depth, be, truecolor, rmax, gmax, bmax, rsh, gsh, bsh = struct.unpack(">BBBBHHHBBB", hdr[4:17])
    name = recv_exact(s, struct.unpack(">I", hdr[20:24])[0])
    print(f"server={name!r} {w}x{h} bpp={bpp} depth={depth} shifts={rsh}/{gsh}/{bsh}")
    s.sendall(struct.pack(">BBH", 2, 0, 1) + struct.pack(">i", 0))     # SetEncodings: Raw
    s.sendall(struct.pack(">BBHHHH", 3, 0, 0, 0, w, h))                # FramebufferUpdateRequest
    bpp_bytes = bpp // 8
    img = bytearray(w * h * 3)
    while True:
        mt = recv_exact(s, 1)[0]
        if mt != 0:
            continue
        recv_exact(s, 1)
        nrect = struct.unpack(">H", recv_exact(s, 2))[0]
        for _ in range(nrect):
            x, y, rw, rh, enc = struct.unpack(">HHHHi", recv_exact(s, 12))
            if enc != 0:
                raise SystemExit(f"unexpected encoding {enc}")
            data = recv_exact(s, rw * rh * bpp_bytes)
            order = "big" if be else "little"
            for j in range(rh):
                row = data[j * rw * bpp_bytes:(j + 1) * rw * bpp_bytes]
                for i in range(rw):
                    px = int.from_bytes(row[i * bpp_bytes:(i + 1) * bpp_bytes], order)
                    r = ((px >> rsh) & rmax) * 255 // (rmax or 1)
                    g = ((px >> gsh) & gmax) * 255 // (gmax or 1)
                    b = ((px >> bsh) & bmax) * 255 // (bmax or 1)
                    o = ((y + j) * w + (x + i)) * 3
                    img[o], img[o + 1], img[o + 2] = r, g, b
        break
    png_write(out, w, h, img)
    print("wrote", out)


if __name__ == "__main__":
    main()
