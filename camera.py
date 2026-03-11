#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

void camera_capture_data(uint8_t *buf, size_t bufsize) {
    char tmp_file_name[] = "ecen-224-XXXXXX";
    char *command = "rpicam-still -n --immediate -e bmp --width 128 --height 128 -o ";

    // 1. Create the temporary file name
    // mkstemp opens the file, but we need the camera process to own it
    int fd = mkstemp(tmp_file_name);
    if (fd == -1) return; 
    close(fd); // Close it so rpicam-still can write to it

    // 2. Prepare the command string
    size_t cmd_len = strlen(command) + strlen(tmp_file_name) + 1;
    char *full_command = malloc(cmd_len);
    if (full_command == NULL) return;
    snprintf(full_command, cmd_len, "%s%s", command, tmp_file_name);

    // 3. Run the camera command
    system(full_command);

    // 4. Read the data back into the buffer
    // We open it in read-only mode to start at the beginning of the file
    int read_fd = open(tmp_file_name, O_RDONLY);
    if (read_fd != -1) {
        read(read_fd, buf, bufsize);
        close(read_fd);
    }

    // 5. Clean up
    remove(tmp_file_name);
    free(full_command);
}
