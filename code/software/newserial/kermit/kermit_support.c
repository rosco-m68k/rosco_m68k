/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v1
 * ------------------------------------------------------------
 * Copyright (c)2019 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Glue code for the Kermit kernel loader
 * ------------------------------------------------------------
 */

#include "cdefs.h"
#include "kermit.h"
#include "platform.h"
#include "rtlsupport.h"

UCHAR o_buf[OBUFLEN+8];         /* File output buffer */
UCHAR i_buf[IBUFLEN+8];         /* File input buffer */

static struct k_data k;
static struct k_response response;

extern uint8_t *kernel_load_ptr;
static uint8_t *current_load_ptr;
extern void SENDCHAR(uint8_t c);
extern uint8_t RECVCHAR();

static int inchk(struct k_data * k) {
    return -1;
}

static int readpkt(struct k_data * k, UCHAR *p, int len) {
    int x, n;
    short flag;
    UCHAR c;

    flag = n = 0;

    while (1) {
        x = RECVCHAR();
        c = (k->parity) ? x & 0x7f : x & 0xff;      /* Strip parity */

        if (!flag && c != k->r_soh)                 /* No start of packet yet */
          continue;                                 /* so discard these bytes. */

        if (c == k->r_soh) {                        /* Start of packet */
            flag = 1;                               /* Remember */
            continue;                               /* But discard. */
        } else if (c == k->r_eom                    /* Packet terminator */
           || c == '\012'                           /* 1.3: For HyperTerminal */
           ) {
            return(n);
        } else {                                    /* Contents of packet */
            if (n++ > k->r_maxlen)                  /* Check length */
              return(0);
            else
              *p++ = x & 0xff;
        }
    }

    return(-1);
}

static int tx_data(struct k_data * k, UCHAR *p, int n) {
    for (int i = 0; i < n; i++) {
        SENDCHAR(*p++);
    }

    return(X_OK);                                   /* Success */
}

static int openfile(struct k_data * k, UCHAR * s, int mode) {
    return X_OK;
}

/* Suspect this function isn't needed since we're receive-only... */
static ULONG fileinfo(struct k_data * k, UCHAR * filename, UCHAR * buf, int buflen, short * type, short mode) {
    buf[0] = 0;             /* "Cannot determine" file time.. */
    *type = 1;              /* Always binary... */
    return X_OK;
}

/* Suspect this function isn't needed since we're receive-only... */
static int readfile(struct k_data * k) {
    return -1;
}

static int writefile(struct k_data * k, UCHAR * s, int n) {
    memcpy(s, current_load_ptr, n);
    current_load_ptr += n;
    return X_OK;
}

static int closefile(struct k_data * k, UCHAR c, int mode) {
    return X_OK;
}

int receive_kernel() {
    int status, rx_len;
    uint8_t *inbuf;
    short r_slot;

    current_load_ptr = kernel_load_ptr;

    k.xfermode = 1;                                 /* Manual select  */
    k.remote = 1;                                   /* Remote */
    k.binary = 1;                                   /* Binary mode */
    k.parity = 0;                                   /* No parity */
    k.bct = 3;                                      /* Not sure, I think 3 is CRC... */
    k.ikeep = 1;                                    /* Keep incompletely received files */
    k.filelist = 0;                                 /* List of files to send (if any) */
    k.cancel = 0;                                   /* Not cancelled yet */

/*  Fill in the i/o pointers  */

    k.zinbuf = i_buf;                               /* File input buffer */
    k.zinlen = IBUFLEN;                             /* File input buffer length */
    k.zincnt = 0;                                   /* File input buffer position */
    k.obuf = o_buf;                                 /* File output buffer */
    k.obuflen = OBUFLEN;                            /* File output buffer length */
    k.obufpos = 0;                                  /* File output buffer position */

/* Fill in function pointers */

    k.rxd    = readpkt;                             /* for reading packets */
    k.txd    = tx_data;                             /* for sending packets */
    k.ixd    = inchk;                               /* for checking connection */
    k.openf  = openfile;                            /* for opening files */
    k.finfo  = fileinfo;                            /* for getting file info */
    k.readf  = readfile;                            /* for reading files */
    k.writef = writefile;                           /* for writing to output file */
    k.closef = closefile;                           /* for closing files */

    status = kermit(K_INIT, &k, 0, 0, "", &response);
    if (status != X_OK) {
        return 0;
    }

    while (status != X_DONE) {
        inbuf = getrslot(&k,&r_slot);               /* Allocate a window slot */
        rx_len = k.rxd(&k,inbuf,P_PKTLEN);          /* Try to read a packet */

        if (rx_len < 1) {                           /* No data was read */
            freerslot(&k,r_slot);                   /* So free the window slot */
            if (rx_len < 0)                         /* If there was a fatal error */
              return 0;                             /* give up */
        }

        switch (status = kermit(K_RUN, &k, r_slot, rx_len, "", &response)) {
        case X_OK:
            continue;                               /* Keep looping */
        case X_DONE:
            break;                                  /* Finished */
        case X_ERROR:
            return 0;                               /* Failed */
        }
    }

    return 1;
}
