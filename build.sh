#!/bin/bash
#
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0 # builtin bash timer
ZIPNAME="Azrael-X2PRO-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="$HOME/clang-proton"
DEFCONFIG="RMX1931_defconfig"

export PATH="$TC_DIR/bin:$PATH"

if ! [ -d "$TC_DIR" ]; then
	echo "clang-proton not found! Cloning to $TC_DIR..."
	if ! git clone --depth=1 https://gitlab.com/LeCmnGend/proton-clang.git "$TC_DIR"; then
		echo "Cloning failed! Aborting..."
		exit 1
	fi
fi

if [[ $1 = "-r" || $1 = "--regen" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG savedefconfig
	cp out/defconfig arch/arm64/configs/$DEFCONFIG
	exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
	rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CONFIG_NO_ERROR_ON_MISMATCH=y 2>&1 | tee error.log - Image.gz dtbo.img

kernel="out/arch/arm64/boot/Image.gz"
dtb="out/arch/arm64/boot/dts/qcom/sm8150-v2.dtb"
dtbo="out/arch/arm64/boot/dtbo.img"

 git clone https://github.com/AbzRaider/AnyKernel_RMX3.git -b x2PRO 
		
	
	cp $kernel $dtbo AnyKernel_RMX3
	cp $dtb AnyKernel_RMX3/dtb
	rm -f *zip
	cd AnyKernel_RMX3 || exit
	rm -rf out/arch/arm64/boot
	zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
	cd ..
	rm -rf AnyKernel_RMX3
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	echo "Zip: $ZIPNAME"
	curl --upload-file "$ZIPNAME" https://free.keep.sh
	echo
else
	echo -e "\nCompilation failed!"
fi
