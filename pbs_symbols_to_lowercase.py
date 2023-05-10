import os
import re

def convert_to_lowercase(file_path):
    # Define a list of symbols that should be included to lowercase conversion
    include_symbols = ['Brown', 'Bipedal']
    #if word in include_symbols and len(word) > 1:
        #    words[i] = word.lower()

    # Define a list of symbols that should be excluded from lowercase conversion
    exclude_symbols = [
        ':RTP', ':_INTL', ':_I', ':UP', ':DOWN', ':LEFT', ':RIGHT',
        ':BACKSPACE', ':DELETE', ':HOME', ':END', ':RETURN', ':BGM',
        ':ME', ':ME', ':BGS', ':SE', ':XXX', ':ESCAPE', ':DATA',
        ':DATA_FILENAME', ':OPTIONAL', ':PBS_BASE_FILENAME'
    ]
    # Create a temporary file to write the modified text
    temp_file_path = file_path + '.tmp'

    # Open the input file and the temporary output file
    with open(file_path, 'r', encoding='utf-8') as input_file, open(temp_file_path, 'w', encoding='utf-8') as output_file:
        # If the file extension is .rb, only convert symbols to lowercase
        if file_path.endswith('.rb'):
            # Define a regular expression pattern to match symbols
            symbol_pattern = re.compile(r'(?<!:):[A-Z_]+\b')
            # For each line in the file, convert symbols to lowercase (except for excluded symbols)
            for line in input_file:
                # If the line contains an excluded symbol, write the line as-is to the output file
                if any(symbol.upper() in line for symbol in exclude_symbols):
                    output_file.write(line)
                else:
                    # If the line doesn't contain any excluded symbols, convert symbols to lowercase
                    modified_line = re.sub(symbol_pattern, lambda m: m.group(0).lower(), line)
                    output_file.write(modified_line)
        else:
            # Iterate over each line in the input file
            for line in input_file:
                # Check if the line starts with the string 'Evolutions'
                if line.startswith('Evolutions'):
                    # Split the line into parts using the '=' delimiter and remove leading/trailing whitespace
                    evolution = line.strip().split('=')
                    parts = [part.strip() for part in evolution[1].split(',')]

                    # Create a list of valid evolution types
                    evolution_list = ['Item', 'TradeItem', 'HasMove', 'NightHoldItem', 'DayHoldItem', 'HasInParty', 'TradeSpecies', 'HoldItem']

                    # Convert the parts to lowercase
                    parts[0] = parts[0].lower()
                    if parts[1] in evolution_list:
                        parts[2] = parts[2].lower()
                    if len(parts) > 3:
                        parts[3] = parts[3].lower()
                        if parts[4] in evolution_list:
                            parts[5] = parts[5].lower()
                    if len(parts) > 6:
                        parts[6] = parts[6].lower()
                        if parts[7] in evolution_list:
                            parts[8] = parts[8].lower()
                    if len(parts) > 9:
                        parts[9] = parts[9].lower()
                        if parts[10] in evolution_list:
                            parts[11] = parts[11].lower()
                    if len(parts) > 12:
                        parts[12] = parts[12].lower()
                        if parts[13] in evolution_list:
                            parts[14] = parts[14].lower()
                    if len(parts) > 15:
                        parts[15] = parts[15].lower()
                        if parts[16] in evolution_list:
                            parts[17] = parts[17].lower()
                    if len(parts) > 18:
                        parts[18] = parts[18].lower()
                        if parts[19] in evolution_list:
                            parts[20] = parts[20].lower()
                    if len(parts) > 21:
                        parts[21] = parts[21].lower()
                        if parts[22] in evolution_list:
                            parts[23] = parts[23].lower()
                    if len(parts) > 24:
                        parts[24] = parts[24].lower()
                    if len(parts) > 27:
                        parts[27] = parts[27].lower()
                    # Join the modified parts back into a single line
                    modified_line = evolution[0] + '= ' + ','.join(parts) + '\n'
                    # If it does, write the line to the output file as-is
                    output_file.write(modified_line)
                else:
                    # Iterate through each line of the input file
                    for line in input_file:
                        # Split the line into separate words
                        words = line.strip().split()
                        # Convert uppercase words longer than one character to lowercase
                        modified_words = [word.lower() if word.isupper() and len(word) > 1 else word for word in words]
                        # Join the modified words back into a single line and add a newline character
                        modified_line = ' '.join(modified_words) + '\n'
                        # If the line starts with any of the specified prefixes, write it to the output file as-is
                        if any(line.startswith(x) for x in ['Name = TM', 'Name = TR', 'EndSpeechWin', 'EndSpeechLose', 'Evolutions', 'BeginSpeech', 'FieldUse']):
                            output_file.write(line)
                        # Otherwise, write the modified line to the output file
                        else:
                            output_file.write(modified_line)

    # Replace the original file with the temporary file
    os.replace(temp_file_path, file_path)


def process_folder(folder_path, exclude_txt=[]):
    # Loop through all files and directories in the given folder
    for name in os.listdir(folder_path):
        # Construct the full path to the file or directory
        path = os.path.join(folder_path, name)

        # If the path is a directory, recursively process it
        if os.path.isdir(path):
            process_folder(path, exclude_txt)
        # If the path is a .txt or .rb file and is not in the exclusion list, convert its contents to lowercase
        elif os.path.isfile(path) and name.endswith(('.txt', '.rb')) and name not in exclude_txt:
            convert_to_lowercase(path)

def process_folders(root_directories, exclude_txt=[]):
    # Loop through all root directories
    for root_directory in root_directories:
        # Recursively process all files and directories in the root directory
        process_folder(root_directory, exclude_txt)

# Specify a list of root directories to start the search
root_directories = ['PBS', 'Data/Scripts']
exclude_list = ["map_connections.txt", "map_metadata.txt", "dungeon_tilesets.txt", 'phone.txt']
# Recursively process all files and directories in each root directory
process_folders(root_directories, exclude_list)