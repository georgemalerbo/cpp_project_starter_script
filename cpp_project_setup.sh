###############################################
#
# Description:
#   This script was made as a tool to help me and possibly anyone else new to C++
#   It automates the process of manually creating a new project directory with starter files for various tools that are commonly used.
#   creates a "src" dir for source files and an "include" dir for header files.
#   The script prompts you to enter a project directory location and name, and then creates the subdirectories.
#   A starter "main.cpp" file is always created and any additional source files.
#   The script will also generate corresponding header files for each source file 
#   A "CMakeLists.txt" starter file is also created. 
#   The script does not generate build/make files. The script does not run any cmake commands. Only the starter Cmakelists.txt file is created.
#   The script creates a starter "Doxygen.in" config file
#   Similar to the the cmakelists.txt file, the script does not run any doxygen commands 
#   The script includes some error checking... maybe can be improved
#   One nice thing I added was the abillity for the script to detect if there is already a CXX variable set in the environment. 

# clear terminal
clear

# Here we are checking if the user has already installed the zenity installed, which enables a pop-up file explorer to choose the directory 
# is zenity installed?
if command -v zenity &> /dev/null; then
  # Ask user if they want to use the default project directory location
  read -p "Do you want to use the default project directory location ($HOME)? [y/n]" useDefault
  # Check user's response
  if [[ $useDefault =~ ^[Nn]$ ]]; then
    # Use Zenity to open a file explorer and let the user select the project directory location
    projectLocation=$(zenity --file-selection --directory)
  else
    # Set project directory location to default if the user didn't make any manual selection
    projectLocation=$HOME
  fi
else
  # Zenity is not installed, so prompt user to enter the project directory location manually
  read -p "Enter the project directory location: " projectLocation
fi


# error checking.... -

# The =~ operator in this expression is a Bash regular expression match operator that 
# tests whether the string on the left side matches the regular expression pattern on the right side
# The regular expression pattern ^[a-z_]+$ is enclosed in the / characters to define the pattern 
# and is composed of the following elements:


####################################################
#     ^ The caret symbol is the beginning of the string.
#     [a-z_] This is a character set. matches any lowercase letter or underscore.
#     + plus sign "quantifier" specifies that the character set can appear one or more times (to check if directory already exists)
#     $ The dollar sign indicates the end of string.
# prompt user to enter project directory name with lowercase letters and underscores
while true; do
  read -p "Enter the project directory name (use lowercase letters and underscores): " projectName
  if [[ "$projectName" =~ ^[a-z_]+$ ]]; then
    break
  else
    echo "Error: Project directory name should only contain lowercase letters and underscores. Please try again." >&2
  fi
done

# this should set the project directory path
projectPath="$projectLocation/$projectName"

# error checking - if project directory already exists
if [ -d "$projectPath" ]; then
  echo "Error: Project directory already exists." >&2
  exit 1
fi

# check to see if there is already the CXX env. variable set up for the compilier 
# give user the chance to use a different compilier if they want
echo "Checking for C++ compiler..."
echo " "

if [ -z "$CXX" ]; then
    echo "Which C++ compiler do you want to use?"
    read -p "Enter the compiler path: " compilerPath

    # Check if the user entered a compiler path
    if [ -z "$compilerPath" ]; then
        echo "No compiler path entered. Exiting script."
        exit 1
    fi
else
    compilerPath="$CXX"
    echo "Using default CXX environmental variable: $CXX"
fi

# Check if the compiler exists
if ! command -v "$compilerPath" &> /dev/null; then
    echo "Error: Compiler not found at $compilerPath. Exiting script." >&2
    exit 1
fi

echo "Compiler found at $compilerPath. Script can continue."
echo " "
# added a section that check if a cmake toolchain file env variable is set
echo "Checking for CMAKE_TOOLCHAIN_FILE"
echo " "
if [[ -z "${CMAKE_TOOLCHAIN_FILE}" ]]; then
  echo "CMAKE_TOOLCHAIN_FILE variable is not set"
  echo "Please make sure that the toolchain file specified in the `CMAKE_TOOLCHAIN_FILE` environment"
else
  echo "CMAKE_TOOLCHAIN_FILE variable is set to ${CMAKE_TOOLCHAIN_FILE}"
fi


# Create new project directory
mkdir -p "$projectPath"

# Change to new project directory
cd "$projectPath" || exit

# This will create 2 subdirectories for source and header files
mkdir -p src include

# give opprotunity to individually list file names need src directory
# a main.cpp hello world file is generated automatically
# Corrosponding .h files will be generated automatically and placed in the "include" dir
# in the next section of the script
echo " "
echo " "
echo "Here you can create some starter implementation files needed for your project."
echo "Corresponding header files will be generated automatically"
echo " "
echo "Separate file names with spaces and then press enter (e.g. MyClass.cpp MyClass2.cpp):"
read -r srcFiles

# this is a loop that will look at each source file and create them with corresponding header files
# loop through all source files
for srcFile in $srcFiles; do
  # check for invalid file name
  if [[ ! "$srcFile" =~ ^[A-Z][a-zA-Z0-9]*\.cpp$ ]]; then
    echo "Error: Source file name should start with a capital letter and end with .cpp." >&2
    exit 1
  fi
  # If the file name is valid, process the source file


  # This will extract the class name from file name
  className=$(echo "$srcFile" | sed -e 's/\.cpp$//')
  # Create source file
  cat <<EOF > "src/$srcFile"
#include "$className.h"
// Implement $className methods below:

EOF
  # Inserting text into the create header files and format the text so the top two lines are uppercase
  cat <<EOF > "include/$className.h"
#ifndef $(echo "$className" | tr '[:lower:]' '[:upper:]')_H
#define $(echo "$className" | tr '[:lower:]' '[:upper:]')_H


// Declare $className class below:

#endif // $(echo "$className")

EOF

  echo "Created source and header files for $className class."
  echo " "
done

# create the file in src and insert starter text in main.cpp file
cat <<EOF > src/main.cpp
#include <iostream>
int main() {
    std::cout << "Hello, world!" << std::endl;
    return 0;
}
EOF

# create a starter cmakelists.txt file 
# projectName and compilierPath variables used in this section
cat <<EOF > CMakeLists.txt
cmake_minimum_required(VERSION 3.10)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_TOOLCHAIN_FILE})
project(${projectName})


set(CMAKE_CXX_STANDARD 17)

# Set compiler to use
set(CMAKE_CXX_COMPILER "$compilerPath")

# Add header files
include_directories(include)

# Add source files
file(GLOB SOURCE_FILES "src/*.cpp")

# Create executable
add_executable($projectName \${SOURCE_FILES})

# Specify C++ language for source files
set_source_files_properties(\${SOURCES} PROPERTIES LANGUAGE CXX)

# Specify output path
set(EXECUTABLE_OUTPUT_PATH out)


EOF
echo "Your new project directory was created successfully."

# text inserted into basic starter Doxygen.in - projectName variable used
cat <<EOF > Doxygen.in

PROJECT_NAME = "$projectName"

INPUT = ./src ./include

FILE_PATTERNS = *.cpp *.h

OUTPUT_DIRECTORY = ./docs

GENERATE_HTML = YES

RECURSIVE = YES


EOF

echo "CMakeLists.txt configuration file created successfully."
echo " "
echo " "


echo "Doxygen configuration file created successfully."
echo " "
echo " "



echo "Do you want to initiate a git repository? (y/n)"
read init_git

if [ "$init_git" = "y" ]; then
  git init
echo "Git repo created successfully."
echo "To view the git documentation visit: https://git-scm.com/docs"
echo " "
echo " "
  
  echo "Do you want to make a first commit? (y/n)"
  read make_commit
  
  if [ "$make_commit" = "y" ]; then
    git add .
    echo 'The "git add ." command was run. All files staged'
    echo "Enter first commit message now:"
    read commit_message
    git commit -m "$commit_message"
    echo "Your first commit made with message: $commit_message"
  else
    echo "no commit made"
  fi
else
  echo "no git commands run"
fi


echo "Do you want to open the project directory in VS Code? (y/n)"
read choice

if [ "$choice" = "y" ]; then
  code "$projectPath"
else
  echo "You've reached the end of the script."
  echo As a reminder, your project directory is located at: $projectPath
fi



