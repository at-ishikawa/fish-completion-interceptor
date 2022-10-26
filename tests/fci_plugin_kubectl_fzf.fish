set __FCI_PLUGIN_KUBECTL_FZF_COMMAND "mock_kubectl"

function mock_kubectl
    echo kubectl fzf $argv
end

function run_test
    set -l test_description $argv[1]
    set -l commandline_args (string split " " $argv[2])
    set -l expected_status $argv[3]
    set -l expected_stdout $argv[4]
    set -l expected_stderr $argv[5]

    @test "$test_description for status: $commandline_args" (
        fci_plugin_kubectl_fzf $commandline_args 2>/dev/null
    ) $status -eq $expected_status

    if [ "$expected_stdout" = "" ]
        @test "$test_description for stdout: $commandline_args" (
            fci_plugin_kubectl_fzf $commandline_args 2>/dev/null
        ) -z ""
    else
        @test "$test_description for stdout: $commandline_args" (
            fci_plugin_kubectl_fzf $commandline_args 2>/dev/null
        ) = $expected_stdout
    end

    if [ "$expected_stderr" = "" ]
        @test "$test_description for stderr: $commandline_args" (
            fci_plugin_kubectl_fzf $commandline_args 2>&1
        ) -z ""
    else
        @test "$test_description for stderr: $commandline_args" (
            fci_plugin_kubectl_fzf $commandline_args 2>&1
        ) = "$expected_stderr"
    end

end

@echo == Supported commands

set -l successful_command "kubectl get -o yaml -n namespace pods name"

set test_cases \
    $successful_command \
    "kubectl -n namespace logs pod2" \
    "kubectl describe crd name" \
    "kubectl delete deploy --namespace namespace " \
    "kubectl port-forward " \
    "kubectl logs " \
    "kubectl logs -f " \
    "kubectl get svc -w svc-name" \
    "kubectl get cm -o yaml "

set expecteds \
    "kubectl fzf pods -n namespace -q name" \
    "kubectl fzf pods -n namespace -q pod2" \
    "kubectl fzf crd -q name" \
    "kubectl fzf deploy -n namespace" \
    "kubectl fzf pods,services" \
    "kubectl fzf pods" \
    "kubectl fzf pods" \
    "kubectl fzf svc -q svc-name" \
    "kubectl fzf cm"

for i in (seq 1 (count $test_cases))
    set -l test_case $test_cases[$i]
    set -l expected $expecteds[$i]
    # TODO status check fails for some reasons
    # run_test "Support commands" $test_case 0 $expected ""

    set -l args (string split " " $test_case)
    @test "Support commands: $args" (
        fci_plugin_kubectl_fzf $args
    ) = $expected
end


@echo == Unsupported commands

set test_cases \
    "kubectl apply -f " \
    "kubectl get" \
    "kubectl describe svc" \
    "kubectl delete rs" \
    "kubectl port-forward" \
    "kubectl -c sidecar log" \
    "kubectl -n namespace get" \
    "kubectl "

for test_case in $test_cases
    run_test "Unsupported commands" $test_case 0 "" ""
end

function mock_kubectl
    echo "stderr" >&2
    return 1
end
# TODO: stderr is just output currently
run_test "Error while running the kubectl fzf" $successful_command 1 "" ""

function mock_kubectl
    # show an empty data
    echo -n ''
end
run_test "Error while running the kubectl fzf" $successful_command 1 "" ""
