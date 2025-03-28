//
//  helper.c
//  StikJIT
//
//  Created by Dusk on 28/3/2025.
//
#include <stdio.h>
#include <stdlib.h>

int read_file(const char *filename, uint8_t **data, size_t *length) {
  FILE *file = fopen(filename, "rb");
  if (!file) {
    perror("Failed to open file");
    return 0;
  }

  fseek(file, 0, SEEK_END);
  *length = ftell(file);
  fseek(file, 0, SEEK_SET);

  *data = malloc(*length);
  if (!*data) {
    perror("Failed to allocate memory");
    fclose(file);
    return 0;
  }

  if (fread(*data, 1, *length, file) != *length) {
    perror("Failed to read file");
    free(*data);
    fclose(file);
    return 0;
  }

  fclose(file);
  return 1;
}
