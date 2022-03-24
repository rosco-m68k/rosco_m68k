/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2022 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Basic implementations for ctype routines
 * ------------------------------------------------------------
 */

#include <ctype.h>

int isalnum(int c) {
    return isalpha(c) || isdigit(c);
}

int isalpha(int c) {
    return islower(c) || isupper(c);
}

int islower(int c) {
    return c >= 'a' && c <= 'z';
}

int isupper(int c) {
    return c >= 'A' && c <= 'Z';
}

int isdigit(int c) {
    return c >= '0' && c <= '9';
}

int isxdigit(int c) {
    return isdigit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

int iscntrl(int c) {
    return (c >= 0x00 && c <=0x1F) || c == 0x7F;
}

int isgraph(int c) {
    return isalnum(c) || ispunct(c);
}

int isspace(int c) {
    return c == ' ' || c == '\f' || c == '\n' || c == '\r' || c == '\t' || c == '\v';
}

int isblank(int c) {
    return c == ' ' || c == '\t';
}

int isprint(int c) {
    return isgraph(c) || c == ' ';
}

int tolower(int c) {
    return isupper(c) ? (c) + ('a' - 'A') : c;
}

int toupper(int c) {
    return islower(c) ? (c) + ('A' - 'a') : c;
}
