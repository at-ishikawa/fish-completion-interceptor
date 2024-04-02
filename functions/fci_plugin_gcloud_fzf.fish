__fci_functions

function __fci_plugin_gcloud_fzf_gcloud_cli --argument-names groups

    argparse "project=?" "regions=?" "zones=?" "query=?" -- $argv
    set -l options
    if [ -n "$_flag_project" ]
        set -a options "--project=$_flag_project"
    end
    set -l regions (string trim "$_flag_regions")
    if [ -n "$regions" ]
        set -a options --regions=$regions
    end
    set -l zones (string trim "$_flag_zones")
    if [ -n "$zones" ]
        set -a options --zones=$zones
    end

    set -l result ($__FCI_PLUGIN_GCLOUD_FZF_GCLOUD_CLI (string split " " -- $groups) list $options 2>&1)
    set -l cli_status $status
    if [ $cli_status -ne 0 ]
        echo -n -e "$result"
        return $cli_status
    end
    # Assumes an error if there is no resource by gcloud
    if [ (string split "\n" -- $result | wc -l) -lt 2 ]
        echo -n -e "$result"
        return 1
    end

    string split "\n" -- $result
    return 0
end

function __fci_plugin_gcloud_fzf_list -d "The list of group" \
    --argument-names groups

    argparse "project=?" "regions=?" "zones=?" "query=?" -- $argv
    set -l fzf_preview_command "gcloud $groups describe --zone={2} {1}"
    set -l project $_flag_project
    if [ -n "$project" ]
        set -a fzf_preview_command "--project=$project"
    end

    set -l cli_result (__fci_plugin_gcloud_fzf_gcloud_cli $groups "--project=$project" "--regions=$_flag_regions" "--zones=$_flag_zones")
    set -l cli_status $status
    if [ $cli_status -ne 0 ]
        echo -e -n "$cli_result"
        return $cli_status
    end

    string split "\n" -- $cli_result |
        __fci_fzf --multi "--query=$_flag_query" "--preview=$fzf_preview_command" "--header-lines=1" |
        awk '{ print $1 }'
    return $pipestatus[2]
end

function fci_plugin_gcloud_fzf \
    --description "The plugin of fish-completion-interceptor to run gcloud"

    argparse --ignore-unknown 'project=' -- $argv
    set -l project $_flag_project

    # Only support some commands
    if [ (count $argv) -le 3 ]
        return 0
    end

    # $argv[1]: gcloud
    # $argv[2]: group
    # $argv[3]: command
    set -l group $argv[2]

    switch "$group"
        case compute
            # TODO: Parse options
            # TODO: Only supports a command like `gcloud compute instances describe`
            if [ (count $argv) -le 4 ]
                return 0
            end

            set -l sub_group $argv[3]
            set -l command $argv[4]

            # gcloud compute instances list uses --zones, while
            # gcloud compute instances describe uses --zone
            # gcloud compute disks list accepts --regions as well
            argparse --ignore-unknown "regions=?" "region=?" "zones=?" "zone=?" -- $argv
            set -l zones "$_flag_zones $_flag_zone"
            set -l regions "$_flag_regions $_flag_region"

            # Get a last command line argument as a query
            set -l query $argv[-1]

            __fci_plugin_gcloud_fzf_list \
                "$group $sub_group" \
                "--project=$project" \
                "--regions=$regions" \
                "--zones=$zones" \
                "--query=$query"
            return $status
    end

    return 0
end
