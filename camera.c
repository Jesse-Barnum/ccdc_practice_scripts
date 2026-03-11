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

void camera_save_to_file(uint8_t *buf, size_t bufsize, char *filename) {
    if (buf == NULL || filename == NULL) {
        return;
    }

    // 1. Open the file for writing
    // O_WRONLY: Write only
    // O_CREAT: Create if it doesn't exist
    // O_TRUNC: Overwrite if it does exist
    // 0644: Standard permissions (owner can read/write, others can read)
    int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    
    if (fd == -1) {
        perror("Error opening file for saving");
        return;
    }

    // 2. Write the entire buffer (Header + Pixels)
    ssize_t bytes_written = write(fd, buf, bufsize);

    // 3. Verify the write was successful
    if (bytes_written != (ssize_t)bufsize) {
        fprintf(stderr, "Warning: Only wrote %ld of %zu bytes\n", bytes_written, bufsize);
    }

    // 4. Close the file descriptor
    close(fd);
}
