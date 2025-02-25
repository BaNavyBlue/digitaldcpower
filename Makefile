# makefile, written by guido socher
MCU=atmega8
DUDECPUTYPE=m8
CC=avr-gcc
OBJCOPY=avr-objcopy
# optimize for size:
CFLAGS=-g -mmcu=$(MCU) -Wall -Wstrict-prototypes -Os -mcall-prologues
#
LOADCMD=avrdude
LOADARG=-p $(DUDECPUTYPE) -c stk500v2 -e -U flash:w:
#-------------------
.PHONY: all
all: main.hex
#
main: main.hex 
#
#-------------------
help: 
	@echo "Usage: make help"
	@echo "       Print this help"
	@echo " "
	@echo "Usage: make all|load|load_pre|rdfuses|fuse|wrfuse4mhz"
	@echo "       program using the avrdude programmer"
	@echo " "
	@echo "Usage: make clean"
	@echo "       delete all generated files except the pre-compiled ones"
#-------------------
main.hex: main.out 
	$(OBJCOPY) -R .eeprom -O ihex main.out main.hex 
	avr-size main.out
	@echo " "
	@echo "Expl.: data=initialized data, bss=uninitialized data, text=code"
	@echo " "
main.out: main.o lcd.o analog.o dac.o kbd.o i2c_avr.o
	$(CC) $(CFLAGS) -o main.out -Wl,-Map,main.map main.o lcd.o analog.o dac.o kbd.o i2c_avr.o
main.o: main.c lcd.h analog.h hardware_settings.h avr_compat.h kbd.h i2c_avr.h
	$(CC) $(CFLAGS) -Os -c main.c
#-------------------
lcd.o : lcd.c lcd.h lcd_hw.h
	$(CC) $(CFLAGS) -Os -c lcd.c
#-------------------
i2c_avr.o : i2c_avr.c i2c_avr.h avr_compat.h
	$(CC) $(CFLAGS) -Os -c i2c_avr.c
#-------------------
analog.o : analog.c analog.h avr_compat.h hardware_settings.h
	$(CC) $(CFLAGS) -Os -c analog.c
#-------------------
dac.o : dac.c dac.h avr_compat.h
	$(CC) $(CFLAGS) -Os -c dac.c
#-------------------
kbd.o : kbd.c kbd.h avr_compat.h
	$(CC) $(CFLAGS) -Os -c kbd.c
#-------------------
load: main.hex
	$(LOADCMD) $(LOADARG)main.hex
#
# here is a pre-compiled version in case you have trouble with
# your development environment
load_pre: main_pre.hex
	$(LOADCMD) $(LOADARG)main_pre.hex
#
pre: main.hex
	cp main.hex main_pre.hex
#-------------------
# fuse byte settings:
#  Atmel AVR ATmega8 
#  Fuse Low Byte      = 0xe1 (1MHz internal), 0xe3 (4MHz internal), 0xe4 (8MHz internal)
#  Fuse High Byte     = 0xd9 
#  Factory default is 0xe1 for low byte and 0xd9 for high byte
# Check this with make rdfuses
rdfuses:
	avrdude -p $(DUDECPUTYPE) -c stk500v2 -v -q
# use internal RC oscillator 4 Mhz (lf=0xe3 hf=0xd9)
fuse:
	avrdude -p  $(DUDECPUTYPE) -c stk500v2 -u -v -U lfuse:w:0xe3:m
	avrdude -p  $(DUDECPUTYPE) -c stk500v2 -u -v -U hfuse:w:0xd9:m
# use internal RC oscillator 4 Mhz (lf=0xe3 hf=0xd9)
wrfuse4mhz:
	avrdude -p  $(DUDECPUTYPE) -c stk500v2 -u -v -U lfuse:w:0xe3:m
	avrdude -p  $(DUDECPUTYPE) -c stk500v2 -u -v -U hfuse:w:0xd9:m
#-------------------
clean:
	rm -f *.o *.map *.out test*.hex main.hex 
#-------------------
