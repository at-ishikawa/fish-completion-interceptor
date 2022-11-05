set __FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI mock_kubectl
set __FCI_PLUGIN_KUBECTL_FZF_FZF_CLI mock_fzf

function run_test \
    -a test_description \
    -a commandline_arg \
    -a expected_status \
    -a expected_stdout \
    -a expected_stderr
    set -l commandline_args (string split " " $commandline_arg)

    set -l actual_stdout (fci_plugin_kubectl_fzf $commandline_args 2>/dev/null)
    set -l actual_stderr (fci_plugin_kubectl_fzf $commandline_args 2>&1)
    set -l actual_status $status
    set -l actual_stderr (string replace "$actual_stdout" "" "$actual_stderr")

    @echo "$test_description: $commandline_args"
    @test "status" $actual_status -eq $expected_status
    @test "stdout" "$actual_stdout" = $expected_stdout
    @test "stderr" "$actual_stderr" = $expected_stderr
end

@echo == Supported commands

set -l successful_command "kubectl get -o yaml -n namespace pods name"

set test_cases \
    $successful_command \
    "kubectl -n namespace logs pod2" \
    "kubectl describe crd name" \
    "kubectl delete deploy --namespace namespace " \
    "kubectl port-forward " \
    "kubectl logs -f " \
    "kubectl get svc -w svc-name" \
    "kubectl get cm --output yaml " \
    "kubectl get ingress,svc " \
    "kubectl get all " \
    "kubectl edit -n namespace daemonsets "

set expected_kubectl_commands \
    "get pods --namespace=namespace" \
    "get pods --namespace=namespace" \
    "get crd" \
    "get deploy --namespace=namespace" \
    "get pods,services --no-headers=true" \
    "get pods" \
    "get svc" \
    "get cm" \
    "get ingress,svc --no-headers=true" \
    "get all --no-headers=true" \
    "get daemonsets --namespace=namespace"


set default_expected_fzf_option $FCI_PLUGIN_KUBECTL_FZF_FZF_OPTION
function get_expected_fzf_option -a resource
    echo "$default_expected_fzf_option --preview=kubectl describe $resource {1}"
end

set expected_fzf_options \
    "$default_expected_fzf_option -q name --preview=kubectl describe pods {1} --namespace=namespace" \
    "$default_expected_fzf_option -q pod2 --preview=kubectl describe pods {1} --namespace=namespace" \
    "$default_expected_fzf_option -q name --preview=kubectl describe crd {1}" \
    "$default_expected_fzf_option --preview=kubectl describe deploy {1} --namespace=namespace" \
    (get_expected_fzf_option "pods,services") \
    (get_expected_fzf_option "pods") \
    "$default_expected_fzf_option -q svc-name --preview=kubectl describe svc {1}" \
    (get_expected_fzf_option "cm") \
    (get_expected_fzf_option "ingress,svc") \
    (get_expected_fzf_option "all") \
    "$default_expected_fzf_option --preview=kubectl describe daemonsets {1} --namespace=namespace"

for i in (seq 1 (count $test_cases))
    set -l test_case $test_cases[$i]
    set expected_kubectl_command $expected_kubectl_commands[$i]

    function mock_kubectl
        if [ "$expected_kubectl_command" != "$argv" ]
            echo "kubectl argv: (expected: $expected_kubectl_command, actual: $argv)" >&2
            return 255
        end

        echo "NAME  READY"
        echo "pod1  1/1"
        echo "pod2  1/1"
        return 0
    end

    set expected_fzf_option $expected_fzf_options[$i]
    function mock_fzf
        if [ "$expected_fzf_option" != "$argv" ]
            echo "fzf argv: (expected: $expected_fzf_option, actual: $argv)"
            return 255
        end
        echo "pod1  1/1"
        echo "pod2  1/1"
        return 0
    end

    run_test "Support commands" $test_case 0 "pod1 pod2" ""
end


@echo == Unsupported kubectl commands

function mock_kubectl
    return 255
end

function mock_fzf
    return 255
end

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
    run_test "Unsupported kubectl commands" $test_case 0 "" ""
end

@echo === kubectl errors

function mock_kubectl
    echo "stderr\nstderr\nstderr" >&2
    return 1
end

function mock_fzf
    # Shouldn't be called
    return 255
end

run_test "Error when kubectl returns an error status" $successful_command 1 "" "stderr\nstderr\nstderr"

function mock_kubectl
    echo "No resource found in mock namespace"
end

function mock_fzf
    # Shouldn't be called
    return 255
end

run_test "Error when kubectl doesn't return any resource" $successful_command 1 "" "No resource found in mock namespace"

@echo === fzf errors

function mock_kubectl
    echo "NAME READY"
    echo "pod   1/1"
end

function mock_fzf
    echo "stderr" >&2
    return 1
end

# fzf uses stderr for the interactive interrface so the code doesn't capture stderr
run_test "Error when fzf returns an error status" $successful_command 1 "" ""

function mock_fzf
    echo ""
end

run_test "Error while fzf returns nothing" $successful_command 1 "" ""
