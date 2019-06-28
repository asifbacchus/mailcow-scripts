#!/bin/sh

#######
### cleanup old messages in ALL mail folders older than x days that are SEEN
### and UNflagged
###
### This script is meant to be executed as a CRON job so there is no friendly
### user output or error trapping. Check logs for errors.
#######


### functions

# bad parameters
badParam () {
    if [ "$1" = "empty" ]; then
        printf "\n'%s' cannot have a NULL (empty) value.\n" "$2"
        printf "Please use '--help' for assistance.\n\n"
    elif [ "$1" = "nospecify" ]; then
        printf "\n'%s' was not specified.\n" "$2"
        printf "Please use '--help' for assistance.\n\n"
    fi
    exit 1
}

# script help
scriptHelp () {
    printf "\n*** Delete ALL messages older than x days ***\n"
    printf "*** only READ and UNFLAGGED messages will be removed ***\n\n"
    printf "Usage: ./mail_prune.sh -d|--days x [-p|--path|--mailcow-path path]\n"
    printf "\n\tWhere:\n"
    printf "\t\tx: delete messages (ALL users, ALL folders) older than this many days\n"
    printf "\t\tpath: path to your mailcow-dockerized installation\n"
    printf "\t\t(default: /opt/mailcow-dockerized)\n\n"
    exit 0
}


### startup parameters

# set defaults
mailcowPath="/opt/mailcow-dockerized"

# no parameters given, show help
if [ $# -le 0 ]; then
    scriptHelp
fi

# process startup parameters
while [ $# -gt 0 ]; do
    case "$1" in
        -h|-\?|--help)
            # display help
            scriptHelp
            exit 0
            ;;
        -d|--days)
            # delete messages older than this many days
            if [ -n "$2" ]; then
                deleteOlder="$2"
                shift
            else
                badParam empty "$@"
            fi
            ;;
        -p|--path|--mailcow-path)
            # path to mailcow directory
            if [ -n "$2" ]; then
                mailcowPath="$2"
                shift
            else
                badParam empty "$@"
            fi
            ;;
        *)
            printf "Unknown option: %s\n" "$1"
            printf "Use '--help' for valid options\n\n"
            exit 1
            ;;
    esac
    shift
done


### check for missing parameters
if [ -z "$deleteOlder" ]; then
    badParam nospecify '--days'
fi


### display parameters being used
printf "\nUsing parameters:\n"
printf "delete ALL messages older than %s days\n" "$deleteOlder"
printf "mailcow path: %s\n\n" "$mailcowPath"


### execute doveadm using parameters provided
if ! cd "$mailcowPath" > /dev/null 2>&1; then
    printf "Can't change to specified mailcow-dockerized directory!\n"
    printf "\t(%s)\n\n" "$mailcowPath"
    printf "Exiting. No actions performed.\n\n"
    exit 2
fi

# delete old messages
printf "Deleting OLD messages...\n"
/usr/local/bin/docker-compose exec -T dovecot-mailcow doveadm expunge -A mailbox '*' SEEN UNFLAGGED BEFORE ${deleteOlder}d


### exit gracefully
printf "...done\n\n"

exit 0
