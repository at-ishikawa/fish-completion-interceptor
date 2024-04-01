function __fci_plugin_gcloud_fzf_gcloud_cli
    set -l args (string trim -- $argv | string split " " | string trim)
    set -l result ($__FCI_PLUGIN_GCLOUD_FZF_GCLOUD_CLI $args 2>&1)
    set -l cli_status $status

    if [ $cli_status -ne 0 ]
        echo -n -e "$result" >&2
        return $cli_status
    end
    # Assumes an error if there is no resource by gcloud
    if [ (string split "\n" -- $result | wc -l) -lt 2 ]
        echo -e "$result" >&2
        return 1
    end

    string split "\n" -- $result
    return 0
end

function __fci_plugin_gcloud_fzf_list -d "The list of group" \
    -a groups \
    project \
    regions \
    zones \
    fzf_query

    set -l cli_options $groups
    set -a cli_options list
    set -l fzf_preview_command "gcloud $groups describe --zone={2} {1}"
    if [ -n "$project" ]
        set -a cli_options --project=$project
        set -a fzf_preview_command "--project=$project"
    end
    set regions (string trim -- $regions)
    if [ -n "$regions" ]
        set -a cli_options --regions=$regions
    end
    set zones (string trim -- $zones)
    if [ -n "$zones" ]
        set -a cli_options --zones=$zones
    end

    fci_run_fzf \
        __fci_plugin_gcloud_fzf_gcloud_cli \
        "$cli_options" \
        "$fzf_query" \
        "$fzf_preview_command" \
        1 \
        --multi

    return $status
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
                "$project" \
                "$regions" \
                "$zones" \
                "$query"
            return $status
    end

    return 0
end
