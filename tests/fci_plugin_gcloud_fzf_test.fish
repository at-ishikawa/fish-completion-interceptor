set -g __FCI_PLUGIN_GCLOUD_FZF_GCLOUD_CLI mock_gcloud
set -g FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_gcloud_test \
    -a commandline_arg \
    -a expected_status \
    -a expected_stdout

    set -l commandline_args (string split " " $commandline_arg)

    set temp_file (mktemp)
    set -l actual_stdout (fci_plugin_gcloud_fzf $commandline_args 2>$temp_file)
    set -l actual_status $status
    set -l actual_stderr (cat $temp_file)
    rm $temp_file

    @test status $actual_status -eq $expected_status
    @test stdout "$actual_stdout" = "$expected_stdout"
    @test stderr -z "$actual_stderr"
end

function run_supported_command_test_cases
    set -l mock_project mock-project

    set -l test_descriptions \
        "gcloud compute instances list doesn't return anything" \
        "gcloud compute instances describe without an argument. gcloud compute instances list returns a single row" \
        "gcloud compute instances describe with an argument. gcloud compute instances list returns multiple rows" \
        "gcloud compute disks describe with an argument."

    set -l test_cases \
        "gcloud compute instances describe " \
        "gcloud compute instances describe --zone=us-central1-a inst" \
        "gcloud --project $mock_project compute instances update inst" \
        "gcloud --project=$mock_project compute disks describe --region=us-east1 --zone=us-east1-a disk"

    set -g mock_gcloud_results \
        "Listed 0 items." \
        "NAME ZONE STATUS\ninstance-1 us-central1-a STAGING" \
        "NAME ZONE STATUS\ninstance-1 us-central1-a STAGING\ninstance-2 us-central1-b STAGING\ninstance-3 us-central1-c STAGING" \
        "NAME LOCATION LOCATION_SCOPE SIZE_GB\ndisk-1 us-central1-a zone 10\ndisk-2 us-central1 region 20"
    set -l expected_gcloud_commands \
        "compute instances list" \
        "compute instances list --zones=us-central1-a" \
        "compute instances list --project=$mock_project" \
        "compute disks list --project=$mock_project --regions=us-east1 --zones=us-east1-a"

    set -l mock_fzf_results \
        "fzf shouldn't be used" \
        "instance-1 us-central1-a STAGING" \
        "instance-2 us-central1-b f1-micro true 10.0.0.0 255.255.255.253 STAGING\ninstance-3 us-central1-c f1-micro true 10.0.0.0 255.255.255.253 STAGING" \
        "disk-1 us-central1-a zone 10\ndisk-2 us-central1 region 20"
    set -l expected_fzf_options \
        "fzf shouldn't be used" \
        "--multi --header-lines=1 --preview=gcloud compute instances describe --zone={2} {1} --query=inst $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        "--multi --header-lines=1 --preview=gcloud compute instances describe --zone={2} {1} --project=$mock_project --query=inst $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS" \
        "--multi --header-lines=1 --preview=gcloud compute disks describe --zone={2} {1} --project=$mock_project --query=disk $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS"

    set -l expected_statuses \
        1 \
        0 \
        0 \
        0
    set -l expected_stdouts \
        "Listed 0 items." \
        instance-1 \
        "instance-2\ninstance-3" \
        "disk-1\ndisk-2"

    for test_case_index in (seq 1 (count $test_cases))
        # global option is somehow required
        set -g expected_gcloud_command $expected_gcloud_commands[$test_case_index]
        set -g mock_gcloud_result $mock_gcloud_results[$test_case_index]

        function mock_gcloud
            if [ "$argv" != "$expected_gcloud_command" ]
                echo "gcloud argv: (expected: $expected_gcloud_command, actual: $argv)" >&2
                return 255
            end

            echo -e "$mock_gcloud_result"
            return 0
        end

        set -g expected_fzf_option $expected_fzf_options[$test_case_index]
        set -g mock_fzf_result $mock_fzf_results[$test_case_index]
        function mock_fzf
            if [ "$expected_fzf_option" != "$argv" ]
                echo "fzf options: (expected $expected_fzf_option, actual: $argv)" >&2
                return 255
            end

            echo -e "$mock_fzf_result"
            return 0
        end

        set -l test_case $test_cases[$test_case_index]
        set -l expected_status $expected_statuses[$test_case_index]
        set -l expected_stdout (echo -e "$expected_stdouts[$test_case_index]")

        @echo "Supported command: $test_case_index: $test_descriptions[$test_case_index]"
        run_gcloud_test "$test_case" $expected_status "$expected_stdout"
    end
end

@echo == Supported commands
run_supported_command_test_cases

@echo == Error cases

function mock_gcloud
    echo -e "stderr\nstderr\nstderr" >&2
    return 1
end
function mock_fzf
    echo "fzf shouldn't be used"
    return 255
end

@echo "Error case: Error when gcloud returns an error status"
set -l expected_stdout (echo -e "stderr\nstderr\nstderr")
run_gcloud_test "gcloud compute instances describe " 1 "$expected_stdout" ""

function mock_gcloud
    echo -e "NAME ZONE STATUS\ninstance-1 us-central1-a STAGING"
end
function mock_fzf
    return 130
end

@echo "Error case: Error when fzf was canceled"
run_gcloud_test "gcloud compute instances describe " 130 "" ""
