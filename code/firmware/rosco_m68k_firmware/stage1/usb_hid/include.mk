OBJECTS+=usb_hid/interrupt.o usb_hid/ring_buffer.o usb_hid/usbhid.o \
		 usb_hid/usbinput.o usb_hid/usb_efp.o usb_hid/init_subsys.o
DEFINES+=-DUSB_HID
INCLUDES+=-Iusb_hid/include