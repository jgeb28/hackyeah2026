#!/usr/bin/env bash
# Start the Oniro/OpenHarmony emulator in a *windowed* QEMU session that
# actually presents on this host.
#
# Why not run.sh: the stock launcher uses "-vga none -device virtio-gpu-pci".
# On this host (QEMU 11.1.1, Wayland + hybrid GPU) that console is never
# presented and the window only shows "Display output is not active.".
# Using the VGA-class "-vga virtio" (virtio-vga) presents correctly.
#
#   scripts/start-windowed.sh            # SDL, GL on (default)
#   ONIRO_DISPLAY=gtk scripts/start-windowed.sh
#   ONIRO_DISPLAY=sdl,gl=off scripts/start-windowed.sh
#
# Run detached:  setsid nohup scripts/start-windowed.sh >log 2>&1 </dev/null &
set -euo pipefail
DIR="${ONIRO_EMULATOR_IMAGES:-$HOME/ohos/emulator/oniro/images}"
cd "$DIR"
exec qemu-system-x86_64 \
  -machine q35 -smp 6 -m 4096M -boot c \
  -vga virtio \
  -display "${ONIRO_DISPLAY:-sdl,gl=on}" \
  -rtc base=utc,clock=host -device es1370 \
  -initrd ramdisk.img -kernel bzImage \
  -drive if=none,file=updater.img,format=raw,id=updater,index=0 \
  -device virtio-blk-pci,drive=updater \
  -drive if=none,file=system.img,format=raw,id=system,index=1 \
  -device virtio-blk-pci,drive=system \
  -drive if=none,file=vendor.img,format=raw,id=vendor,index=2 \
  -device virtio-blk-pci,drive=vendor \
  -drive if=none,file=userdata.img,format=raw,id=userdata,index=3 \
  -device virtio-blk-pci,drive=userdata \
  -append "ip=dhcp loglevel=4 console=ttyS0,115200 init=init root=/dev/ram0 rw ohos.boot.hardware=x86_general ohos.required_mount.system=/dev/block/vdb@/usr@ext4@ro,barrier=1@wait,required ohos.required_mount.vendor=/dev/block/vdc@/vendor@ext4@ro,barrier=1@wait,required ohos.required_mount.misc=/dev/block/vda@/misc@none@none=@wait,required" \
  -enable-kvm -cpu host \
  -netdev "user,id=net0,hostfwd=tcp::${ONIRO_HDC_PORT:-55555}-:55555" \
  -device virtio-net-pci,netdev=net0
