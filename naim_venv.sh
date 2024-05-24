#!/bin/bash

#############################################################################################################################
#                                                                                                                           #
#                                               Collecting basic info                                                       #
#                                                                                                                           #
#############################################################################################################################

script_directory="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
resource_path="$script_directory/Resources/naim_venv_list.txt"
script_name="$(grep -oE "[^/]+?$" <<< "$(grep -oE "/?[^/]+?$" <<< ${BASH_SOURCE[@]})")"

#############################################################################################################################
#                                                                                                                           #
#                                                  About this script                                                        #
#                                                                                                                           #
#############################################################################################################################

# Use "bash naim_venv.sh -h" for help 
About="This script was created for managing python virtual environments, specially when 
there is too many environments with multiple purposes. You can save each of your 
environment using an unique name that will point to the path of your environment. 
This script will also create a resource file where it can save all the references.

I recommend you to create all of your python environments using this script, 
but you can also add your existing environments.

I also recommend you add this script in your \"~/.bashrc\" file. 
This will allow you to excute this script using custom name(command).    \e[0;1;33m
To add this script in your bashrc file:   \e[0;1;37m
echo \"alias nv=\\\"source $script_directory/$script_name\\\"\" >> ~/.bashrc && source ~/.bashrc    \e[0;1;33m

Examples to run this script:    \e[0;1;37m
bash $script_name command \$1 \$2        or
source $script_name command \$1 \$2
"

#############################################################################################################################
#                                                                                                                           #
#                                                    Basic info functions                                                   #
#                                                                                                                           #
#############################################################################################################################

# If resource file not found, create it
check_create_resource(){
    # If resource directory not found, try to create both resource directory and file
    if [[ ! -d "$script_directory/Resources" ]]; then
        # Ask the user if he wants to create the resource file
        echo -e "\e[1;31m The resource file is vital for this script to run, either you create it or change the \"resource_path\" variable"
        echo -e "\e[1;33m Do you want to create \"$resource_path\" (resource file)? [y/n]: \e[0m" && read ans

        # If user agrees, create it
        if [[ $(grep -iE "^y$|^yes$" <<< $ans) ]]; then
            # Step 1: Try to create the resource directory
            mkdir "$script_directory/Resources"

            # If created successfully, print a message
            if [[ $? == 0 ]]; then
                echo -e "\e[1;32m Successfully created \"$script_directory/Resources\" directory \e[0m"
            
            # If failed to create, show an error and ask use to create it manually
            else
                echo -e "\e[1;31m Error! Failed to create resource directory!"
                echo -e "You may like to create it uing \"mkdir $script_directory/Resources\" \e[0m"
                return 1
            fi

            # Step 2: Try to create the resource file
            touch "$resource_path"

            # If created successfully, print a message
            if [[ $? == 0 ]]; then
                echo -e "\e[1;32m Successfully created \"$resource_path\" file \e[0m"
            
            # If failed to create, show an error and ask use to create it manually
            else
                echo -e "\e[1;31m Error! Failed to create resource file!"
                echo -e "You may like to create it uing \"touch $resource_path\" \e[0m"
                return 1
            fi

        # If user does not agree, cancel the action
        elif [[ $(grep -iE "^n$|^no$" <<< $ans) ]]; then
            echo -e "\e[1;32m Action canceled! \e[0m"
            return 1

        # If unknown input given, ask again
        else
            check_create_resource
        fi
    
    # If resource file not found but resource directory exists, try to create the resource file only
    elif [[ ! -e "$resource_path" ]]; then
        # Ask the user if he wants to create the resource file
        echo -e "\e[1;31m The resource file is vital for this script to run, either you create it or change the \"resource_path\" variable"
        echo -e "\e[1;33m Do you want to create \"$resource_path\"(resource file)? [y/n]: \e[0m" && read ans

        # If user agrees, create it
        if [[ $(grep -iE "^y$|^yes$" <<< $ans) ]]; then
            # Try to create the resource file
            touch "$resource_path"

            # If created successfully, print a message
            if [[ $? == 0 ]]; then
                echo -e "\e[1;32m Successfully created \"$resource_path\" file \e[0m"
            
            # If failed to create, show an error and ask use to create it manually
            else
                echo -e "\e[1;31m Error! Failed to create resource file!"
                echo -e "You may like to create it uing \"touch $resource_path\" \e[0m"
                return 1
            fi

        # If user does not agree, cancel the action
        elif [[ $(grep -iE "^n$|^no$" <<< $ans) ]]; then
            echo -e "\e[1;32m Action canceled! \e[0m"
            return 1

        # If unknown input given, ask again
        else
            check_create_resource
        fi
    
    # If noting missing, return 0
    else
        return 0
    fi
}


# See if the script is running on same session or not (needed for some cases not all)
sourced(){
    # If script is running without "source" command, show a warning
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        echo -e "\e[1;31m Use \"source\" command to run scripts in this session \e[0m"
        return 1
    
    # If script is running using "source" command, return 0
    else
        return 0
    fi
}

#############################################################################################################################
#                                                                                                                           #
#                                  Functions to get informations from the resource file                                     #
#                                                                                                                           #
#############################################################################################################################

# Get path of a environment from the resource file
get_venv_path(){        # $1(reference name)
    # Read entire resource file and search for the reference name
    read ref_name ref_path <<< $(grep -E "^$1 " $resource_path)

    # If matches, print the path of the reference name
    if [[ $ref_name ]]; then
        echo "$ref_path"
    
    # Else, show an error
    else
        echo -e "\e[1;31m Error! Reference name \"$1\" does not exist in resource file! \e[0m"
        return 1
    fi
}

#############################################################################################################################
#                                                                                                                           #
#                                             Set all the commands for the user                                             #
#                                                                                                                           #
#############################################################################################################################

# Creating an array using strings(commands for user to use) as index, to call the function
declare -A command_dictionary
command_dictionary["help"]="show_help"               # -h
command_dictionary["list"]="show_list"               # -l
command_dictionary["search"]="isearch_venv"          # -s
command_dictionary["Search"]="search_venv"           # -S
command_dictionary["path"]="show_venv_path"          # -p
command_dictionary["goto"]="change_dir"              # -g
command_dictionary["Goto"]="goto_script_directory"   # -G
command_dictionary["activate"]="activate_venv"       # -a
command_dictionary["addvenv"]="add_resource"         # -A
command_dictionary["create"]="create_venv"           # -c
command_dictionary["delete"]="delete_venv"           # -d
command_dictionary["rename"]="rename_venv"           # -r
command_dictionary["update"]="update_venv"           # -u
command_dictionary["cpcmd"]="copy_commands_to_bin"   # -C
command_dictionary["freeze"]="create_requirements"   # -f

# Creating an array using characters(flags for user to use) as index, to call the functions
declare -A flag_dictionary
flag_dictionary["h"]="show_help"
flag_dictionary["l"]="show_list"
flag_dictionary["s"]="isearch_venv"
flag_dictionary["S"]="search_venv"
flag_dictionary["p"]="show_venv_path"
flag_dictionary["g"]="change_dir"
flag_dictionary["G"]="goto_script_directory"
flag_dictionary["a"]="activate_venv"
flag_dictionary["A"]="add_resource"
flag_dictionary["c"]="create_venv"
flag_dictionary["d"]="delete_venv"
flag_dictionary["r"]="rename_venv"
flag_dictionary["u"]="update_venv"
flag_dictionary["C"]="copy_commands_to_bin"
flag_dictionary["f"]="create_requirements"

#############################################################################################################################
#                                                                                                                           #
#                                      Create a function for each of those commands                                         #
#                                                                                                                           #
#############################################################################################################################

# bash naim_venv.sh -h
show_help(){
    # Pring the "About" of this script
    echo -e "\e[1;32m$About\e[0m"
    # Creating an array using commands as index, for the help command
    declare -a help_dictionary
    help_dictionary[0]="help, -h Show all available commands"
    help_dictionary[1]="list, -l Show list of all references"
    help_dictionary[2]="search, -s Search for reference (ingnore case)      \e[0;1;33m
    \n\t Secondary flags: -n -> referance name, -p -> referance path; and
    \n\t no secondary flag to search in both     \e[0;1;37m
    \n\t Example: bash $script_name -s -n \"keyword\"\t and
    \n\t Example: bash $script_name -s \"keyword\""
    help_dictionary[3]="Search, -S Search for reference (case sensetive)    \e[0;1;33m
    \n\t Secondary flags: -n -> referance name, -p -> referance path; and
    \n\t no secondary flag to search in both     \e[0;1;37m
    \n\t Example: bash $script_name -S -n \"keyword\"\t and
    \n\t Example: bash $script_name -S \"keyword\""
    help_dictionary[4]="path, -p Show the path of the reference"
    help_dictionary[5]="goto, -g Goto the directory of the reference"
    help_dictionary[6]="Goto, -G Goto the directory of the bash script"
    help_dictionary[7]="activate, -a Activate an environment"
    help_dictionary[8]="addvenv, -A Add new reference to the list as reference \$1 and path \$2"
    help_dictionary[9]="create, -c Create a new virtual environment as reference name \$1 and envname \$2"
    help_dictionary[10]="delete, -d Delete the reference of a environment"
    help_dictionary[11]="rename, -r Rename a reference name from \$1 to \$2"
    help_dictionary[12]="update, -u Update all python libraries of a environment    \e[0;1;33m
    \n\t (default current environment)"
    help_dictionary[13]="cpcmd, -C Copy Command \$2 to the bin of the reference \$1"
    help_dictionary[14]="freeze, -f Create requirements.txt file from a environment     \e[0;1;33m
    \n\t (default current environment)"

    # Read all the elements of the array one by one and print
    for ii in "${help_dictionary[@]}"; do
        help_list=( $ii )
        echo -e "\e[1;32m ${help_list[0]} ${help_list[1]} \e[0;33m■■🞂\e[0;1;32m ${help_list[@]:2} \e[0m"
    done
}


# bash naim_venv.sh -l
show_list() {
    # Read every line from the resource file and show output
    cat "$resource_path" | while read -r i j; do
        echo -e "\e[1;32m $i \e[0;33m■■🞂\e[0;1;32m$j \e[0m"
    done
}


# bash naim_venv.sh -s -n keyword
isearch_venv(){      # $1 2$?``
    # If all the necessary inputs are given, start the function
    if [[ $1 ]]; then
        # See if second flag in been used (Second flag could be n=referance name, p=referance path, b=both)
        if [[ ${1:0:1} == '-' ]]; then
            # If $1 == -n, then search for reference name only
            if [[ ${1:0:2} == "-n" ]]; then
                # Read each line and search for the pattern, print if matches
                grep -iE "^[^ ]*$2[^ ]* " $resource_path | while read -r i j; do
                    echo -e "\e[1;32m $i \e[0;33m■■🞂\e[0;1;32m $j \e[0m"
                done

            # If $1 == -p, then search for reference path only
            elif [[ ${1:0:2} == "-p" ]]; then
                # Read each line and search for the pattern, print if matches
                grep -iE " [^ ]*$2[^ ]*$" $resource_path | while read -r i j; do
                    echo -e "\e[1;32m $i \e[0;33m■■🞂\e[0;1;32m $j \e[0m"
                done

            # else, show an error
            else
                echo -e "\e[1;31m Error! Unknown flag was given! Valid flags are \"-n\" and \"-p\" "
                echo -e " See \"$script_name -h\" for help \e[0m"
            fi
        
        # If no secendary flag is given, search in both
        else
            # Read each line and search for the pattern, print if matches
            grep -i "$1" $resource_path | while read -r i j; do
                echo -e "\e[1;32m $i \e[0;33m■■🞂\e[0;1;32m $j \e[0m"
            done
        fi

    # If no reference name was not given, show an error
    else
        echo -e "\e[1;31m Error! No reference pattern was given! \e[0m"
        return 1
    fi
}


# bash naim_venv.sh -S -n keyword
search_venv(){      # $1 $2?
    # If all the necessary inputs are given, start the function
    if [[ $1 ]]; then
        # See if second flag in been used (Second flag could be n=referance name, p=referance path)
        if [[ ${1:0:1} == '-' ]]; then
            # If $1 == -n, then search for reference name only
            if [[ ${1:0:2} == "-n" ]]; then
                # Read each line and search for the pattern, print if matches
                grep -E "^[^ ]*$2[^ ]* " $resource_path | while read -r i j; do
                    echo -e "\e[1;32m $i \e[0;33m■■🞂\e[0;1;32m $j \e[0m"
                done

            # If $1 == -p, then search for reference path only
            elif [[ ${1:0:2} == "-p" ]]; then
                # Read each line and search for the pattern, print if matches
                grep -E " [^ ]*$2[^ ]*$" $resource_path | while read -r i j; do
                    echo -e "\e[1;32m $i \e[0;33m■■🞂\e[0;1;32m $j \e[0m"
                done

            # else, show an error
            else
                echo -e "\e[1;31m Error! Unknown flag was given! Valid flags are \"-n\" and \"-p\" "
                echo -e " See \"$script_name -h\" for help \e[0m"
            fi
        
        # If no secendary flag is given, search in both
        else
            # Read each line and search for the pattern, print if matches
            grep "$1" $resource_path | while read -r i j; do
                echo -e "\e[1;32m $i \e[0;33m■■🞂\e[0;1;32m $j \e[0m"
            done
        fi

    # If no reference name was not given, show an error
    else
        echo -e "\e[1;31m Error! No reference pattern was given! \e[0m"
        return 1
    fi
}


# path
show_venv_path(){       # $1
    # If all the necessary inputs are given, start the function
    if [[ $1 ]]; then
        # Try to get the path of the environment using get_venv_path function
        venv="$(get_venv_path $1)"

        # If the path is found, print it
        if [[ $? == 0 ]]; then
            echo -e "\e[1;32m $venv \e[0m"
        
        # If the path is not found, show the error message of the get_venv_path function
        else
            echo "$venv"
            return 1
        fi

    # If no reference name was not given, show an error
    else
        echo -e "\e[1;31m Error! No reference name was given! \e[0m"
        return 1
    fi
}


# goto
change_dir(){       # $1
    # If all the necessary inputs are given, start the function
    if [[ $1 ]]; then
        # Try to get the path of the environment using get_venv_path function
        venv="$(get_venv_path $1)"

        # If the path is found, check its existence
        if [[ $? == 0 ]]; then
            # If path exists, try to change directory
            if [[ -d "$venv/.." ]]; then
                cd "$venv/.."

                # If directory changes successfully, print the path
                if [[ $? == 0 ]]; then
                    echo -e "\e[1;32m $(pwd) \e[0m"
                    
                    # See if the script is running on same session or not
                    sourced
                
                # If directory does not changes, show an error
                else
                    echo -e "\e[1;31m Error! Failed to change the directory! \e[0m"
                    return 1
                fi
            
            # If path does not exists, show an error
            else
                echo -e "\e[1;31m Error! Environment \"$1\" and its path does not exits! "
                echo -e " You may use \"$script_name -d $1\" to delete this environment \e[0m"
                return 1
            fi
        
        # If the path is not found, show the error message of the get_venv_path function
        else
            echo "$venv"
            return 1
        fi

    # If no reference name was not given, show an error
    else
        echo -e "\e[1;31m Error! No reference name was given! \e[0m"
        return 1
    fi
}


# Goto
goto_script_directory(){
    # Try to go to the script directory
    cd "$script_directory"

    # If directory changes successfully, print the path
    if [[ $? == 0 ]]; then
        echo -e "\e[1;32m $(pwd) \e[0m"

        # See if the script is running on same session or not
        sourced
            
    # If directory does not changes, show an error
    else
        echo -e "\e[1;31m Error! Failed to change the directory \"$script_directory\"! \e[0m"
        return 1
    fi
}


# activate
activate_venv(){        # $1
    # If all the necessary inputs are given, start the function
    if [[ $1 ]]; then
        # Try to get the reference path using get_venv_path function
        venv="$(get_venv_path $1)"

        # If path is found, try to activate it
        if [[ $? == 0 ]]; then
            source "$venv/bin/activate"

            # If environment is activated successfully, show success message
            if [[ $? == 0 ]]; then
                echo -e "\e[1;32m Environment \"$venv\" activated \e[0m"
                sourced
            
            # If environment activation fails, try to find the reason
            else
                # If environment was deleted, tell the user
                if [[ -e "$venv/bin/activate" ]]; then
                    echo -e "\e[1;31m Error! The environment was deleted \"$1\"! \e[0m"

                # If enviroment is still exists but not executable by the user, tell the user
                elif [[ -x "$2/bin/activate" ]]; then
                    echo -e "\e[1;31m Error! You don't have permission to activate the environment \"$1\"! \e[0m"

                # If environment still exists and also executable, show the general error message
                else
                    echo -e "\e[1;31m Error! Failed to activate environment \"$1\"! \e[0m"
                fi
            fi

        # If path not found, show the error message given by the get_venv_path funciton 
        else
            echo "$venv"
            return 1
        fi
    
    # If no reference name was not given, show an error
    else
        echo -e "\e[1;31m Error! No reference name was given! \e[0m"
        return 1
    fi
}


# addvenv
add_resource(){     # $1 $2
    # If all the necessary inputs are given, start the function
    if [[ $1 && $2 ]]; then
        # If the environment exists, start the process of adding it to the resource file
        if [[ -e "$2/bin/activate" ]]; then
            # Step 1: Find the absolute path
            # If the absolute path is already given, store it for farther use
            if [[ ${2:0:1} == "/" ]]; then
                abs_venv_path="$2"

            # If the absolute path is not given, get it
            else
                abs_venv_path="$(pwd $2)/$2"
            fi

            # Step 2: See if the reference is already present, if not add it
            # If the reference already exists
            resault="$(grep -E "^$1 | $abs_venv_path$" "$resource_path")"
            if [[ $resault ]]; then
                # Read the reference and show an error
                echo "$resault" | while read -r i j; do
                    echo -e "\e[1;31m Error! \"$i \e[0;33m■■🞂\e[0;1;31m $j\" already exists! \e[0m"
                done
                return 1
            
            # If the reference does not already exists, add it
            else
                echo "$1 $abs_venv_path" >> "$resource_path"

                # If successfully added, print the reference
                if [[ $? == 0 ]]; then
                    echo -e "\e[1;32m $1 \e[0;33m■■🞂\e[0;1;32m $abs_venv_path \e[0m"
                
                # If failed to add, show an error
                else
                    echo -e "\e[1;31m Error! Failed to edit resource file! \e[0m"
                    return 1
                fi
            fi
        
        # If the environment does not exists, show an error
        else
            echo -e "\e[1;31m Error! The directory \"$2\" is not a python virtual environment! \e[0m"
            return 1
        fi

    # If no path name was not given, show an error
    elif [[ $1 && -z $2 ]]; then
        echo -e "\e[1;31m Error! No path was given! \e[0m"
        return 1

    # If no reference name was not given, show an error
    else
        echo -e "\e[1;31m Error! No reference name and path was given! \e[0m"
        return 1
    fi
}


# create
create_venv(){      # $1 $2?
    # If all the necessary inputs are given, start the function
    if [[ $1 ]]; then

        # Step 1: Get a name for the envoronment
        # If a name was given, use it
        if [[ $2 ]]; then
            name="$2"
        
        # If no name was given, use the word "venv"
        else
            name="venv"
        fi

        # Step 2: Create the virtual environment and add it to the resource file
        # Try to create the environment
        python3 -m venv "$name"

        # if environment creation is successfull, add it to the resource file
        if [[ $? == 0 ]]; then
            add_resource "$1" "$(pwd)/$name"
            echo -e "\e[1;32m Successfully created environment \"$name\" \e[0m"
        
        # if environment creation is failed, show an error
        else
            echo -e "\e[1;31m Error! Failed to create environment \"$name\"! \e[0m"
            return 1
        fi

    # If no reference name was not given, show an error
    else
        echo -e "\e[1;31m Error! No reference name was given! \e[0m"
        return 1
    fi
}


# delete
delete_venv(){      # $1
    # If all the necessary inputs are given, start the function
    if [[ $1 ]]; then
        # Try to find the reference in the resourcce file
        read line_num_ref_name venv <<< $(grep -nE "^$1 " $resource_path)

        # If the reference is found, try to delete if
        if [[ $line_num_ref_name ]]; then
            # Get the line number
            line_num="${line_num_ref_name:0:-(( ${#1} + 1))}"

            # Delete the specific line
            sed -i "$line_num d" "$resource_path"

            # If successfully deleted, print a message
            if [[ $? == 0 ]]; then
                echo -e "\e[1;32m Successfully deleted reference \"$1\" \e[0m"
            
            # If failed to delete, show an error
            else
                echo -e "\e[1;31m Error! Failed to delete reference \"$1\"! \e[0m"
                return 1
            fi

        # If the reference is not found, show an error
        else
            echo -e "\e[1;31m Error! Reference does not exist! \e[0m"
            return 1
        fi

    # If no reference name was not given, show an error
    else
        echo -e "\e[1;31m Error! No reference name was given! \e[0m"
        return 1
    fi
}


# rename
rename_venv(){      # $1 $2
    # If all the necessary inputs are given, start the function
    if [[ $1 && $2 ]]; then
        # Try to find the reference path
        venv=$(get_venv_path $1)

        # If reference exists
        if [[ $? == 0 ]]; then
            # Try to delete the reference
            msg1="$(delete_venv $1)"

            # If successfully deleted then try to add new reference
            if [[ $? == 0 ]]; then
                # Try to add the new reference
                msg2="$(add_resource "$2" "$venv")"

                # If reference added successfully show success message
                if [[ $? == 0 ]]; then
                    echo -e "\e[1;32m Successfully renamed reference name \"$1\" to \"$2\" \e[0m"

                # If reference added failed
                else
                    # Try to restore old reference 
                    msg3="$(add_resource "$1" "$venv")"

                    # If restore succeeds, show rename failed!
                    if [[ $? == 0 ]]; then
                        echo "$msg2"
                        echo -e "\e[1;31m Error! Failed to rename reference name \"$1\" to \"$2\" \e[0m"
                        return 1

                    # If failed to restore, show errors!
                    else
                        # Error messages
                        echo "$msg2"
                        echo -e "\e[1;31m Error! Failed to rename reference name \"$1\" to \"$2\" \e[0m"
                        echo -e "\e[1;31m Old reference \"$1 \e[0;33m■■🞂\e[0;1;31m $venv\" has been removed \e[0m"
                        return 1
                    fi
                fi
            
            # If reference deletation failed, show the error message given by delete_venv function
            else
                echo "$msg1"
                return 1
            fi

        # If reference does not exists, show the error message given by get_venv_path function
        else
            echo "$venv"
            return 1
        fi

    # If new reference name was not given, show an error
    elif [[ $1 && -z $2 ]]; then
        echo -e "\e[1;31m Error! No new reference name was given! \e[0m"
        return 1

    # If no reference name was not given, show an error
    else
        echo -e "\e[1;31m Error! No reference name was given! \e[0m"
        return 1
    fi
}


# update
update_venv(){      # $1?
    # If reference name was given, first try to active the environment then update
    if [[ $1 ]]; then
        # Try to activate the given environment
        activate_venv "$1"

        # If activated successfully, update it
        if [[ $? == 0 ]]; then
            pip install --upgrade pip

            # Update all packages one by one
            pip list | while read -r i j; do
                pip install --upgrade "$i"
            done
        
        # If activation failed, show an error
        else
            echo -e "\e[1;31m Error! Failed to activate environment \"$1\"! \e[0m"
            return 1
        fi

    # If no reference name was not given, update current environment
    else
        # Ask the user if to update the current environment
        echo -e "\e[1;33m Are you sure you want to update current environment? [y/n]: \e[0m" && read ans

        # If user agrees to update the current environment, start updating
        if [[ $(grep -iE "^y$|^yes$" <<< $ans) ]]; then
            pip install --upgrade pip

            # Update all packages one by one
            pip list | while read -r i j; do
                pip install --upgrade "$i"
            done

        # If user does not agree to update the current environment, cancel the action
        elif [[ $(grep -iE "^n$|^no$" <<< $ans) ]]; then
            echo -e "\e[1;32m Action canceled! \e[0m"

        # If unknown input given, ask again
        else
            update_venv $1
        fi
    fi
}


# cpcmd
copy_commands_to_bin(){      # $1 $2
    # If all the necessary inputs are given, start the function
    if [[ $1 && $2 ]]; then
        # Get the path of the reference using get_venv_path function
        venv="$(get_venv_path $1)"

        # If path is found, check if the command file exists
        if [[ $? == 0 ]]; then
            # If the command file exists, check if the file is executable by the current user, then copy it
            if [[ -e $2 ]]; then
                # Step 1: check if file is executable, if not make it
                # If the command file is executable by the current user
                if [[ ! -x $2 ]]; then
                    echo -e "\e[1;31m Warning! The file \"$2\" is not executable by the current user! \e[0m"

                    # Ask the user if he wants to make it executable
                    echo -e "\e[1;33m Are you sure you want to make the \"$2\" file executable? [y/n]: \e[0m" && read ans

                    # If user agrees to change permission, use chmod +x
                    if [[ $(grep -iE "^y$|^yes$" <<< $ans) ]]; then
                        chmod +x "$2"

                        # If succeeds, print a message
                        if [[ $? == 0 ]]; then
                            echo -e "\e[1;32m Successfully changed file permission \e[0m"

                        # If fails, show an error
                        else
                            echo -e "\e[1;31m Error! Failed changed file permission! \e[0m"
                            return 1
                        fi

                    # If user does not agree to change permission, cancel the action
                    elif [[ $(grep -iE "^n$|^no$" <<< $ans) ]]; then
                        echo -e "\e[1;32m Action canceled! \e[0m"

                    # If unknown input given, ask again
                    else
                        copy_commands_to_bin "$1" "$2"
                    fi
                fi

                # Step 2: Check if environment still exists, if not, show an error
                # If environment still exists, try to copy the file
                if [[ -d "$venv/bin/" ]]; then
                    cp "$2" "$venv/bin/"

                    # If copied successfully, print a message
                    if [[ $? == 0 ]]; then
                        echo -e "\e[1;32m Successfully copied file \"$2\" to environment \"$1\" \e[0m"

                    # If failed to copy, show an error
                    else
                        echo -e "\e[1;31m Error! Failed to copy file \"$2\" to environment \"$1\"! \e[0m"
                        return 1
                    fi
                
                # If environment does not exits, show an error
                else
                    echo -e "\e[1;31m Error! Environment does not exits!"
                    echo -e " You may use \"$script_name -d $1\" to delete this environment \e[0m"
                fi
            
            # If command file does not exists, show an error
            else
                echo -e "\e[1;31m Error! File \"$2\" does not exist! \e[0m"
                return 1
            fi

        # If path not found, show the error message given by the get_venv_path funciton 
        else
            echo "$venv"
            return 1
        fi

    # If no file name was not given, show an error
    elif [[ $1 && -z $2 ]]; then
        echo -e "\e[1;31m Error! No file name was given! \e[0m"
        return 1

    # If no reference name was not given, show an error
    else
        echo -e "\e[1;31m Error! No reference and file name was given! \e[0m"
        return 1
    fi
}


# freeze
create_requirements(){      # $1?
    # If reference name of a venv is given, try to activate it first
    if [[ $1 ]]; then
        activate_venv "$1"

        # If activation succeeds, make requirements.txt
        if [[ $? == 0 ]]; then
            pip freeze > requirements.txt

        # If activation fails, show an error message
        else
            echo -e "\e[1;31m Error! Failed to create the requirements.txt file \"$1\"! \e[0m"
            return 1
        fi
    
    # If reference name is not given, make requirements.txt from existing environment 
    else
        pip freeze > requirements.txt
    fi
}

#############################################################################################################################
#                                                                                                                           #
#                                               Ready to run this script                                                    #
#                                                                                                                           #
#############################################################################################################################

# Main function to parse commands and call the relevent functions
main(){     # $1 $2 $3?
    # If a single or multiple commands are given using flags 
    if [[ ${1:0:1} == '-' ]]; then
        # Loop through all the flags one by one in queue order
        for (( i=1; i<${#1}; i++ )); do
            ${flag_dictionary[${1:$i:1}]} "$2" "$3"
        done
    
    # If a single command was given directly
    else
        ${command_dictionary[$1]} "$2" "$3"
    fi
}


# Check for the resource file, if missing, try to create one
check_create_resource

# If resoruce file exists, run the rest
if [[ $? == 0 ]]; then
    # If commands are given
    if [[ $1 ]]; then
        main "$1" "$2" "$3"
    # If commands are missiog
    else
        echo -e "\e[1;31m Error! No commands were given! \e[0m"
    fi

# If resource file does not exists, show an error
else
    echo -e "\e[1;31m Error! Resource file not found! \e[0m"
fi
