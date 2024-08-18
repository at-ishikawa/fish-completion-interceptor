set -g __FCI_PLUGIN_GCLOUD_FZF_GCLOUD_CLI mock_gcloud
set -g FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_gcloud_test
    argparse --ignore-unknown \
        "expected-gcloud-argv=" \
        "mock-gcloud-stdout=" \
        "mock-gcloud-stderr=" \
        "mock-gcloud-status=" \
        -- $argv

    function mock_gcloud \
        --inherit-variable _flag_expected_gcloud_argv \
        --inherit-variable _flag_mock_gcloud_stdout \
        --inherit-variable _flag_mock_gcloud_stderr \
        --inherit-variable _flag_mock_gcloud_status

        set -q _flag_mock_gcloud_status; or set _flag_mock_gcloud_status 0
        if test -n "$_flag_expected_gcloud_argv"; and [ "$argv" != "$_flag_expected_gcloud_argv" ]
            echo "op argv: (expected: $_flag_expected_gcloud_argv, actual: $argv)" >&2
            return 255
        end

        if [ $_flag_mock_gcloud_status -ne 0 ]
            echo -e "$_flag_mock_gcloud_stderr" >&2
            return $_flag_mock_gcloud_status
        end

        echo -e "$_flag_mock_gcloud_stdout"
        return $_flag_mock_gcloud_status
    end

    __fci_plugin_run_test \
        --plugin-function=fci_plugin_gcloud_fzf \
        $argv
end

function run_supported_command_test_cases
    set -l mock_project mock-project

    run_gcloud_test \
        --description "gcloud compute instances list doesn't return anything" \
        --command "gcloud compute instances describe " \
        --expected-gcloud-argv "compute instances list" \
        --mock-gcloud-stdout "Listed 0 items." \
        --expected-status 1 \
        --expected-stdout "Listed 0 items."
    run_gcloud_test \
        --description "gcloud compute instances describe without an argument. gcloud compute instances list returns a single row" \
        --command "gcloud compute instances describe --zone=us-central1-a inst" \
        --expected-gcloud-argv "compute instances list --zones=us-central1-a" \
        --mock-gcloud-stdout "NAME ZONE STATUS\ninstance-1 us-central1-a STAGING" \
        --expected-fzf-option "--multi --header-lines=1 --preview=gcloud compute instances describe --zone={2} {1} --query=inst $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "instance-1 us-central1-a STAGING" \
        --expected-stdout instance-1
    run_gcloud_test \
        --description "gcloud compute instances describe with an argument. gcloud compute instances list returns multiple rows" \
        --command "gcloud --project $mock_project compute instances update inst" \
        --expected-gcloud-argv "compute instances list --project=$mock_project" \
        --mock-gcloud-stdout "NAME ZONE STATUS\ninstance-1 us-central1-a STAGING\ninstance-2 us-central1-b STAGING\ninstance-3 us-central1-c STAGING" \
        --expected-fzf-option "--multi --header-lines=1 --preview=gcloud compute instances describe --zone={2} {1} --project=$mock_project --query=inst $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "instance-2 us-central1-b f1-micro true 10.0.0.0 255.255.255.253 STAGING\ninstance-3 us-central1-c f1-micro true 10.0.0.0 255.255.255.253 STAGING" \
        --expected-stdout "instance-2 instance-3"
    run_gcloud_test \
        --description "gcloud compute disks describe with an argument." \
        --command "gcloud --project=$mock_project compute disks describe --region=us-east1 --zone=us-east1-a disk" \
        --expected-gcloud-argv "compute disks list --project=$mock_project --regions=us-east1 --zones=us-east1-a" \
        --mock-gcloud-stdout "NAME LOCATION LOCATION_SCOPE SIZE_GB\ndisk-1 us-central1-a zone 10\ndisk-2 us-central1 region 20" \
        --expected-fzf-option "--multi --header-lines=1 --preview=gcloud compute disks describe --zone={2} {1} --project=$mock_project --query=disk $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        --mock-fzf-stdout "disk-1 us-central1-a zone 10\ndisk-2 us-central1 region 20" \
        --expected-stdout "disk-1 disk-2"
end

function run_error_test_cases
    run_gcloud_test \
        --description "error when gcloud returns an error status" \
        --command "gcloud compute instances describe " \
        --mock-gcloud-status 1 \
        --mock-gcloud-stderr "stderr\nstderr\nstderr" \
        --expected-status 1 \
        --expected-stdout "stderr stderr stderr"

    run_gcloud_test \
        --description "fzf was canceled" \
        --command "gcloud compute instances describe " \
        --mock-gcloud-stdout "NAME ZONE STATUS\ninstance-1 us-central1-a STAGING" \
        --mock-fzf-status 130 \
        --expected-status 130
end

@echo == Supported commands
run_supported_command_test_cases

@echo == Error cases
run_error_test_cases
