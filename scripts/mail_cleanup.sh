#!/bin/sh

#######
### cleanup old messages in Junk and Trash mail folders
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
    printf "\n*** Delete old messages in Junk and Trash folders ***\n\n"
    printf "Usage: ./mail_cleanup.sh --junk-read x --junk-all y --trash z [-p|--path|--mailcow-path path]\n"
    printf "\n\tWhere:\n"
    printf "\t\tx: delete READ messages in the JUNK folder older than this many days\n"
    printf "\t\ty: delete ALL messages in the JUNK folder older than this many days\n"
    printf "\t\tz: delete ALL messages in the TRASH folder older than this many days\n"
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
        --junk-read)
            # expunge READ messages in Junk folder
            if [ -n "$2" ]; then
                deleteJunkRead="$2"
                shift
            else
                badParam empty "$@"
            fi
            ;;
        --junk-all)
            # expunge messages in Junk folder older than...
            if [ -n "$2" ]; then
                deleteJunkAll="$2"
                shift
            else
                badParam empty "$@"
            fi
            ;;
        --trash)
            # expunge messages in Trash folder older than...
            if [ -n "$2" ]; then
                deleteTrash="$2"
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
if [ -z "$deleteJunkRead" ]; then
    badParam nospecify '--junk-read'
elif [ -z "$deleteJunkAll" ]; then
    badParam nospecify '--junk-all'
elif [ -z "$deleteTrash" ]; then
    badParam nospecify '--trash'
fi


### display parameters being used
printf "\nUsing parameters:\n"
printf "delete READ junk messages after %s days\n" "$deleteJunkRead"
printf "delete ALL junk messages after %s days\n" "$deleteJunkAll"
printf "delete ALL messages in trash older than %s days\n" "$deleteTrash"
printf "mailcow path: %s\n\n" "$mailcowPath"


### execute doveadm using parameters provided
if ! cd "$mailcowPath" > /dev/null 2>&1; then
    printf "Can't change to specified mailcow-dockerized directory!\n"
    printf "\t(%s)\n\n" "$mailcowPath"
    printf "Exiting. No actions performed.\n\n"
    exit 2
fi

# clean up read junk mail
printf "Cleaning up READ junk mail...\n"
/usr/local/bin/docker-compose exec -T dovecot-mailcow doveadm expunge -A mailbox 'Junk' SEEN NOT SINCE ${deleteJunkRead}d
# clean up all junk mail
printf "Cleaning up OLD junk mail...\n"
/usr/local/bin/docker-compose exec -T dovecot-mailcow doveadm expunge -A mailbox 'Junk' SAVEDBEFORE ${deleteJunkAll}d
# clean up trash
printf "Cleaning up TRASH...\n"
/usr/local/bin/docker-compose exec -T dovecot-mailcow doveadm expunge -A mailbox 'Trash' SAVEDBEFORE ${deleteTrash}d


### exit gracefully
printf "...done\n\n"

exit 0
