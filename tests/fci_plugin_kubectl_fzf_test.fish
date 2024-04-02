set __FCI_PLUGIN_KUBECTL_FZF_KUBECTL_CLI mock_kubectl
set FISH_COMPLETION_INTERCEPTOR_FZF_CLI mock_fzf

function run_kubectl_test \
    --argument-names test_description \
    commandline_arg \
    expected_status \
    expected_stdout \
    expected_stderr
    set -l commandline_args (string split " " $commandline_arg)

    set temp_file (mktemp)
    set -l actual_stdout (fci_plugin_kubectl_fzf $commandline_args 2>$temp_file)
    set -l actual_status $status
    set -l actual_stderr (cat $temp_file)
    rm $temp_file

    @echo "$test_description: $commandline_args"
    # @echo "expected: $expected_stdout, actual: $actual_stdout"
    @test status $actual_status -eq $expected_status
    @test stdout "$actual_stdout" = "$expected_stdout"
    @test stderr "$actual_stderr" = "$expected_stderr"
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
    "kubectl edit -n namespace daemonsets " \
    "kubectl -n namespace exec "

set -l mock_kubectl_results \
    "NAME READY\npod1 1/1\npod2 1/1" \
    "NAME READY\npod1 1/1" \
    "NAME READY\npod1 1/1\npod2 1/1" \
    "NAME READY\npod1 1/1\npod2 1/1" \
    "NAME READY\npod1 1/1" \
    "NAME READY\npod1 1/1\npod2 1/1" \
    "NAME READY\npod1 1/1\npod2 1/1" \
    "NAME READY\npod1 1/1\npod2 1/1" \
    "NAME READY\npod1 1/1\npod2 1/1" \
    "NAME READY\npod1 1/1\npod2 1/1" \
    "NAME READY\npod1 1/1\npod2 1/1" \
    "NAME READY\npod1 1/1\npod2 1/1" \
    "NAME READY\npod1 1/1\npod2 1/1"
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
    "get daemonsets --namespace=namespace" \
    "get pods --namespace=namespace"

set default_expected_fzf_option $FISH_COMPLETION_INTERCEPTOR_FZF_OPTIONS

set mock_fzf_results \
    "pod1 1/1\npod2 1/1" \
    "pod1 1/1" \
    "pod1 1/1\npod2 1/1" \
    "pod1 1/1\npod2 1/1" \
    "pod1 1/1" \
    "pod1 1/1\npod2 1/1" \
    "pod1 1/1\npod2 1/1" \
    "pod1 1/1\npod2 1/1" \
    "pod1 1/1\npod2 1/1" \
    "pod1 1/1\npod2 1/1" \
    "pod1 1/1\npod2 1/1" \
    "pod1 1/1\npod2 1/1" \
    "pod1 1/1\npod2 1/1"
set expected_fzf_options \
    "--multi --header-lines=1 --preview=kubectl describe pods {1} --namespace=namespace --query=name" \
    "--multi --header-lines=1 --preview=kubectl describe pods {1} --namespace=namespace --query=pod2" \
    "--multi --header-lines=1 --preview=kubectl describe crd {1} --query=name" \
    "--multi --header-lines=1 --preview=kubectl describe deploy {1} --namespace=namespace" \
    "--multi --preview=kubectl describe {1}" \
    "--multi --header-lines=1 --preview=kubectl describe pods {1}" \
    "--multi --header-lines=1 --preview=kubectl describe svc {1} --query=svc-name" \
    "--multi --header-lines=1 --preview=kubectl describe cm {1}" \
    "--multi --preview=kubectl describe {1}" \
    "--multi --preview=kubectl describe {1}" \
    "--multi --header-lines=1 --preview=kubectl describe daemonsets {1} --namespace=namespace" \
    "--multi --header-lines=1 --preview=kubectl describe pods {1} --namespace=namespace"

set -l expected_stdouts \
    "pod1\npod2" \
    pod1 \
    "pod1\npod2" \
    "pod1\npod2" \
    pod1 \
    "pod1\npod2" \
    "pod1\npod2" \
    "pod1\npod2" \
    "pod1\npod2" \
    "pod1\npod2" \
    "pod1\npod2" \
    "pod1\npod2"

for i in (seq 1 (count $test_cases))
    set -l test_case $test_cases[$i]
    set expected_kubectl_command $expected_kubectl_commands[$i]

    set -g mock_kubectl_result $mock_kubectl_results[$i]
    function mock_kubectl
        if [ "$expected_kubectl_command" != "$argv" ]
            echo "kubectl argv: (expected: $expected_kubectl_command, actual: $argv)" >&2
            return 255
        end

        echo -e "$mock_kubectl_result"
        return 0
    end

    set -g expected_fzf_option "$expected_fzf_options[$i] $default_expected_fzf_option"
    set -g mock_fzf_result $mock_fzf_results[$i]
    function mock_fzf
        if [ "$expected_fzf_option" != "$argv" ]
            echo "fzf argv: (expected: $expected_fzf_option, actual: $argv)" >&2
            return 255
        end
        echo -e "$mock_fzf_result"
        return 0
    end

    set -l expected_stdout (echo -e "$expected_stdouts[$i]")
    run_kubectl_test "Support commands" $test_case 0 "$expected_stdout" ""
end


@echo == Unsupported kubectl commands

function mock_kubectl
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
    run_kubectl_test "Unsupported kubectl commands" "$test_case" 0 "" ""
end

@echo === kubectl errors

function mock_kubectl
    echo -e "stderr\nstderr\nstderr" >&2
    return 1
end

function mock_fzf
    echo "fzf shouldn't be used"
    return 255
end

set -l expected_stdout (echo -e "stderr\nstderr\nstderr")
run_kubectl_test "Error when kubectl returns an error status" $successful_command 1 "$expected_stdout" ""

function mock_kubectl
    echo "No resource found in mock namespace"
end

function mock_fzf
    echo "fzf shouldn't be called" >&2
    return 255
end

run_kubectl_test "Error when kubectl doesn't return any resource" $successful_command 1 "No resource found in mock namespace" ""

@echo === fzf errors

function mock_kubectl
    echo "NAME READY"
    echo "pod   1/1"
end

function mock_fzf
    return 130
end

# fzf uses stderr for the interactive interrface so the code doesn't capture stderr
run_kubectl_test "Error when fzf was canceled" $successful_command 130 "" ""
