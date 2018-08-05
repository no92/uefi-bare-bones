#include <efi.h>
#include <stdbool.h>

/* I'm too lazy to type this out five times */
#define ERR(x) if(EFI_ERROR((x))) return (x)

efi_status efi_main(efi_handle handle __attribute__((unused)), efi_system_table *st) {
	efi_status status;
	efi_input_key key;

	/* reset the watchdog timer */
	status = st->BootServices->SetWatchdogTimer(0, 0, 0, NULL);
	ERR(status);

	/* clear the screen */
	status = st->ConOut->ClearScreen(st->ConOut);
	ERR(status);

	/* print 'Hello World' */
	status = st->ConOut->OutputString(st->ConOut, L"Hello World");
	ERR(status);

	/* flush console input buffer */
	status = st->ConIn->Reset(st->ConIn, false);
	ERR(status);

	/* poll for a keystroke */
	while((status = st->ConIn->ReadKeyStroke(st->ConIn, &key)) == EFI_NOT_READY);
	ERR(status);

	return EFI_SUCCESS;
}
