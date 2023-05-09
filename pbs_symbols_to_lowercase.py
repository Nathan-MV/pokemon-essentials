import os

def convert_to_lowercase(file_path):
    # Create a temporary file to write the modified text
    temp_file_path = file_path + '.tmp'
    with open(file_path, 'r') as input_file, open(temp_file_path, 'w') as output_file:
        for line in input_file:
            # Split the line into words
            words = line.strip().split()
            # Loop through each word in the line
            for i, word in enumerate(words):
                # Check if the word is all uppercase
                if word.isupper():
                    # Convert the word to lowercase
                    words[i] = word.lower()
            # Join the modified words back into a single line
            modified_line = ' '.join(words) + '\n'
            # Write the modified line to the temporary file
            output_file.write(modified_line)

    # Replace the original file with the temporary file
    os.replace(temp_file_path, file_path)


def process_folder(folder_path):
    # Loop through all files and directories in the given folder
    for name in os.listdir(folder_path):
        # Construct the full path to the file or directory
        path = os.path.join(folder_path, name)

        # If the path is a directory, recursively process it
        if os.path.isdir(path):
            process_folder(path)
        # If the path is a .txt file, convert its contents to lowercase
        elif os.path.isfile(path) and name.endswith('.txt'):
            convert_to_lowercase(path)

def process_folders(root_directories):
    # Loop through all root directories
    for root_directory in root_directories:
        # Recursively process all files and directories in the root directory
        process_folder(root_directory)

# Specify a list of root directories to start the search
root_directories = ['PBS', 'Data/Scripts']

# Recursively process all files and directories in each root directory
process_folders(root_directories)